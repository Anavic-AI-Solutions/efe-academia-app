# Chat realtime — App Flutter Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Conectar la app con Reverb para que el chat funcione en tiempo real y sincronizado: iniciar conversación desde una lista de usuarios vinculados, recibir mensajes sin refrescar, mantener la lista de chats y el badge de no leíidos al día, recuperarse de una caída de conexión y mostrar confirmación de lectura e indicador "escribiendo…".

**Architecture:** Un servicio aislado `RealtimeService` (envoltorio de `laravel_reverb`) expone streams de eventos por canal; los `StateNotifier` de chat existentes los consumen con deduplicación por `id`. La redescarga tras reconexión se registra como listeners en el servicio, de modo que cada pantalla se resincroniza por su cuenta. Se agrega la feature `relations` con la misma estructura `data/domain/providers/screens` que el resto.

**Tech Stack:** Flutter 3.24, Dart ≥3.5, flutter_riverpod (`StateNotifier` manual), go_router, Dio, freezed + build_runner, flutter_dotenv, laravel_reverb ^0.7.1, flutter_test con fakes escritos a mano.

**Spec:** `docs/superpowers/specs/2026-10-02-chat-realtime-nucleo-design.md` (este plan argumenta desde el spec).

## Global Constraints

- Estructura por feature: `lib/features/<feature>/{data,domain,providers,screens}`; core en `lib/core/`.
- Riverpod manual: `final xProvider = StateNotifierProvider<XNotifier, XState>(...)`. **No** usar `riverpod_annotation`/código generado (no se usa en el repo).
- Modelos de dominio con `freezed` + `part 'x.freezed.dart';` → regenerar con `dart run build_runner build --delete-conflicting-outputs`.
- UI: **nunca un `AppBar` crudo** (regla de `docs/superpowers/plans/2026-10-01-ui-azul-unificada.md`); usar `LargeTitleBar` (listas) y `ScreenHeader` (detalle). Componentes: `AppCard`, `AppAvatar`, `BadgeCounter`, `EmptyState`, `ErrorView`, `ListShimmer`, `AppSearchBar`, `RefreshIndicator`.
- Tokens: `AppColors.primary`, `chipFor(isDark)`, `mutedFor(isDark)`, radio 13.
- i18n: toda cadena nueva va a `lib/l10n/app_es.arb` **y** `lib/l10n/app_en.arb` y se lee con `context.l10n`. Los textos exactos están en la sección A6 del spec.
- Verificación por tarea: `flutter analyze --no-fatal-infos && flutter test <ruta>`; al final `dart format --set-exit-if-changed . && flutter analyze --no-fatal-infos && flutter test`.
- Tests con fakes escritos a mano (`implements X`), siguiendo `test/ui_unified/chat_search_profile_test.dart`. Sin mockito/mocktail.
- No romper los tests existentes: `test/chat_models_test.dart` y `test/ui_unified/chat_search_profile_test.dart` deben seguir en verde.

## Review Focus

1. **Mensajes duplicados**: el backend hace `broadcast(...)->toOthers()` pero la app no manda `X-Socket-ID`, así que el emisor recibe su propio broadcast. Prueba: `realtime_messages_test.dart` "incoming message with an id that already exists is ignored" (Tarea 6).
2. **Backfill pisando o duplicando** respecto de los mensajes que llegan en vivo tras la reconexión. Prueba: "backfill merges missing messages keeping ascending order without duplicates" (Tarea 6).
3. **Canales que sobreviven al logout** o suscripciones duplicadas al reabrir un chat. Prueba: "disconnect with forget clears every channel and listener" (Tarea 2) + "watchChat subscription cancels when disposed" (Tarea 1).
4. **`/chat/new` capturado por la ruta `/chat/:id`** → pantalla inalcanzable. Prueba: `new_chat_route_test.dart` "navigates to the new chat screen instead of a chat detail" (Tarea 4).
5. **Badge que no baja al abrir un chat ni se refresca sin WebSocket**. Prueba: "unread badge refreshes when a chat is opened" y "unread badge refreshes on resume without realtime" (Tarea 5).

---

### Task 1: Dependencias, configuración y `RealtimeService`

**Files:**
- Modify: `pubspec.yaml` (dependencia `laravel_reverb: ^0.7.1`)
- Modify: `.env` y `.env.example` (`REVERB_HOST`, `REVERB_PORT`, `REVERB_APP_KEY`, `REVERB_SCHEME`)
- Create: `lib/core/realtime/realtime_service.dart`
- Test: `test/core/realtime/realtime_service_test.dart`

**Interfaces:**
- Consumes: `SecureStorage.getToken()` (`lib/core/storage/secure_storage.dart:16`), `dotenv.env` (paquete `flutter_dotenv`, ya cargado en `EnvHelper.load()`), `package:laravel_reverb` y `package:laravel_reverb/testing.dart` (`ReverbFake`).
- Produce (lo usan las Tareas 2, 5 y 6):
```dart
class RealtimeService {
  RealtimeService({required Reverb reverb});

  Future<void> connect();
  Future<void> disconnect({bool forget = false});
  bool get isConnected;
  Stream<ReverbState> get states;

  /// Suscribe presence-public.chat.{chatId} y devuelve el handle a cancelar.
  Subscription watchChat({
    required String chatId,
    required void Function(Map<String, dynamic> data) onMessage,   // evento .ChatMessageSend
    required void Function(Map<String, dynamic> data) onRead,      // evento .MessagesRead
    required void Function(Map<String, dynamic> data) onTyping,    // whisper client-typing
  });

  /// Suscribe private-notifications.{userId} y escucha .notification.sent.
  Subscription watchNotifications({
    required String userId,
    required void Function() onNotification,
  });

  /// Registra un listener de resync; devuelve la función que lo remueve.
  VoidCallback addReconnectListener(void Function() listener);
}
```
El `Reverb` de producción se construye fuera (Tarea 2) con `authEndpoint: '${origenDeApiBase}/broadcasting/auth'` y `authHeaders` que leen el token de `SecureStorage` en cada intento; el de tests se obtiene de `ReverbFake().reverb`, por eso el servicio recibe la instancia por constructor.

- [ ] **Step 1: Escribir los tests fallando**

Crear `test/core/realtime/realtime_service_test.dart` con `final fake = ReverbFake();` en `setUp` y `RealtimeService(reverb: fake.reverb)`:

```dart
test('watchChat delivers an incoming ChatMessageSend payload', ...)
    // fake.emit('presence-public.chat.1', r'App\Events\ChatMessageSend' / 'ChatMessageSend',
    //          {'id': '9', 'body': 'hola', 'conversation_id': '1'})
    // → onMessage llamado una vez con id == '9'

test('watchChat delivers MessagesRead payloads', ...)
test('watchChat delivers typing whispers (client-typing)', ...)
test('watchNotifications fires on notification.sent', ...)
test('watchChat subscription cancels when disposed', ...)
    // sub.cancel(); fake.emit(...); → onMessage NO llamado
test('addReconnectListener returns a remover', ...)
    // listener registrado, se remueve, luego fake.drop() → no se invoca
test('service starts disconnected', ...)   // isConnected == false
```

- [ ] **Step 2: Correrlos y verlos fallar**

Run: `flutter test test/core/realtime/realtime_service_test.dart`
Expected: FAIL — `lib/core/realtime/realtime_service.dart` no existe.

- [ ] **Step 3: Agregar la dependencia y las variables de entorno**

`flutter pub add laravel_reverb` (fija `^0.7.1` en `pubspec.yaml`); agregar a `.env` y `.env.example`:
```
REVERB_HOST=localhost
REVERB_PORT=8081
REVERB_APP_KEY=
REVERB_SCHEME=http
```
(Alinear host/puerto/esquema con los `REVERB_*` del backend; en Android emulador el host es `10.0.2.2` — documentarlo en el README al final del plan.)

- [ ] **Step 4: Implementar `RealtimeService`**

`watchChat` suscribe `reverb.presence('public.chat.$chatId')` y registra `.ChatMessageSend`, `.MessagesRead` y `listenForWhisper('client-typing', ...)`; `watchNotifications` usa `reverb.private('notifications.$userId')` y `.notification.sent`. Los listeners de resync viven en un `Set` propio del servicio y se despachan desde un único `reverb.onReconnected(...)` registrado en `connect()` — así el servicio no depende de si la API del paquete permite múltiples callbacks.

- [ ] **Step 5: Correrlos y verlos pasar**

Run: `flutter test test/core/realtime/realtime_service_test.dart` → PASS.

- [ ] **Step 6: Formatear y commitear**

```bash
dart format lib/core/realtime test/core/realtime
flutter analyze --no-fatal-infos
git add pubspec.yaml pubspec.lock .env .env.example lib/core/realtime test/core/realtime
git commit -m "feat(realtime): RealtimeService sobre laravel_reverb con canales y resync"
```

---

### Task 2: Coordinador realtime (ciclo de vida con la sesión) y resync global

**Files:**
- Create: `lib/core/realtime/realtime_providers.dart`
- Modify: `lib/features/auth/providers/auth_provider.dart` (solo si hace falta exponer el cambio de estado; no reescribirlo)
- Test: `test/core/realtime/realtime_providers_test.dart`

**Interfaces:**
- Consumes: `RealtimeService` (Tarea 1), `authProvider` (`AuthState{status,user}`), `chatListProvider` y `chatUnreadCountProvider` (Tarea 5 — registrar el listener de lista en la Tarea 5 y dejar el hook listo acá).
- Produce:
```dart
final realtimeServiceProvider = Provider<RealtimeService>((ref) => ...);   // reemplazable en tests
final realtimeConnectionProvider = StreamProvider<ReverbState>((ref) => ...);
/// true cuando hay sesión y el socket está conectado; false en cuanto falta cualquiera de los dos.
final realtimeReadyProvider = Provider<bool>((ref) => ...);
```
Comportamiento del coordinador (un único `Provider` que observa `authProvider`):
- pasa a `authenticated` → `connect()` + `watchNotifications(userId: user.id)`.
- pasa a `unauthenticated` → `disconnect(forget: true)` y cancelar el `watchNotifications`.
- al montar con sesión ya activa → conectar (arranque en frío).

- [ ] **Step 1: Escribir los tests fallando**

```dart
test('connecting is requested when the session becomes authenticated', ...)
test('notifications channel is watched for the logged in user id', ...)
test('disconnect with forget clears every channel and listener', ...)
    // autenticar → watchNotifications; desconectar → el listener de la Tarea 1 ya no recibe
test('no connection attempt happens while unauthenticated', ...)
```
(Fakes: un `FakeRealtimeService implements RealtimeService` que registra llamadas, más el `authProvider` sobrescrito con un `AuthState` controlado por el test.)

- [ ] **Step 2: Correrlos y verlos fallar**

Run: `flutter test test/core/realtime/realtime_providers_test.dart` → FAIL (providers inexistentes).

- [ ] **Step 3: Implementar `realtime_providers.dart`**

Provider de servicio (construye el `Reverb` de producción desde `dotenv` + `secureStorageProvider`), `realtimeConnectionProvider` mapeando `service.states`, y el coordinador con `ref.listen(authProvider, ...)`. Registrar **un** `addReconnectListener` que dispare el refetch de la primera página de chats y del contador de no leíidos (esos notifiers se implementan en la Tarea 5; hasta entonces el listener queda con una función inyectable por provider para poder testearlo).

- [ ] **Step 4: Correrlos y ver pasar**

Run: `flutter test test/core/realtime/realtime_providers_test.dart` → PASS.

- [ ] **Step 5: Comprobar que la app existente no se rompió**

Run: `flutter test test/ui_unified/chat_search_profile_test.dart` → PASS.

- [ ] **Step 6: Formatear y commitear**

```bash
dart format lib/core/realtime test/core/realtime
git add lib/core/realtime test/core/realtime
git commit -m "feat(realtime): coordinador de conexión ligado a la sesión y resync global"
```

---

### Task 3: Feature `relations` — API, repositorio, modelo y provider

**Files:**
- Create: `lib/features/relations/data/relations_api.dart`
- Create: `lib/features/relations/data/relations_repository.dart`
- Create: `lib/features/relations/domain/relation_model.dart` (+ `.freezed.dart` generado)
- Create: `lib/features/relations/providers/relations_provider.dart`
- Test: `test/features/relations/relations_repository_test.dart`

**Interfaces:**
- Consumes: `ApiClient.get(...)` (`lib/core/api/api_client.dart`), `CursorPagination<T>` (`lib/core/api/cursor_pagination.dart`), patrón de `lib/features/chat/data/chat_repository.dart`.
- Produce (lo consumen las Tareas 4):
```dart
// domain
@freezed
class RelationModel with _$RelationModel {
  const factory RelationModel({
    required String id,        // users.id en string
    required String fullname,
    required String role,      // student|professor|parent|admin|branch|user
    required int userId,
  }) = _RelationModel;
  factory RelationModel.fromJson(Map<String, dynamic> json);
}

// data
class RelationsApi {
  Future<Response> getRelations({String? query, String? cursor, int limit = 50});   // GET /relations
}
class RelationsRepository {
  Future<CursorPagination<RelationModel>> getRelations({String? query, String? cursor});
}

// providers
class RelationsState { CursorPagination<RelationModel> pagination; bool isLoading; String? error; String query; }
class RelationsNotifier extends StateNotifier<RelationsState> {
  Future<void> load();                 // página 1 con la query actual
  Future<void> loadMore();
  Future<void> setQuery(String query); // debounce 300 ms en la pantalla
}
final relationsProvider = StateNotifierProvider<RelationsNotifier, RelationsState>(...);
```

- [ ] **Step 1: Escribir el test del repositorio**

`test/features/relations/relations_repository_test.dart`, patrón de `test/classrooms/classroom_repository_test.dart` (una `Response` falsa de Dio con `statusCode: 200`):

```dart
test('parses the json api relation element into a RelationModel', ...)
    // data: [{type:'relation', id:'7', attributes:{fullname:'María Pérez', role:'student', user_id:7}}]
    // meta: {cursor:'Mw==', has_more:true, total:12}
    // → pagination.data.single: id=='7', fullname=='María Pérez', role=='student', userId==7
    // → hasMore == true, nextCursor == 'Mw==', total == 12

test('returns an empty pagination when the response has no data', ...)
test('tolerates a missing meta cursor', ...)     // nextCursor null, hasMore false
```

- [ ] **Step 2: Correrlo y verlo fallar**

Run: `flutter test test/features/relations/relations_repository_test.dart` → FAIL (archivo inexistente).

- [ ] **Step 3: Implementar modelo, api y repositorio**

`RelationModel.fromJson` acepta el elemento JSON:API (leer `attributes.fullname`, `attributes.role`, `attributes.user_id`, `id`). `RelationsApi.getRelations` arma `queryParameters: {if (query != null) 'q': query, if (cursor != null) 'cursor': cursor, 'per_page': limit}`. El repositorio desempaqueta `{data, meta}` igual que `ChatRepository.getChats`.

- [ ] **Step 4: Regenerar freezed y correr el test**

```bash
dart run build_runner build --delete-conflicting-outputs
flutter test test/features/relations/relations_repository_test.dart   # PASS
```

- [ ] **Step 5: Implementar `relations_provider.dart`**

`RelationsNotifier(load/refresh/loadMore/setQuery)` con `setState` sobre `RelationsState`, igual que `ChatListNotifier`. La query se limpia y recarga desde la pantalla (la Tarea 4 hace el debounce).

- [ ] **Step 6: Comprobar el conjunto de la feature y commitear**

```bash
flutter analyze --no-fatal-infos
git add lib/features/relations test/features/relations lib/features/relations/domain/relation_model.freezed.dart
git commit -m "feat(relations): modelo, api, repositorio y provider de usuarios vinculados"
```

---

### Task 4: Pantalla "Nuevo chat" + ruta + i18n

**Files:**
- Create: `lib/features/relations/screens/new_chat_screen.dart`
- Modify: `lib/app/router.dart:263-279` (ruta dentro de la rama `/chat`)
- Modify: `lib/l10n/app_es.arb`, `lib/l10n/app_en.arb` (claves de la sección A6 del spec)
- Modify: `lib/features/chat/screens/chat_list_screen.dart` (botón `+`)
- Test: `test/features/relations/new_chat_screen_test.dart`, `test/features/relations/new_chat_route_test.dart`

**Interfaces:**
- Consumes: `relationsProvider` (Tarea 3), `chatApiProvider.createPrivateChat(withUserId:)` (Tarea 5 — **si la Tarea 5 aún no existe**, crear el método en `ChatApi` acá: `Future<Response> createPrivateChat({required int withUserId}) => _client.post('/chats', data: {'type': 'private', 'with_user_id': withUserId});`), componentes de UI y `localizedApp()`.
- Produce: ruta `GET /chat/new`, pantalla con estados, navegación `context.push('/chat/$id?name=${Uri.encodeComponent(fullname)}')`.

- [ ] **Step 1: Escribir los tests de pantalla y de ruta**

`new_chat_screen_test.dart` (con `localizedApp(home: ...)` y un `RelationsNotifier`/`ChatApi` falso):

```dart
test('shows the shimmer while loading', ...)
test('shows the empty state when there are no linked people', ...)
test('shows the error view with retry when the request fails', ...)
test('lists linked people with name and role chip', ...)
test('shows no results state when the query matches nothing', ...)
test('tapping a person posts the chat once and navigates to the conversation', ...)
    // doble tap rápido → el ChatApi falso registra UNA sola llamada
```
`new_chat_route_test.dart`:
```dart
test('navigates to the new chat screen instead of a chat detail', ...)
    // un GoRouter construido igual al de la app: push('/chat/new') renderiza NewChatScreen
    // y NO ChatDetailScreen (evita que ':id' capture 'new')
```

- [ ] **Step 2: Correrlos y verlos fallar**

Run: `flutter test test/features/relations/` → FAIL (pantalla y ruta inexistentes).

- [ ] **Step 3: Agregar las claves i18n en ambos idiomas**

Insertar las claves de la tabla A6 del spec en `app_es.arb` y `app_en.arb` (bloque `chat*`/`relation*`, cerca de la línea 357 del ES). Regenerar: `flutter gen-l10n`.

- [ ] **Step 4: Implementar `NewChatScreen`**

`ConsumerStatefulWidget` con `ScreenHeader(title: context.l10n.chatNewTitle)`, `AppSearchBar` con debounce de 300 ms que llama `setQuery`, y la lista: `ListShimmer` / `EmptyState` / `ErrorView(onRetry)` / `ListView.builder` de `AppCard` + `AppAvatar` + `Text(fullname)` + chip de rol (`chipFor(isDark)`). Al tocar: deshabilitar la fila y mostrar spinner, `createPrivateChat`, y en éxito `context.push(...)`; en error, re-habilitar y mostrar `ErrorView`/snackbar con reintento.

- [ ] **Step 5: Registrar la ruta y el botón `+`**

En `router.dart`, dentro de la rama `StatefulShellBranch` de `/chat` **antes** de la ruta `:id`:
```dart
GoRoute(path: 'new', builder: (context, state) => const NewChatScreen()),
```
En `chat_list_screen.dart`, agregar la acción `+` en el `LargeTitleBar` → `context.push('/chat/new')`.

- [ ] **Step 6: Correr los tests y el analyze**

Run: `flutter test test/features/relations/ && flutter analyze --no-fatal-infos` → PASS.

- [ ] **Step 7: Commitear**

```bash
dart format lib/features/relations lib/app/router.dart
git add lib/features/relations lib/app/router.dart lib/l10n test/features/relations
git commit -m "feat(chat): pantalla Nuevo chat con buscador de vínculos y ruta /chat/new"
```

---

### Task 5: Chat en vivo — lista, contador de no leíidos y badge de la nav

**Files:**
- Modify: `lib/features/chat/data/chat_api.dart` (`createPrivateChat`, `getUnreadCount`)
- Modify: `lib/features/chat/providers/chat_provider.dart` (`ChatListNotifier.refreshFirstPage`, `chatUnreadCountProvider`)
- Modify: `lib/core/realtime/realtime_providers.dart` (el listener global de la Tarea 2 dispara estos refresh)
- Modify: `lib/app/router.dart` (`CustomBottomNav` → `BadgeCounter` en la pestaña Chat)
- Test: `test/features/chat/chat_list_live_test.dart`, `test/features/chat/unread_badge_test.dart`

**Interfaces:**
- Consumes: `RealtimeService.watchNotifications` + `addReconnectListener` (Tarea 1/2), `NotificationService`-equivalente del backend (`GET /chats/unread-count` → `{data:{count}}`).
- Produce:
```dart
// ChatApi
Future<Response> createPrivateChat({required int withUserId});
Future<int> getUnreadCount();          // GET /chats/unread-count → data.count
Future<void> markRead(String chatId);  // POST /chats/{id}/read (el backend despacha MessagesRead)

// chat_provider.dart
Future<void> ChatListNotifier.refreshFirstPage();   // igual que refresh(), sin estado de carga inicial
final chatUnreadCountProvider = FutureProvider<int>((ref) => ...);
final chatUnreadCountControllerProvider = Provider<...> // o ref.invalidate(chatUnreadCountProvider)
```

- [ ] **Step 1: Escribir los tests fallando**

`test/features/chat/chat_list_live_test.dart`:
```dart
test('a notification refreshes the first page of the chat list', ...)
    // ChatListNotifier con repositorio falso; se dispara el listener de notificación
    // → se llamó getChats() sin cursor y el estado quedó con la respuesta nueva

test('refreshFirstPage updates unread counts and last message preview', ...)
```
`test/features/chat/unread_badge_test.dart`:
```dart
test('unread badge refreshes when a chat is opened', ...)
    // chatUnreadCountProvider con ChatApi falso: el ChatApi registra la llamada a markRead
    // y el próximo valor del provider es 0
test('unread badge refreshes on resume without realtime', ...)
    // el refresh manual funciona aunque nunca haya llegado un evento por WebSocket
test('unread count parses the data.count envelope', ...)
```

- [ ] **Step 2: Correrlos y verlos fallar**

Run: `flutter test test/features/chat/chat_list_live_test.dart test/features/chat/unread_badge_test.dart` → FAIL.

- [ ] **Step 3: Implementar `createPrivateChat`, `getUnreadCount` y `markRead` en `ChatApi`**

`getUnreadCount()` desempaqueta `response.data['data']['count']` (con fallback a `0` si falta). `markRead(chatId)` es `POST /chats/$chatId/read` y su éxito invalida `chatUnreadCountProvider`.

- [ ] **Step 4: Implementar `refreshFirstPage` y `chatUnreadCountProvider`**

`refreshFirstPage()` repite `refresh()` sin tocar `isLoading` en true (para que la lista no parpadee). El provider de contador se invalida: al llegar `.notification.sent`, al abrir un chat (tras `POST /chats/{id}/read` o al cargar mensajes, que el backend ya marca como leídos) y en el listener global de reconexión.

- [ ] **Step 5: Conectar el coordinador y el badge de la nav**

**5a — Montar el coordinador (hallazgo de la revisión de la Tarea 2):** en `lib/app/app.dart`, dentro de `build` de `EfeApp`, agregar `ref.watch(realtimeCoordinatorProvider);`. El coordinador usa `ref.listen(authProvider)`, que solo está activo mientras el provider esté vivo; sin este `watch` la app nunca conecta, ni se suscribe, ni hace arranque en frío (los tests lo montan a mano y no lo detectan).

**5b — Cablear el resync:** en `realtime_providers.dart`, sobreescribir `realtimeResyncProvider` (o registrar el listener que la Tarea 2 dejó inyectable) para que llame a `refreshFirstPage()` del `ChatListNotifier` + invalide `chatUnreadCountProvider`. `watchNotifications(onNotification: ...)` → lo mismo (debounced ~500 ms).

**5c — Badge:** en `CustomBottomNav` (`router.dart:85-96`, ítem de Chat), envolver el ícono con `BadgeCounter` usando `chatUnreadCountProvider`; ocultarlo cuando sea `0`.

- [ ] **Step 6: Correr los tests y el analyze**

Run: `flutter test test/features/chat/ && flutter analyze --no-fatal-infos` → PASS.
Confirmar además que `flutter test test/ui_unified/chat_search_profile_test.dart` sigue pasando (el `CustomBottomNav` cambió).

- [ ] **Step 7: Commitear**

```bash
dart format lib/features/chat lib/core/realtime lib/app/router.dart
git add lib/features/chat lib/core/realtime lib/app/router.dart test/features/chat
git commit -m "feat(chat): lista y badge de no leíidos en vivo"
```

---

### Task 6: Conversación en vivo — mensajes, resync, typing y lectura

**Files:**
- Modify: `lib/features/chat/providers/chat_provider.dart` (`MessagesNotifier`: `appendIncoming`, `applyReadReceipt`, `markFailed`, `retrySend`, backfill en reconexión)
- Modify: `lib/features/chat/screens/chat_detail_screen.dart` (suscripción, fila de typing, ✓✓, reintento)
- Test: `test/features/chat/realtime_messages_test.dart`, `test/features/chat/chat_detail_widgets_test.dart`

**Interfaces:**
- Consumes: `RealtimeService.watchChat` + `addReconnectListener` (Tarea 1), `MessageModel` (campos `id/body/senderId/senderName/createdAt`), `authProvider.user.id` para el lado propio de la burbuja.
- Produce:
```dart
class MessagesNotifier extends StateNotifier<MessagesState> {
  Future<void> appendIncoming(Map<String, dynamic> event);  // dedupe por id + orden por id asc
  void applyReadReceipt(Map<String, dynamic> event);        // marca burbujas con id <= lastReadMessageId
  void setTyping(Map<String, dynamic> event);               // estado transitorio (ver MessagesState)
  Future<void> send(String body);                           // optimista: estado 'sending' → 'sent' | 'failed'
  Future<void> retrySend(String tempId);
}
// MessagesState agrega: Set<String> unreadableUntilIds (o int? lastReadMessageId),
// String? typingUserId, y un Map<String, MessageStatus> para sending/failed.
```

- [ ] **Step 1: Escribir los tests de lógica**

`test/features/chat/realtime_messages_test.dart`:
```dart
test('appendIncoming adds a new message', ...)
test('incoming message with an id that already exists is ignored', ...)   // Review Focus 1
test('incoming messages are sorted by id ascending', ...)
test('backfill merges missing messages keeping ascending order without duplicates', ...)  // Review Focus 2
test('applyReadReceipt marks own messages up to lastReadMessageId as read', ...)
test('typing event is cleared after the timeout', ...)
test('send failure marks the message as failed and retrySend re-sends it', ...)
```

- [ ] **Step 2: Correrlos y verlos fallar**

Run: `flutter test test/features/chat/realtime_messages_test.dart` → FAIL.

- [ ] **Step 3: Implementar `appendIncoming`, `applyReadReceipt`, estados de envío**

`appendIncoming` descarta si `state.messages.any((m) => m.id == event['id'])`, inserta y reordena por `id` ascendente (numérico, con fallback a `createdAt`). `send` crea la burbuja optimista y, si el `POST` falla, la marca `failed`; `retrySend` reenvía y reemplaza por la respuesta del servidor.

- [ ] **Step 4: Implementar el backfill en reconexión**

`MessagesNotifier` registra en `addReconnectListener` (y lo remueve en `ref.onDispose`) una función que: toma el `id` del último mensaje visible, llama `getMessages(chatId, cursor: id)` y fusiona con `appendIncoming` (la deduplicación hace el trabajo). Si no hay mensajes, refresca con `load()`.

- [ ] **Step 5: Escribir los tests de widgets y hacerlos fallar**

`test/features/chat/chat_detail_widgets_test.dart`:
```dart
test('shows the typing row when the other user is typing', ...)
test('shows a double check on messages read by the other user', ...)
test('shows the failed state with retry on an unsent message', ...)
test('subscribes on mount and cancels on dispose', ...)
```
Run: `flutter test test/features/chat/chat_detail_widgets_test.dart` → FAIL.

- [ ] **Step 6: Conectar la pantalla**

`chat_detail_screen.dart`: en `initState` llamar `markRead(chatId)` (invalida el badge), crear `RealtimeService.watchChat(chatId: ..., onMessage: notifier.appendIncoming, onRead: notifier.applyReadReceipt, onTyping: notifier.setTyping)` y cancelarlo en `dispose`; fila de typing animada arriba de la barra de input (claves `chatTyping`); ✓✓ en burbujas propias cuando `id <= lastReadMessageId`; burbuja fallida con `chatSendFailed` + `chatRetry`; enviar `whisper('client-typing', ...)` con throttle de 2 s mientras se tipea (y `{'typing': false}` al enviar/limpiar).

- [ ] **Step 7: Correr todos los tests de chat y el analyze**

Run: `flutter test test/features/chat/ && flutter test test/ui_unified/chat_search_profile_test.dart && flutter analyze --no-fatal-infos` → PASS.

- [ ] **Step 8: Commitear**

```bash
dart format lib/features/chat
git add lib/features/chat test/features/chat
git commit -m "feat(chat): mensajes en vivo, resync, typing y confirmación de lectura"
```

---

### Task 7: Banner de conexión y verificación final

**Files:**
- Modify: `lib/features/chat/screens/chat_list_screen.dart` (banner de estado)
- Modify: `README.md` (variables `REVERB_*` y host por plataforma)
- Test: `test/features/chat/connection_banner_test.dart`

- [ ] **Step 1: Test del banner (fallando)**

```dart
test('shows the offline banner when the socket is down', ...)
    // realtimeReadyProvider false → banner con el texto chatConnectionLost
test('hides the banner when the connection is restored', ...)
test('tapping the banner retries the connection', ...)
```
Run: `flutter test test/features/chat/connection_banner_test.dart` → FAIL.

- [ ] **Step 2: Implementar el banner**

Bajo el `LargeTitleBar` de `chat_list_screen.dart`, un contenedor con `mutedFor(isDark)` y `context.l10n.chatConnectionLost`, visible solo si `realtimeReadyProvider == false`; al tocar, `service.connect()`. Nunca bloquea el scroll ni el envío (la app sigue funcionando por REST).

- [ ] **Step 3: Documentar configuración en el README**

Agregar a la sección de entorno: `REVERB_HOST/PORT/APP_KEY/SCHEME`, con la tabla de host por plataforma (iOS simulator `localhost`, Android emulator `10.0.2.2`, dispositivo físico `IP de la LAN`) y los requisitos del backend (`php artisan reverb:start` + `php artisan queue:listen --tries=1`).

- [ ] **Step 4: Verificación completa**

```bash
dart format --set-exit-if-changed .
flutter analyze --no-fatal-infos
flutter test
```
Expected: todos en verde (incluidos los tests preexistentes del repo).

- [ ] **Step 5: Commitear**

```bash
dart format lib/features/chat test/features/chat
git add lib/features/chat test/features/chat README.md
git commit -m "feat(chat): banner de conexión y documentación de Reverb"
```

---

## Verificación manual (fuera de los tests)

Con el backend corriendo (`php artisan serve` + `queue:listen` + `reverb:start`) y la app en un emulador:

1. Login con un profesor → pestaña Chat → `+` → aparecen sus alumnos.
2. Tocar un alumno → se crea/abre la conversación.
3. Enviar un mensaje desde la app y verlo llegar **sin refrescar** en el cliente web (`/platform/chats`) y viceversa.
4. Abrir el mismo chat en dos emuladores: mensajes en ambos sentidos en vivo, ✓✓ al abrir, "escribiendo…" mientras el otro tipea.
5. Apagar el WebSocket (`Ctrl+C` al reverb), enviar un mensaje, levantar el reverb → el mensaje perdido aparece **sin duplicarse** y el banner de conexión se oculta.
6. Recibir un mensaje estando en otra pestaña → el badge de la nav aumenta; abrir el chat → baja a 0.
