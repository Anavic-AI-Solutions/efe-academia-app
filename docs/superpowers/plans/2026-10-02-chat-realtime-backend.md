# Chat realtime — Backend Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Exponer en la API de Laravel todo lo que el chat realtime necesita: lista de usuarios vinculados por rol, creación de conversación entre cualquier par vinculado, autenticación Bearer para canales de broadcasting, confirmaciones de lectura, contador global de no leíidos y cierre de los huecos de autorización.

**Architecture:** Un único servicio nuevo (`RelationQueryService`) centraliza el cálculo de vínculos por rol y es la fuente tanto de `GET /relations` como de la autorización de `POST /chats`. Los cambios sobre chat existen son aditivos: se agregan parámetros, rutas y despachos de eventos sin modificar las respuestas que ya consume la web Inertia.

**Tech Stack:** Laravel 11, PHP 8.2+, Sanctum, Musonza Chat v6, Laravel Reverb, Pest 3, laravel/pint.

**Spec:** `docs/superpowers/specs/2026-10-02-chat-realtime-nucleo-design.md` (este plan argumenta desde el spec).

## Global Constraints

- Rutas API bajo prefijo `/api/v1` en `routes/api.php`, dentro del grupo `Route::middleware('auth:sanctum')` (línea 54).
- Respuestas JSON:API vía `JsonApiResource` → `{type, id (string), attributes}`; errores vía el trait `ApiResponder` → `{error:{message,status_code}}`.
- Envolvente de listados con cursor: `{data: [...], meta: {cursor, has_more, total}}` (ver `GET /chats` en `ChatController::index` como referencia).
- Roles: `User::activeRole()` para el rol con el que el usuario opera; `User::hasRole('admin')` para el bypass de admin; `User::role()` para el rol del usuario destino.
- No romper la web Inertia: `/broadcasting/auth` de sesión `web`, los payloads legacy de `POST /chats` (`student_id`/`professor_id`) y los endpoints actuales de chat deben seguir comportándose igual.
- Verificación por tarea: `./vendor/bin/pest tests/Feature/Api/<Archivo>.php`; formato: `./vendor/bin/pint <archivos tocados>`; al final, suite completa.
- Los helpers de Pest declarados en un archivo de test son **globales en todo el suite**: los nombres de funciones auxiliares de cada test file deben ser únicos (usar sufijo `...For<Feature>`).

## Review Focus

Las cinco entradas más probables que ninguna tarea cubre sola, cada una con su prueba en la tarea dueña:

1. **El usuario Bearer no se resuelve en `/broadcasting/auth`** (el framework usa el guard `web` por defecto) → el handshake del móvil fallaría en silencio. Prueba: `BroadcastAuthTest` "bearer token can authorize a presence chat channel" (Tarea 3).
2. **Vinculados sin usuario asociado** (`student_data.user_id = null`) llegan a la creación de chat y `findOrCreateChatWithStudent` lanza `RuntimeException` → 500. Prueba: `RelationsTest` "relations excludes profiles without an associated user" (Tarea 1) + `ChatCreateWithUserTest` "professor can start a private chat with a linked student" (Tarea 2).
3. **Read receipts en spam**: `MessageController::index` marca leído en cada fetch, y el backfill tras reconectar vuelve a llamarlo → eventos `MessagesRead` en cascada. Prueba: `ReadReceiptTest` "marking a chat read with no unread messages does not broadcast" (Tarea 4).
4. **Escritura en conversaciones ajenas**: `POST /chats/{id}/messages` no verifica membresía hoy (solo `upload` lo hace). Prueba: `ChatAuthorizationTest` "user cannot post a message to a chat they are not part of" (Tarea 6).
5. **Eventos encolados que nadie procesa**: `UserNotificationSent` es `ShouldBroadcast` y la cola no siempre corre → el badge dejaría de actualizarse sin error visible. Prueba: `ReadReceiptTest` "MessagesRead implements ShouldBroadcastNow" (Tarea 4) + nota operativa en la Tarea 7.

---

### Task 1: `GET /api/v1/relations` — usuarios vinculados por rol

**Files:**
- Create: `app/Services/RelationQueryService.php`
- Create: `app/Http/Controllers/Api/Chats/RelationController.php`
- Modify: `routes/api.php:139-147` (agregar la ruta en el bloque `// Chat API`)
- Test: `tests/Feature/Api/RelationsTest.php`

**Interfaces:**
- Consumes: `User::activeRole()`, `User::hasRole(string)`, `User::role()`, `User::studentData|professorData|parentData`, `Classrooms` con sus pivotes `professor`/`students`, `StudentData::parents`/`ParentData::students`, `App\Services\ChatQueryService::normalizeForSearch()` (hacerlo `public` o duplicarlo como método privado con la misma implementación — ver Paso 4).
- Produces (para las Tareas 2 y 7):
```php
class RelationQueryService
{
    /** @return \Illuminate\Support\Collection<int, \App\Models\User> vínculos del usuario, sin duplicados y sin él mismo */
    public function relatedUsers(User $user): \Illuminate\Support\Collection;

    /** @return \Illuminate\Support\Collection<int, \App\Models\User> filtrado por nombre, normalizado igual que la búsqueda de chats */
    public function filterByQuery(\Illuminate\Support\Collection $users, string $query): \Illuminate\Support\Collection;
}
```
Ruta: `GET /api/v1/relations?q={?}&cursor={?}&per_page={?}` →
```json
{ "data": [ { "type": "relation", "id": "7",
    "attributes": { "fullname": "María Pérez", "role": "student", "user_id": 7 } } ],
  "meta": { "cursor": "Mw==", "has_more": false, "total": 12 } }
```
`id` = `users.id` en string; `role` = `User::role()` del destino (`student|professor|parent|admin|branch|user`).

- [ ] **Step 1: Escribir los tests fallando**

Crear `tests/Feature/Api/RelationsTest.php` con `uses(RefreshDatabase::class);` y helpers propios con nombres únicos (`createProfessorForRelations()`, `createStudentForRelations()`, `createParentForRelations()`, `createAdminForRelations()`) — copiar el patrón de `tests/Feature/Api/ChatTest.php:17-50` (borrar los datos de perfil que crea el factory y crear el rol deseado).

Casos:

```php
test('relations returns students and professors of shared classrooms for a professor', ...)
    // profesor con un aula; alumno y otro profesor en esa aula
    // GET /api/v1/relations con Sanctum::actingAs($professor)
    // assertStatus(200)
    // ->assertJsonCount(2, 'data')
    // ids devueltos == {alumno->user_id, otroProfesor->user_id}

test('relations returns professors and classmates for a student', ...)
    // alumno en un aula con otro alumno y un profesor
    // data contiene los 2, no contiene al propio alumno

test('relations returns linked students and their classrooms professors for a parent', ...)
    // padre vinculado a un alumno (student_data_parent_data) que comparte aula con un profesor
    // data contiene {hijo, profesor}; no contiene alumnos ajenos

test('relations returns academic users for an admin', ...)
    // admin + un alumno + un profesor con user_id → data los contiene

test('relations excludes the authenticated user', ...)
    // el profesor que llama nunca aparece en data

test('relations excludes profiles without an associated user', ...)
    // StudentData::factory()->create(['user_id' => null])
    // ese perfil no aparece en data

test('relations excludes soft deleted users', ...)
    // User::factory()->create() con deleted_at seteado → no aparece

test('relations filters by q', ...)
    // alumnos "Maria Perez" y "Juan Lopez"; q=mar → solo Maria

test('relations is ordered by fullname', ...)
    // data[i].attributes.fullname en orden ascendente

test('relations paginates with an offset cursor', ...)
    // per_page=1, primera página 1 item + has_more true + cursor no nulo
    // segunda página con ese cursor → el segundo item, has_more false

test('relations requires authentication', ...)
    // sin token → 401

test('relations response uses the json api envelope', ...)
    // data[0] tiene type=relation, id string, attributes con fullname/role/user_id
```

- [ ] **Step 2: Correr los tests y verlos fallar**

Run: `./vendor/bin/pest tests/Feature/Api/RelationsTest.php`
Expected: FAIL — ruta no definida (404).

- [ ] **Step 3: Implementar `RelationQueryService::relatedUsers()` y `filterByQuery()`**

Por rol (`$user->activeRole()`), construir los candidatos **siempre filtrando `whereNotNull('user_id')` en las tablas de perfil** y `whereNull('deleted_at')` en `users`, y deduplicando por id:

| rol | candidatos |
|---|---|
| `professor` | alumnos y profesores de los aulas donde `$user->professorData` es profesor |
| `student` | profesores y demás alumnos de las aulas de `$user->studentData` |
| `parent` | hijos de `$user->parentData` + profesores de las aulas de esos hijos |
| `admin` / `branch` | todos los usuarios con `studentData`, `professorData` o `parentData` |

Excluir siempre `$user->id`. `filterByQuery()` aplica la misma normalización que `ChatQueryService::normalizeForSearch()` (minúsculas UTF-8 + `iconv('UTF-8','ASCII//TRANSLIT')` + `str_contains`).

- [ ] **Step 4: Extraer los criterios compartidos sin duplicarlos**

Mover la lógica de roles que `ChatQueryService::getChatsQuery()` (`app/Services/ChatQueryService.php:28-50`) a métodos reutilizables y que `RelationQueryService` los consuma (o al revés: que `ChatQueryService` use los de `RelationQueryService`). La firma pública de `getChatsQuery()` no cambia.

- [ ] **Step 5: Correr los tests del flujo existente para confirmar que no se rompió nada**

Run: `./vendor/bin/pest tests/Feature/Api/ChatTest.php`
Expected: PASS (mismos resultados que antes de la refactorización).

- [ ] **Step 6: Implementar `RelationController::index()` y registrar la ruta**

En `routes/api.php`, dentro del bloque `// Chat API` y **antes** de cualquier ruta con `{id}`:
```php
Route::get('relations', [RelationController::class, 'index']);
```
El controlador usa `q`, `cursor` (offset en base64, `base64_decode` → int) y `per_page` (`min(...,100)`, default 50), pagina **en memoria** sobre la colección ordenada por `fullname`, y responde `{data, meta:{cursor,has_more,total}}`. Nota: no usar el trait `CursorPagination` acá, porque ordena por `id` y rompería el orden alfabético.

- [ ] **Step 7: Correr los tests y verlos pasar**

Run: `./vendor/bin/pest tests/Feature/Api/RelationsTest.php`
Expected: PASS (todos los casos).

- [ ] **Step 8: Formatear y commitear**

```bash
./vendor/bin/pint app/Services/RelationQueryService.php app/Http/Controllers/Api/Chats/RelationController.php routes/api.php tests/Feature/Api/RelationsTest.php
git add app/Services/RelationQueryService.php app/Http/Controllers/Api/Chats/RelationController.php routes/api.php tests/Feature/Api/RelationsTest.php
git commit -m "feat(api): GET /relations devuelve los usuarios vinculados por rol"
```

---

### Task 2: `POST /chats` con `with_user_id` — iniciar chat con cualquier par vinculado

**Files:**
- Modify: `app/Services/ChatService.php:19-81`
- Modify: `app/Http/Controllers/Api/Chats/ChatController.php:105-147`
- Test: `tests/Feature/Api/ChatCreateWithUserTest.php`

**Interfaces:**
- Consumes: `RelationQueryService::relatedUsers()` (Tarea 1), `ChatService::findOrCreateChatWithStudent()`/`findOrCreateChatWithProfessor()` (existentes), `ChatResource`.
- Produces:
```php
// ChatService
public function findOrCreatePrivateChat(User $initiator, User $target): Conversation;
// Request (aditivo, los params legacy siguen válidos)
POST /api/v1/chats  { "type": "private", "with_user_id": 7 }   → 201 ChatResource | 403 | 422
```

- [ ] **Step 1: Escribir los tests fallando**

Crear `tests/Feature/Api/ChatCreateWithUserTest.php` con helpers propios con nombres únicos (reusar los de `RelationsTest` está bien si se declaran en `tests/Pest.php`; si no, duplicar con sufijo `...ForChatCreate`).

```php
test('professor can start a private chat with a linked student using with_user_id', ...)
    // POST /api/v1/chats {type:'private', with_user_id: $student->user_id}
    // 201; data.attributes.type == 'private'; data.relationships.participants contiene ambos

test('student can start a private chat with a linked professor using with_user_id', ...)
test('student can start a private chat with a classmate using with_user_id', ...)
test('parent can start a private chat with a linked child using with_user_id', ...)
test('admin can start a private chat with any academic user using with_user_id', ...)

test('starting the same chat twice returns the same conversation', ...)
    // dos POST idénticos → 201 ambos, mismo data.id

test('starting a chat with a user who is not related is forbidden', ...)
    // alumno POST con user_id de un profesor de otra escuela/aula ajena → 403

test('starting a chat with a linked student keeps the parents in the conversation', ...)
    // padre vinculado presente en relationships.participants

test('legacy student_id payload still works', ...)
    // POST {type:'private', student_id: uuid} como profesor → 201

test('private chat without any target is rejected', ...)
    // POST {type:'private'} → 422

test('with_user_id requires authentication', ...)   // 401
```

- [ ] **Step 2: Correr los tests y verlos fallar**

Run: `./vendor/bin/pest tests/Feature/Api/ChatCreateWithUserTest.php`
Expected: FAIL — `with_user_id` no se reconoce (422 por validación o el camino legacy).

- [ ] **Step 3: Implementar `ChatService::findOrCreatePrivateChat(User $initiator, User $target): Conversation`**

Extraer el cuerpo común de `findOrCreateChatWithProfessor`/`findOrCreateChatWithStudent` (buscar conversación `private` con ambos participantes, o crearla con `Chat::createConversation([$initiator,$target])->makeDirect()` + `data.type = 'private'`). Si `$target->studentData` existe, llamar `ensureParentsInConversation($conversation, $target->studentData->parents)` para conservar el comportamiento actual. `findOrCreateChatWithProfessor` y `findOrCreateChatWithStudent` pasan a delegar en el método genérico sin cambiar su firma ni su retorno.

- [ ] **Step 4: Agregar la rama `with_user_id` en `ChatController::store()`**

Validación nueva `'with_user_id' => 'sometimes|integer|required_if:type,private'` más la regla: si `type=private` y no viene `with_user_id`, mantener las validaciones legacy actuales. Flujo de la rama nueva:
1. `$target = User::findOrFail($request->with_user_id);`
2. Autorizar: `$this->relationQueryService->relatedUsers($user)->contains('id', $target->id)` → si no, `abort(403)`. (Inyectar `RelationQueryService` en el constructor.)
3. `$conversation = $this->chatService->findOrCreatePrivateChat($user, $target);`

- [ ] **Step 5: Correr los tests y verlos pasar**

Run: `./vendor/bin/pest tests/Feature/Api/ChatCreateWithUserTest.php`
Expected: PASS.

- [ ] **Step 6: Correr la suite de chat existente (no romper lo legacy)**

Run: `./vendor/bin/pest tests/Feature/Api/ChatTest.php`
Expected: PASS.

- [ ] **Step 7: Formatear y commitear**

```bash
./vendor/bin/pint app/Services/ChatService.php app/Http/Controllers/Api/Chats/ChatController.php tests/Feature/Api/ChatCreateWithUserTest.php
git add app/Services/ChatService.php app/Http/Controllers/Api/Chats/ChatController.php tests/Feature/Api/ChatCreateWithUserTest.php
git commit -m "feat(api): POST /chats acepta with_user_id con autorización por vínculo"
```

---

### Task 3: `POST /api/v1/broadcasting/auth` con Bearer token

**Files:**
- Modify: `routes/api.php` (grupo `auth:sanctum`)
- Create (solo si delegar no funciona): `app/Http/Controllers/Api/BroadcastAuthController.php`
- Modify: `.env.example` (variables `REVERB_*`)
- Test: `tests/Feature/Api/BroadcastAuthTest.php`

**Interfaces:**
- Consumes: `Illuminate\Broadcasting\BroadcastController` (invocable del framework), `BroadcastManager::auth($request)`, `routes/channels.php` (`public.chat.{id}`, `notifications.{userId}`).
- Produce:
```
POST /api/v1/broadcasting/auth   body: {socket_id, channel_name}
  → 200 {"auth": "<firma>"}  (o {"auth","channel_data"} para presencia)
  → 403 si el usuario no puede suscribirse / token inválido
```

- [ ] **Step 1: Escribir los tests fallando**

Crear `tests/Feature/Api/BroadcastAuthTest.php` (helpers con nombres únicos; asumir `Event::fake` donde haga falta):

```php
test('bearer token can authorize a presence chat channel', ...)
    // crea conversación con $sender y $receiver; Sanctum::actingAs($sender) NO sirve aquí:
    // usar el token real → $token = $sender->createToken('auth-token')->plainTextToken;
    // $this->withHeaders(['Authorization' => 'Bearer '.$token])
    //      ->post('/api/v1/broadcasting/auth',
    //             ['socket_id' => '123.456', 'channel_name' => 'presence-public.chat.'.$conversation->id])
    // assertStatus(200)->assertJsonStructure(['auth'])

test('bearer token can authorize the user notifications channel', ...)
    // channel_name = 'private-notifications.'.$sender->id → 200 + auth

test('bearer token cannot authorize a chat channel the user is not part of', ...)
    // canal 'presence-public.chat.'.$otherConversation->id → 403

test('invalid bearer token is rejected', ...)
    // 'Bearer 1|notarealtoken' → 401 o 403

test('the web session route still works', ...)
    // $this->actingAs($sender) (guard web) + post('/broadcasting/auth', ...) → 200 + auth
```

- [ ] **Step 2: Correr los tests y verlos fallar**

Run: `./vendor/bin/pest tests/Feature/Api/BroadcastAuthTest.php`
Expected: FAIL — la ruta `/api/v1/broadcasting/auth` no existe (404).

- [ ] **Step 3: Registrar la ruta delegando al controlador del framework**

Dentro del grupo `auth:sanctum` de `routes/api.php`:
```php
Route::post('broadcasting/auth', \Illuminate\Broadcasting\BroadcastController::class);
```
Si el test "bearer token can authorize..." sigue fallando porque `$request->user()` resuelve contra el guard `web`, crear `app/Http/Controllers/Api/BroadcastAuthController.php` que reciba `socket_id` + `channel_name` y llame `app(\Illuminate\Broadcasting\BroadcastManager::class)->auth($request)`. **El test es el que decide cuál de las dos variantes se queda.**

- [ ] **Step 4: Correr los tests y verlos pasar**

Run: `./vendor/bin/pest tests/Feature/Api/BroadcastAuthTest.php`
Expected: PASS (los 5 casos, incluida la ruta `web`).

- [ ] **Step 5: Documentar las variables de Reverb en `.env.example`**

Agregar (hoy no existen):
```
BROADCAST_CONNECTION=reverb
REVERB_APP_ID=
REVERB_APP_KEY=
REVERB_APP_SECRET=
REVERB_HOST=localhost
REVERB_PORT=8081
REVERB_SCHEME=http
```
(ajustar puerto/esquema a los del `.env` real de desarrollo).

- [ ] **Step 6: Formatear y commitear**

```bash
./vendor/bin/pint routes/api.php app/Http/Controllers/Api/BroadcastAuthController.php tests/Feature/Api/BroadcastAuthTest.php
git add routes/api.php .env.example tests/Feature/Api/BroadcastAuthController.php tests/Feature/Api/BroadcastAuthTest.php
git commit -m "feat(api): autenticación Bearer para /broadcasting/auth (clientes móviles)"
```

---

### Task 4: Read receipts — despachar `MessagesRead`

**Files:**
- Modify: `app/Events/MessagesRead.php`
- Modify: `app/Http/Controllers/Api/Chats/ChatController.php:181-191` (`markRead`)
- Modify: `app/Http/Controllers/Api/Chats/MessageController.php:84-85` (`index`)
- Modify: `app/Services/ChatService.php` (nuevo método compartido)
- Test: `tests/Feature/Api/ReadReceiptTest.php`

**Interfaces:**
- Consumes: `Chat::conversation($c)->setParticipant($u)->unreadCount()`, `Chat::...->readAll()`, `broadcast(...)->toOthers()`.
- Produce:
```php
// ChatService
public function markConversationRead(Conversation $conversation, User $user): void;
// Evento: ShouldBroadcastNow, canal presence 'public.chat.{id}', broadcastAs 'MessagesRead'
// payload: ['chatId' => int, 'userId' => int, 'lastReadMessageId' => ?int]
```

- [ ] **Step 1: Escribir los tests fallando**

Crear `tests/Feature/Api/ReadReceiptTest.php`:

```php
test('MessagesRead implements ShouldBroadcastNow', ...)
    // (new MessagesRead(1, 2, 3)) instanceof ShouldBroadcastNow → true
    // y NO implements ShouldBroadcast encolable

test('marking a chat read broadcasts MessagesRead with the last read message id', ...)
    // conversación con 2 mensajes no leídos por $receiver
    // Event::fake([MessagesRead::class]); Sanctum::actingAs($receiver)
    // POST /api/v1/chats/{id}/read → 200
    // Event::assertDispatched(MessagesRead::class, fn ($e) =>
    //     $e->chatId === $conversation->id && $e->userId === $receiver->id
    //     && $e->lastReadMessageId === $lastMessageId)

test('marking a chat read with no unread messages does not broadcast', ...)
    // sin mensajes pendientes → Event::assertNotDispatched(MessagesRead::class)

test('messages index broadcasts MessagesRead once when there were unread messages', ...)
    // GET /api/v1/chats/{id}/messages con no-leídos > 0 → assertDispatched
    // segunda llamada inmediata (ya leído) → assertNotDispatched
```

Nota: los casos de autorización (no-participante) viven en la Tarea 6 (`ChatAuthorizationTest`) para no dejar tests rojos entre tareas.

- [ ] **Step 2: Correr los tests y verlos fallar**

Run: `./vendor/bin/pest tests/Feature/Api/ReadReceiptTest.php`
Expected: FAIL — el evento no se despacha (o el payload no tiene `lastReadMessageId`).

- [ ] **Step 3: Cambiar `MessagesRead` a `ShouldBroadcastNow` y ampliar su payload**

Agregar la propiedad `lastReadMessageId` al constructor y a `broadcastAs()` mantener `'MessagesRead'`. Revisar que el canal siga siendo `presence-public.chat.{chatId}`.

- [ ] **Step 4: Implementar `ChatService::markConversationRead(Conversation, User): void`**

```php
$unread = Chat::conversation($c)->setParticipant($user)->unreadCount();
if ($unread === 0) { return; }
Chat::conversation($c)->setParticipant($user)->readAll();
$lastId = $c->messages()->max('id');
broadcast(new MessagesRead($c->id, $user->id, $lastId))->toOthers();
```
Reemplazar el cuerpo de `ChatController::markRead()` y de `MessageController::index()` (línea 85) por esta llamada.

- [ ] **Step 5: Correr los tests y verlos pasar**

Run: `./vendor/bin/pest tests/Feature/Api/ReadReceiptTest.php`
Expected: PASS (los 4 casos).

- [ ] **Step 6: Formatear y commitear**

```bash
./vendor/bin/pint app/Events/MessagesRead.php app/Services/ChatService.php app/Http/Controllers/Api/Chats/ChatController.php app/Http/Controllers/Api/Chats/MessageController.php tests/Feature/Api/ReadReceiptTest.php
git add app/Events/MessagesRead.php app/Services/ChatService.php app/Http/Controllers/Api/Chats/ChatController.php app/Http/Controllers/Api/Chats/MessageController.php tests/Feature/Api/ReadReceiptTest.php
git commit -m "feat(api): MessagesRead se despacha al marcar leído, con lastReadMessageId"
```

---

### Task 5: `GET /api/v1/chats/unread-count` — badge global

**Files:**
- Modify: `app/Http/Controllers/Api/Chats/ChatController.php`
- Modify: `routes/api.php:139-147`
- Test: `tests/Feature/Api/UnreadCountTest.php`

**Interfaces:**
- Consumes: tabla `chat_message_notifications` (`messageable_type`, `messageable_id`, `is_seen`).
- Produce: `GET /api/v1/chats/unread-count` → `{ "data": { "count": 7 } }` (y opcionalmente `unreadChats`: cantidad de conversaciones con count > 0, no requerido por la app).

- [ ] **Step 1: Escribir los tests fallando**

Crear `tests/Feature/Api/UnreadCountTest.php`:

```php
test('unread count sums unread messages across the user conversations', ...)
    // 2 conversaciones con 3 y 4 no leídos para el usuario → data.count == 7

test('unread count only counts the authenticated user messages', ...)
    // no leídos de OTRO usuario no suman

test('unread count is zero when everything is read', ...)

test('unread count requires authentication', ...)  // 401
```

- [ ] **Step 2: Correrlos y verlos fallar**

Run: `./vendor/bin/pest tests/Feature/Api/UnreadCountTest.php` → FAIL (404).

- [ ] **Step 3: Implementar `ChatController::unreadCount()` y registrar la ruta**

Consulta única sobre `chat_message_notifications` (`is_seen = 0`, `messageable_id = $user->id`, `messageable_type = User::class`) con `SUM` por grupo; responder `{data:{count}}`. Registrar la ruta **antes** de `Route::get('chats/{id}', ...)`.

- [ ] **Step 4: Correr y ver pasar**

Run: `./vendor/bin/pest tests/Feature/Api/UnreadCountTest.php` → PASS.

- [ ] **Step 5: Formatear y commitear**

```bash
./vendor/bin/pint app/Http/Controllers/Api/Chats/ChatController.php routes/api.php tests/Feature/Api/UnreadCountTest.php
git add app/Http/Controllers/Api/Chats/ChatController.php routes/api.php tests/Feature/Api/UnreadCountTest.php
git commit -m "feat(api): GET /chats/unread-count para el badge de la navegación"
```

---

### Task 6: Hardening de autorización en los endpoints de chat

**Files:**
- Modify: `app/Http/Controllers/Api/Chats/ChatController.php:80-103` (`show`)
- Modify: `app/Http/Controllers/Api/Chats/MessageController.php:26-101` (`index`) y `:103-135` (`store`)
- Test: `tests/Feature/Api/ChatAuthorizationTest.php`

**Interfaces:**
- Consumes: `$conversation->getParticipants()`, `$user->hasRole('admin')`.
- Produce: comportamiento — participante → 200; no participante → `403`; admin → 200 (y en `show` conserva el auto-join actual).

- [ ] **Step 1: Escribir los tests fallando**

Crear `tests/Feature/Api/ChatAuthorizationTest.php`:

```php
test('user cannot show a chat they are not part of', ...)      // 403
test('admin can show any chat', ...)                            // 200 + auto-join
test('participant can show their chat', ...)                    // 200
test('user cannot read messages from a chat they are not part of', ...)  // 403
test('user cannot post a message to a chat they are not part of', ...)   // 403
test('participant can post a message', ...)                     // 201
test('admin can post a message to any chat', ...)               // 201
test('admin can read messages from any chat', ...)              // 200
```

- [ ] **Step 2: Correrlos y verlos fallar**

Run: `./vendor/bin/pest tests/Feature/Api/ChatAuthorizationTest.php` → FAIL (los de no-participante devuelven 200).

- [ ] **Step 3: Agregar la verificación de membresía**

Método privado compartido en cada controlador (o un helper en `ChatService`): `abort_if(! $user->hasRole('admin') && ! $conversation->getParticipants()->contains('id', $user->id), 403, 'You are not a participant of this conversation.')`. Aplicar en `ChatController::show` (antes del auto-join de admin), `MessageController::index` y `MessageController::store`.

- [ ] **Step 4: Correr los tests nuevos y los de chat existentes**

Run: `./vendor/bin/pest tests/Feature/Api/ChatAuthorizationTest.php && ./vendor/bin/pest tests/Feature/Api/ChatTest.php && ./vendor/bin/pest tests/Feature/Api/E2E/ChatApiTest.php`
Expected: PASS en los tres.

- [ ] **Step 5: Formatear y commitear**

```bash
./vendor/bin/pint app/Http/Controllers/Api/Chats/ChatController.php app/Http/Controllers/Api/Chats/MessageController.php tests/Feature/Api/ChatAuthorizationTest.php
git add app/Http/Controllers/Api/Chats/ChatController.php app/Http/Controllers/Api/Chats/MessageController.php tests/Feature/Api/ChatAuthorizationTest.php
git commit -m "fix(api): verifica membresía en show/messages de chat (403 para ajenos)"
```

---

### Task 7: Verificación final del backend

**Files:**
- Modify (si algo falla): los que haga falta
- Modify: `README.md` (nota operativa)

- [ ] **Step 1: Suite completa**

Run: `./vendor/bin/pest`
Expected: PASS — ningún test existente roto por los cambios.

- [ ] **Step 2: Formateo del repo**

Run: `./vendor/bin/pint --test`
Expected: PASS (o correr `./vendor/bin/pint` y commitear el formato).

- [ ] **Step 3: Nota operativa en el README**

Documentar en la sección de comandos que el realtime requiere `php artisan reverb:start` **y** `php artisan queue:listen --tries=1` (sin cola, `UserNotificationSent` queda encolado y el badge de la app no se actualiza en vivo).

- [ ] **Step 4: Commitear**

```bash
git add README.md
git commit -m "docs: requisitos operativos del realtime (reverb + cola)"
```
