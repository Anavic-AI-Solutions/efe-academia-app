# Núcleo de chat realtime — Design Spec

**Fecha:** 2026-10-02
**Estado:** borrador para revisión del usuario
**Sub-proyecto:** 1 de 3 (ver "Alcance" al final)

---

## 1. Contexto

| | |
|---|---|
| App móvil | `/opt/dev/efe_mobile` — Flutter 3.24 / Dart ≥3.5, Riverpod (`StateNotifier` escrito a mano), go_router, Dio, flutter_dotenv, freezed, i18n ARB (ES/EN). |
| Backend | `/opt/dev/efe-app` — Laravel 11, Sanctum (tokens sin expiración), Musonza Chat v6, Laravel Reverb v1.4.4 (WebSocket), FCM + WebPush, cola `database`, Postgres. |
| Chat existente | App: `lib/features/chat/` con lista, detalle, envío y paginación por cursor. Backend: 8 rutas `/api/v1/chats*`. |
| Faltantes hoy | Ningún transporte realtime en la app; no existe endpoint de relaciones; no hay UI para iniciar una conversación; `/broadcasting/auth` solo autentica con sesión `web` (cookie), no con Bearer; los eventos `MessagesRead` y `MessageDeleted` están definidos pero nunca se despachan; no hay `GET /chats/unread-count`; no hay API de borrar/editar mensaje. |

## 2. Objetivo

1. El usuario logueado puede **iniciar un chat desde la app con los usuarios vinculados a él por relaciones** (calculadas según su rol).
2. La conversación funciona **en tiempo real y sincronizada**: mensajes nuevos llegan sin refrescar, la lista de chats y el contador de no leíidos se actualizan en vivo, y tras una caída de conexión se recupera lo perdido.
3. Incluye **confirmación de lectura** (✓✓) e **indicador "escribiendo…"**.

### Criterios de éxito
- Enviar un mensaje en A lo ve B en < 1 s con la app en primer plano, sin tocar nada.
- Un mensaje recibido con el socket caído aparece tras la reconexión (backfill), sin duplicados.
- El badge de la nav refleja el total de no leíidos y baja al abrir un chat.
- Ninguna pantalla muestra un `AppBar` crudo ni texto sin traducir.

## 3. Alcance

**En alcance:** backend (relaciones, auth Bearer para broadcasting, ampliación de `POST /chats`, read receipts, unread-count, hardening de autorización) + app Flutter (servicio realtime, pantalla "Nuevo chat", chats en vivo, badge, read receipts, typing).

**Fuera de alcance (fases 2 y 3):** adjuntos de archivos/imágenes, eliminar/editar mensaje, notificaciones push FCM, reacciones, presencia en la lista de chats.

---

## 4. Cambios de backend (`/opt/dev/efe-app`)

### B1. `GET /api/v1/relations` — nuevo

Lista los usuarios vinculados al autenticado.

- **Query:** `q` (opcional, filtro por nombre), `cursor` (opcional), `per_page` (default 50, máx 100).
- **Envolvente:** idéntica a `GET /chats` — `{data: [...], meta: {cursor, has_more, total}}` (usa el trait `CursorPagination` existente).
- **Elemento:**

```json
{
  "type": "relation",
  "id": "7",
  "attributes": {
    "fullname": "María Pérez",
    "role": "student",
    "user_id": 7
  }
}
```

- **`id` = `users.id` (bigint)**, no el uuid de `student_data`/`professor_data`/`parent_data`.
- **Conjunto por rol** (usa `User::activeRole()`, la misma semántica que `ChatQueryService::getChatsQuery()`):

| Rol del emisor | Devuelve |
|---|---|
| `professor` | alumnos de sus aulas + profesores de esas aulas |
| `student` | profesores de sus aulas + compañeros de aula |
| `parent` | hijos vinculados (`student_data_parent_data`) + profesores de las aulas de esos hijos |
| `admin`/`branch` | todos los usuarios con dato académico (student/professor/parent) |

- **Exclusiones y reglas:** excluir al propio usuario; excluir usuarios sin `user_id` (`whereNotNull('user_id')`, ya que `findOrCreateChatWithStudent` lanza `RuntimeException` sin usuario asociado); excluir soft-deleted; deduplicar por `user_id`; ordenar por `fullname` ascendente.
- **Filtro `q`:** normalización igual que `ChatQueryService::normalizeForSearch()` (minúsculas UTF-8 + transliteración ASCII + `str_contains`).
- **Implementación:** nuevo `RelationQueryService` que **reutiliza** los criterios ya escritos en `ChatQueryService::getChatsQuery()`/`getSearchSuggestions()` (extraer a métodos compartidos en lugar de duplicar la lógica de roles).

### B2. `POST /api/v1/chats` — ampliación de pares permitidos

Hoy solo acepta: profesor/admin → `student_id`; alumno/padre → `professor_id`. Se agrega un parámetro genérico:

- **Nuevo body:** `{ "type": "private", "with_user_id": 7 }` (aditivo; `student_id`/`professor_id` siguen funcionando para la web).
- **Flujo:** validar `with_user_id` requerido cuando se envía → `User::findOrFail` → **autorizar: el destino debe pertenecer al conjunto de relaciones del emisor (misma lógica que B1)**, si no → `403` → crear/encontrar conversación privada con el método genérico extraído `ChatService::findOrCreatePrivateChat(User $initiator, User $target): Conversation`.
- `findOrCreatePrivateChat` concentra la lógica actual de `findOrCreateChatWithProfessor`/`findOrCreateChatWithStudent` (buscar conversación `type === 'private'` con ambos participantes, o crearla con `makeDirect()`), y **si el destino tiene `studentData` conserva `ensureParentsInConversation()`** para que los padres vean el chat alumno-profesor.
- Respuesta: `201` con el `ChatResource` existente.

### B3. `POST /api/v1/broadcasting/auth` — autenticación con Bearer

- Nueva ruta **dentro del grupo `auth:sanctum`** de `routes/api.php` que delega al `BroadcastController` del framework (`Illuminate\Broadcasting\BroadcastController`), de modo que el usuario se resuelve con el token y las callbacks de `routes/channels.php` reciben el `$user` correcto.
- La ruta `/broadcasting/auth` de sesión `web` **no se toca** (la app Inertia sigue funcionando).
- **Prueba obligatoria** que lo prueba: con `Authorization: Bearer <token>` se obtiene `auth` para `presence-public.chat.{id}` y `private-notifications.{userId}`; sin token o con token inválido → 403; usuario que no es participante → 403. Si delegar al `BroadcastController` no resuelve el usuario con sanctum, se implementa un controlador propio que llama `Broadcast::auth($request)` — la prueba es la que define cuál sirve.

### B4. Read receipts: despachar `MessagesRead`

- El evento `MessagesRead` (ya definido, nunca disparado) pasa a `ShouldBroadcastNow` para no depender de la cola.
- **Se despacha** desde el `markRead` (`POST /chats/{id}/read`) y desde `MessageController::index` (que también marca leído), **solo si el `unreadCount` era > 0 antes de marcar** — así cada refetch/backfill no emite eventos repetidos.
- Canal: `presence-public.chat.{id}` (el mismo que suscribe la app), `broadcastAs() = 'MessagesRead'`, `->toOthers()`.
- **Payload ampliado:** `{chatId, userId, lastReadMessageId}` — las dos primeras claves son las que el evento ya tiene (`chatId`, `userId`), y `lastReadMessageId` es el `max(id)` de mensajes de la conversación al momento de marcar (nullable si la conversación está vacía). Permite marcar ✓✓ solo las burbujas anteriores y no todas. El cliente ignora los eventos cuyo `userId` es el suyo propio.

### B5. `GET /api/v1/chats/unread-count` — nuevo

- Respuesta: `{ "data": { "count": 12 } }`.
- Cálculo: suma de `chat_message_notifications` con `messageable_type = App\Models\User`, `messageable_id = usuario`, `is_seen = 0`, agrupado por conversación (misma fuente de verdad que `unread_count` por chat). Vale para todos los roles.
- Patrón análogo al ya existente `GET /notifications/unread-count`.

### B6. Hardening de autorización (mismos controladores de chat)

- `GET /chats/{id}`: hoy no verifica membresía → `403` si el llamador no es participante (los admins siguen pudiendo entrar).
- `POST /chats/{id}/messages` y `GET /chats/{id}/messages`: agregar la verificación explícita de participante (hoy solo `upload` la tiene; Musonza filtra lecturas pero no impide escribir en una conversación ajena).

---

## 5. Cambios de app Flutter (`/opt/dev/efe_mobile`)

### A1. Dependencia y configuración

- `pubspec.yaml`: **`laravel_reverb: ^0.7.1`** (pure Dart, API estilo Echo).
- `.env` / `.env.example`: `REVERB_HOST`, `REVERB_PORT`, `REVERB_APP_KEY`, `REVERB_SCHEME` (la app key no es secreta). `EnvHelper` ya copia `.env` junto al ejecutable.
- El `authEndpoint` es `${origen de API_BASE_URL}/api/v1/broadcasting/auth`, con `authHeaders` que leen el token de `SecureStorage` (clave `auth_token`) en cada intento.

### A2. `lib/core/realtime/` — capa realtime

```
lib/core/realtime/realtime_service.dart      # envuelve Reverb
lib/core/realtime/realtime_providers.dart    # providers Riverpod + coordinador
```

**`RealtimeService`** (responsabilidades):
- Construye `Reverb(host, port, appKey, useTls, authEndpoint, authHeaders, handleAppLifecycle: true, onError)`.
- `connect()` al iniciar sesión; `disconnect(forget: true)` al cerrar sesión (borra canales y listeners para que la sesión siguiente no re-suscriba nada del usuario anterior).
- `Stream<ReverbState> get connectionStates` → alimenta el banner de conexión.
- `Subscription watchChat(String chatId, ...callbacks)` → suscribe `presence-public.chat.{chatId}` y escucha `.ChatMessageSend`, `.MessagesRead` y el whisper `client-typing`.
- `Subscription watchUserChannel(String userId, ...callbacks)` → suscribe `private-notifications.{userId}` y escucha `.notification.sent`.
- `void onReconnected(void Function())` → hook de resync.

**Coordinador (Riverpod):** observa `authProvider` — al pasar a `authenticated` conecta y suscribe el canal de usuario; al `unauthenticated` desconecta con `forget`. `ChatDetailScreen`/`ChatListNotifier` suscriben y cancelan sus canales con `ref.onDispose`.

### A3. Reglas de sincronización

1. **Dedup por `id` de mensaje.** El backend hace `broadcast(...)->toOthers()` pero la app **no envía `X-Socket-ID`**, por lo que el emisor recibe su propio broadcast: todo append verifica que el `id` no exista ya. El envío optimista (REST) y el broadcast conviven sin duplicados.
2. **Orden**: mensajes ordenados por `id` ascendente (coincide con la paginación ascendente del backend).
3. **`onReconnected` → resync** (solo después de restaurar todos los canales, y debounced ~500 ms): refetch página 1 de `GET /chats`, `GET /chats/unread-count`, y si hay un chat abierto backfill `GET /chats/{id}/messages?cursor=<último id visible>` — la paginación ascendente devuelve exactamente lo que se perdió.
4. **Mismo resync al volver de background** (Reverb lo dispara vía reconexión con `handleAppLifecycle`).
5. **Modo degradado:** con el socket caído la app sigue funcionando por REST (enviar, y recibir al refrescar) y muestra el banner de conexión. Nunca bloquear el envío por estar sin WebSocket.
6. **Notificaciones de lista:** `.notification.sent` en `private-notifications.{userId}` → refetch de la primera página de `/chats` + `/chats/unread-count`.

### A4. `lib/features/relations/` — nueva feature

```
data/relations_api.dart         # GET /relations
data/relations_repository.dart  # parseo → CursorPagination<RelationModel>
domain/relation_model.dart      # freezed: RelationModel{id, fullname, role, userId}
providers/relations_provider.dart  # RelationsNotifier(load/refresh/loadMore/setQuery)
screens/new_chat_screen.dart
```

### A5. Integración con el chat existente

- `chat_api.dart`: `createPrivateChat({required int withUserId})` → `POST /chats {type:'private', with_user_id}`; `getUnreadCount()` → `GET /chats/unread-count`.
- `chat_provider.dart`:
  - `MessagesNotifier.appendIncoming(MessageModel)` — dedup + orden.
  - `MessagesNotifier` con estado de envío: `sending` → `sent` | `failed` (con `retrySend(tempId)`).
  - `ChatListNotifier.refreshFirstPage()` para el refetch vía realtime.
  - `chatUnreadCountProvider` (se refresca en `.notification.sent`, al marcar leído y al abrir un chat).
- `chat_detail_screen.dart`: suscribe su canal al montar, cancela al desmontar; fila de "escribiendo…", read receipts, reintento de envío fallido, subtítulo vivo.
- `chat_list_screen.dart`: botón `+` en `LargeTitleBar`, banner de conexión, refresca con notificaciones.
- `lib/app/router.dart`: ruta `/chat/new` **antes** de `/chat/:id` dentro de la rama del shell (evita que `:id` capture "new").
- `lib/core/widgets/custom_bottom_nav.dart` (o el archivo donde vive `CustomBottomNav`): `BadgeCounter` con `chatUnreadCountProvider`.

### A6. Copy nuevo (claves ARB en `app_es.arb` y `app_en.arb`)

| Clave | ES | EN |
|---|---|---|
| `chatNewTitle` | Nuevo chat | New chat |
| `chatNewSearchHint` | Buscar persona… | Search people… |
| `chatNewEmptyTitle` | Sin personas vinculadas | No linked people |
| `chatNewEmptySubtitle` | Todavía no tenés personas con las que chatear | You don't have anyone to chat with yet |
| `chatNewNoResults` | Sin resultados para «%s» | No results for “%s” |
| `chatNewStart` | Iniciar conversación | Start conversation |
| `relationRoleStudent` | Alumno | Student |
| `relationRoleProfessor` | Profesor | Professor |
| `relationRoleParent` | Padre/Madre | Parent |
| `relationRoleAdmin` | Admin | Admin |
| `chatTyping` | escribiendo… | typing… |
| `chatOnline` | en línea | online |
| `chatConnectionLost` | Sin conexión — tocá para reintentar | Offline — tap to retry |
| `chatSendFailed` | No se pudo enviar | Couldn't send |
| `chatRetry` | Reintentar | Retry |
| `chatUnreadLabel` | %s mensajes sin leer | %s unread messages |

Estas claves y textos son la fuente de verdad: se implementan tal cual, sin agregar strings hardcodeados en los widgets.

### A7. Estados de UI (obligatorios)

**`/chat/new`:** cargando (`ListShimmer`) → vacío propio (`EmptyState` "Sin personas vinculadas") / vacío de búsqueda (`EmptyState` "Sin resultados") / error (`ErrorView(onRetry)`) / lista (`AppCard` + `AppAvatar` + fullname + chip de rol con `chipFor(isDark)`). Fila deshabilitada con spinner mientras resuelve el `POST`.
**Lista de chats:** banner de conexión cuando `connectionState != connected`; badge en la nav.
**Detalle:** fila de typing sobre el input; ✓✓ en burbujas propias leídas; burbuja en estado fallido con reintento.

---

## 6. Manejo de errores y casos borde

1. Vinculado sin `user_id` → excluido en B1 (evita el `RuntimeException` de `findOrCreateChatWithStudent`).
2. Broadcast propio recibido → dedup por `id`.
3. Backfill y mensaje en vivo simultáneos → dedup + orden por `id`.
4. Envío sin conexión → burbuja `failed` con reintento; el resto responde por REST.
5. 401/403 en auth de canal (sesión cerrada en otro dispositivo) → el interceptor de Dio ya redirige a login; `RealtimeService.disconnect(forget: true)` en logout.
6. Doble tap en la fila de relación → fila deshabilitada + spinner (el backend es idempotente igualmente).
7. `POST /chats` con usuario no vinculado → 403 y `ErrorView` con reintento en la pantalla.
8. Cola: `UserNotificationSent` es `ShouldBroadcast` (en cola). Si no corre `php artisan queue:listen` el badge no se actualiza en vivo. **Requisito operativo documentado y verificado en la etapa de verificación.**

## 7. Testing

**Backend — Pest (`tests/Feature/Api/`):**
- `RelationsTest` — el set devuelto por rol (profesor/student/parent/admin), exclusión del propio usuario, exclusión de usuarios sin `user_id`, filtro `q`, 401 sin token, forma del elemento `relation`.
- `BroadcastAuthTest` — Bearer autentica `presence-public.chat.{id}` y `private-notifications.{userId}`; no-participante → 403; token inválido → 403; la ruta `web` de sesión sigue funcionando.
- `ChatCreateTest` — `with_user_id` crea o devuelve la conversación existente (idempotencia por par), para cada combinación de roles; usuario no vinculado → 403; conserva `ensureParentsInConversation` cuando el destino es alumno.
- `ReadReceiptTest` — `Event::fake`: `markRead` con no-leíidos > 0 despacha `MessagesRead` con `{chatId, userId, lastReadMessageId}`; con no-leídos = 0 no despacha nada.
- `UnreadCountTest` — suma correcta por usuario.
- `ChatAuthorizationTest` — 403 de `GET /chats/{id}`, `GET/POST messages` a conversación ajena (admin pasa).

**App — `flutter_test` con fakes escritos a mano (patrón del repo, sin mockito):**
- `test/core/realtime/realtime_service_test.dart` con **`ReverbFake`** (de `package:laravel_reverb/testing.dart`): mensaje entrante → append; duplicado → se ignora; reconexión → dispara backfill; logout → canales limpios.
- `test/features/relations/relations_repository_test.dart` — parseo JSON:API con `Response` falso (patrón de `classroom_repository_test`).
- `test/features/chat/chat_list_notifier_test.dart` — notificación entrante actualiza `unread_count`/`last_message`; `chatUnreadCountProvider`.
- Widget tests con `localizedApp()`: `/chat/new` (shimmer/vacío/error/lista, tap → un solo `POST`), fila "escribiendo…", read receipt, reintento de envío fallido, badge en la nav.

**Verificación:** `dart format --set-exit-if-changed .`, `flutter analyze --no-fatal-infos`, `flutter test` (CI de la app); `php artisan test --filter=...` en el backend.

## 8. Riesgos y operación

- **`laravel_reverb` es un paquete joven** (~160 descargas/semana). Es pure Dart y está aislado en `RealtimeService`; si falla, el plan contempla reemplazarlo por un cliente propio sobre `web_socket_channel` sin tocar el resto de la app.
- Reverb debe estar corriendo (`php artisan reverb:start`) y la cola (`php artisan queue:listen`) para que el badge se actualice en vivo.
- `.env.example` del backend **no tiene las variables `REVERB_*`** hoy: agregarlas.
- La app necesita las variables `REVERB_*` en su `.env`; en Android emulador el host es `10.0.2.2`, en dispositivo físico la IP de la LAN (documentado en el README de la app).

## 9. Definición de terminado

- [ ] Los 6 cambios de backend están implementados con sus tests Pest en verde.
- [ ] La app permite ir de la lista de chats → `+` → buscar un vinculado → iniciar conversación → intercambiar mensajes en vivo con otro dispositivo.
- [ ] Los mensajes perdidos con el socket caído aparecen al reconectar, sin duplicados.
- [ ] Badge de no leíidos en la nav, actualizado en vivo y al abrir un chat.
- [ ] ✓✓ de lectura y "escribiendo…" funcionando entre dos dispositivos.
- [ ] Estados de UI completos (cargando/vacío/error/conexión caída) en ES y EN.
- [ ] `flutter analyze` + `flutter test` + `dart format` en verde; `php artisan test` en verde.
