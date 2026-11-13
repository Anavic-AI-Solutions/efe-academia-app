# Solicitudes (admin/sede) en EFE Mobile — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Agregar la sección y pantalla de Solicitudes para admin/sede en la app Flutter, con lista, detalle, aprobación y rechazo de altas de alumnos y padres, usando la misma lógica de negocio que la web.

**Architecture:** Backend Laravel: se extraen `RequestSearchService` y `RequestReviewService` para que web y API compartan reglas; se agrega `Api\Requests\RequestController` con lista combinada, detalle y acciones bajo `role:admin,branch`. Mobile Flutter: feature `requests` con Freezed, Dio, Riverpod y go_router; lista paginada con filtros y detalle con documentación, selector de curso y acciones.

**Tech Stack:** Laravel 11 + Sanctum + PostgreSQL + Pest (CI); Flutter 3.44 + Riverpod 2 + go_router 14 + Freezed + Dio + Phosphor + url_launcher.

**Spec:** `docs/superpowers/specs/2026-11-13-solicitudes-admin-mobile-design.md`

## Global Constraints

- **Backend worktree:** `/opt/dev/efe-app/.worktrees/feat-solicitudes-admin`, branch `feat-solicitudes-admin` desde `preprod`.
- **Mobile worktree:** `/opt/dev/efe_mobile/.worktrees/feat-solicitudes-admin`, branch `feat-solicitudes-admin` desde `master`.
- Si ya se está ejecutando dentro de un worktree, usarlo y no crear otro.
- **No correr Pest ni `php artisan test` sobre la base de desarrollo.** Verificar PHP con `php -l` y `./vendor/bin/pint`. Los tests backend se corren en CI o con una `DB_DATABASE` descartable.
- `admin` ve todas las sedes. `branch`/`sede` ve solo solicitudes de su sede, en lista, detalle y acciones.
- Las solicitudes rechazadas se listan aunque el usuario esté soft-deleted (`withTrashed`).
- La búsqueda de solicitudes cubre nombre, email y DNI, accent-insensitive.
- El selector de curso busca en el servidor con debounce; no se limita a la primera página.
- Acciones idempotentes: repetir una acción devuelve `200` con `changed: false`. `classroom_id` inválido devuelve `422`.
- Sin dependencias nuevas.
- Strings nuevos solo en `lib/l10n/app_es.arb` y `app_en.arb`; regenerar con `flutter gen-l10n` y no editar `app_localizations*.dart`.
- Mobile: `flutter analyze` y `flutter test` deben pasar antes de cerrar cada tarea.
- Menú: 13 secciones totales; Solicitudes visible solo para `admin` y `branch` (incluido `sede`).

## Review Focus

1. **Fuga entre sedes:** un usuario `branch` no debe ver ni aprobar solicitudes de otra sede; un padre de otra sede debe responder `404` aunque `ParentData` no tenga scope de sede.
2. **Rechazadas invisibles:** rechazar un alumno o padre soft-deletea su usuario; el filtro “Rechazadas” debe seguir mostrando la solicitud.
3. **Carrera entre admins:** dos admins con la misma solicitud abierta; la segunda acción no debe duplicar notificaciones ni cambios y debe devolver `changed: false`.
4. **Padre desactualizado:** aprobar un hijo desde el detalle del padre debe refrescar el estado del padre, incluso si la aprobación del último hijo auto-aprueba al padre.
5. **Curso fuera de la primera página:** el selector debe encontrar un curso que no está entre los primeros 50 resultados.

---

### Task 1: Servicios backend compartidos y delegación de la web

**Files:**
- Create: `app/Services/RequestSearchService.php`
- Create: `app/Services/RequestReviewService.php`
- Modify: `app/Models/Traits/HasAccentInsensitiveSearch.php`
- Modify: `app/Http/Controllers/StudentDataController.php:301-527`
- Modify: `app/Http/Controllers/ParentDataController.php:380-444`
- Test: `tests/Feature/RequestServicesTest.php`

**Interfaces:**
- Produces: `RequestSearchService::paginate(User $viewer, string $status, string $type, string $search, int $perPage, int $page): LengthAwarePaginator` — devuelve `User` con `student_data` o `parent_data` cargados, igual que la lista web actual.
- Produces: `RequestReviewService::approveStudent(StudentData $student, ?string $classroomId): array{status: string, changed: bool, parent_approved: bool, next_student_id: ?string}`
- Produces: `RequestReviewService::rejectStudent(StudentData $student): array{status: string, changed: bool}`
- Produces: `RequestReviewService::approveParent(ParentData $parent): array{status: string, changed: bool, first_student_id: ?string}`
- Produces: `RequestReviewService::rejectParent(ParentData $parent): array{status: string, changed: bool}`
- Produces: `HasAccentInsensitiveSearch::scopeSearchByFields(Builder $query, array $fields, ?string $search): Builder`
- Consumes: `App\Notifications\NewRequest`, `App\Services\NotificationService`, `App\Models\User`, `App\Models\StudentData`, `App\Models\ParentData`.

- [ ] **Step 1: Write the failing service tests**

Crear `tests/Feature/RequestServicesTest.php` con helpers de nombre único:

```php
<?php

use App\Models\Classrooms;
use App\Models\ParentData;
use App\Models\StudentData;
use App\Models\User;
use App\Services\RequestReviewService;
use App\Services\RequestSearchService;
use Illuminate\Foundation\Testing\RefreshDatabase;

uses(RefreshDatabase::class);

function createAdminForRequestServices(): User
{
    $user = User::factory()->create();
    $user->studentData()->delete();
    $user->professorData()->delete();
    $user->parentData()->delete();
    $user->userData()->create(['role' => 'admin']);

    return $user;
}

function createBranchForRequestServices(string $branch): User
{
    $user = User::factory()->create(['branch_name' => $branch]);
    $user->studentData()->delete();
    $user->professorData()->delete();
    $user->parentData()->delete();
    $user->userData()->create(['role' => 'branch']);

    return $user;
}
```

Casos:

- `search finds a student by email and by dni`: crear alumno pending con `email = 'ana@test.com'`, `identity_number = '99887766'`; `paginate($admin, 'pending', 'all', 'ana@test', 20, 1)` devuelve 1; con `'99887766'` devuelve 1.
- `branch only sees its own students and parents`: crear alumno pending branch `Centro`, alumno pending branch `Norte`, padre pending con hijo `Centro`, padre pending con hijo `Norte`; `paginate($branch, 'pending', 'all', '', 20, 1)` devuelve solo los de `Centro`; `paginate($admin, ...)` devuelve los cuatro.
- `rejected students remain listed after the user is soft deleted`: alumno pending con usuario; ejecutar `rejectStudent`; `paginate($admin, 'rejected', 'student', '', 20, 1)` devuelve 1.
- `approving the last child approves the parent`: alumno pending con padre y un curso; `approveStudent` devuelve `changed: true`, `parent_approved: true`; el alumno queda `approved`, el curso queda vinculado y el padre queda `approved`.
- `repeating an approval is a no-op`: alumno ya `approved`; `approveStudent` devuelve `changed: false` y no cambia el curso.
- `rejecting an approved student is a no-op`: alumno `approved`; `rejectStudent` devuelve `changed: false` y el estado sigue `approved`.

- [ ] **Step 2: Run tests to verify they fail**

Run (solo con base descartable o en CI): `DB_DATABASE=efe_requests_test ./vendor/bin/pest tests/Feature/RequestServicesTest.php`
Expected: FAIL — las clases y el scope no existen.

- [ ] **Step 3: Implement `searchByFields`**

En `HasAccentInsensitiveSearch` agregar el scope que arma un `where` agrupado con `orWhereRaw` por cada campo, usando `DbDialect::isPgSql()` y `immutable_unaccent(lower(...))` igual que `searchByField`.

- [ ] **Step 4: Implement `RequestSearchService`**

Mover a `paginate` la construcción de consultas y la paginación manual de `StudentDataController::requestsIndex()` (líneas 301-427), con estos cambios:

- Reemplazar `withoutGlobalScopes()` por `withoutGlobalScope('order')` para conservar el scope de sede.
- Usar `User::withTrashed()` en las consultas de alumnos con usuario y de padres.
- Buscar con `searchByFields(['student_data.fullname', 'student_data.email', 'student_data.identity_number'], $search)` y los equivalentes de `parent_data`.
- Para `branch`, agregar `whereHas('students')` dentro de la consulta de `parentData` para exigir al menos un hijo de su sede.
- Cargar `studentData` con `without('media')` y `parentData` con `withCount('students')`.
- Mantener el orden alumnos con usuario → alumnos sin usuario → padres y la paginación manual actual.
- El método recibe `User $viewer`, no lee `request()`.

- [ ] **Step 5: Implement `RequestReviewService`**

Mover la lógica de `StudentDataController::requestsApprove/requestsReject` y `ParentDataController::requestsApprove/requestsReject` a métodos transaccionales (`DB::transaction`). Conservar:

- Aprobación de alumno: `status = approved`, `syncWithoutDetaching` del curso, notificación al alumno, auto-aprobación y notificación del padre si no quedan hijos pendientes, y `next_student_id` si quedan.
- Rechazo de alumno: no hacer nada si ya está `approved`; si no, `rejected`, notificación y soft-delete del usuario.
- Aprobación de padre: `approved`, `current_student_id` al primer hijo, `current_selected_id` del usuario y notificación.
- Rechazo de padre: `rejected`, rechazo de hijos pendientes, notificaciones **antes** de los soft-deletes, y borrado de usuarios.
- Devolver `changed: false` cuando el estado destino ya estaba aplicado.

- [ ] **Step 6: Delegar la web a los servicios**

En `StudentDataController::requestsIndex()` llamar a `RequestSearchService::paginate($request->user(), ...)` y conservar el `Inertia::render('Requests/Index', ...)` con las mismas props. En `requestsApprove/requestsReject` y en los equivalentes de `ParentDataController`, llamar al servicio y conservar los redirects actuales.

- [ ] **Step 7: Verify syntax and style**

Run: `php -l app/Services/RequestSearchService.php && php -l app/Services/RequestReviewService.php && php -l app/Models/Traits/HasAccentInsensitiveSearch.php && php -l app/Http/Controllers/StudentDataController.php && php -l app/Http/Controllers/ParentDataController.php`
Expected: `No syntax errors detected` en todos.
Run: `./vendor/bin/pint --dirty`
Expected: sin errores.

- [ ] **Step 8: Commit**

```bash
git add app/Services/RequestSearchService.php app/Services/RequestReviewService.php \
  app/Models/Traits/HasAccentInsensitiveSearch.php \
  app/Http/Controllers/StudentDataController.php app/Http/Controllers/ParentDataController.php \
  tests/Feature/RequestServicesTest.php
git commit -m "feat(requests): share search and review rules with the web flow"
```

---

### Task 2: Endpoints API de Solicitudes

**Files:**
- Create: `app/Http/Controllers/Api/Requests/RequestController.php`
- Create: `app/Http/Resources/RequestResource.php`
- Modify: `routes/api.php` (después del bloque de `registrations`)
- Test: `tests/Feature/Api/RequestsTest.php`

**Interfaces:**
- Consumes: `RequestSearchService::paginate(...)` y `RequestReviewService::*` de Task 1.
- Produces: `RequestController::index`, `showStudent`, `showParent`, `approveStudent`, `rejectStudent`, `approveParent`, `rejectParent`.
- Produces: `RequestResource` acepta `StudentData|ParentData`; `type` = `student_request|parent_request`; atributos `kind`, datos personales, `children_count`, `children`, `media`.

- [ ] **Step 1: Write the failing API tests**

Crear `tests/Feature/Api/RequestsTest.php` con helpers únicos (`createAdminForRequestsApi`, `createBranchForRequestsApi`). Casos:

- `admin can list pending students and parents`: 2 alumnos pending (uno con usuario y uno sin usuario), 1 padre pending con 2 hijos, 1 alumno approved; `GET /api/v1/requests` devuelve 3 ítems, `meta.total = 3`, y `kind` incluye `student` y `parent`.
- `type filter returns only the requested kind`: `?type=student` devuelve 2; `?type=parent` devuelve 1.
- `search matches email and dni`: `?search=ana@test.com` y `?search=99887766` devuelven el alumno.
- `branch only sees requests from its branch`: branch `Centro` ve 1 alumno y 1 padre de `Centro`, no los de `Norte`; admin ve ambos.
- `branch cannot open or act on another branch parent`: `GET /api/v1/requests/parents/{id}` y `POST .../reject` devuelven 404.
- `admin can show a student request`: `GET /api/v1/requests/students/{id}` devuelve `type=student_request`, `attributes.kind=student` y `attributes.media`.
- `admin can show a parent request with children`: devuelve `attributes.children` con 2 hijos y `children_count=2`.
- `approving a student attaches the classroom`: `POST .../students/{id}/approve` con `classroom_id`; responde 200 `changed=true`, y la DB tiene `status=approved` y el aula vinculada.
- `approving a student without a classroom is rejected`: sin `classroom_id` responde 422 y el alumno sigue `pending`.
- `approving an already approved student returns changed false`: responde 200 `changed=false`.
- `rejecting a student soft deletes the user`: responde 200; `status=rejected` y `$user->fresh()->trashed()`.
- `rejecting an approved student keeps it approved`: responde 200 `changed=false`; sigue `approved`.
- `approving a parent sets the first child as current`: responde 200 y `current_student_id` es el primer hijo.
- `rejecting a parent rejects pending children and soft deletes users`: los hijos pending quedan `rejected` y los usuarios `trashed`.
- `only admin and branch can access requests`: un usuario parent recibe 403; un professor recibe 403.

- [ ] **Step 2: Run tests to verify they fail**

Run (solo con base descartable o en CI): `DB_DATABASE=efe_requests_test ./vendor/bin/pest tests/Feature/Api/RequestsTest.php`
Expected: FAIL — rutas/controlador no existen.

- [ ] **Step 3: Implement `RequestResource`**

Implementar `resourceType()`, `attributes($request)` y el helper de URL absoluta. Para `media` usar `relationLoaded('media')` y mapear `collection_name`, `file_name`, `mime_type`, `url`. Para `children` usar `relationLoaded('students')`. Para `children_count` usar `students_count` si existe y, si no, el conteo de la relación cargada.

- [ ] **Step 4: Implement `RequestController` y rutas**

Rutas dentro de `Route::middleware('role:admin,branch')->group(...)`:

```php
Route::get('requests', [RequestController::class, 'index']);
Route::get('requests/students/{student}', [RequestController::class, 'showStudent']);
Route::get('requests/parents/{parent}', [RequestController::class, 'showParent']);
Route::post('requests/students/{student}/approve', [RequestController::class, 'approveStudent']);
Route::post('requests/students/{student}/reject', [RequestController::class, 'rejectStudent']);
Route::post('requests/parents/{parent}/approve', [RequestController::class, 'approveParent']);
Route::post('requests/parents/{parent}/reject', [RequestController::class, 'rejectParent']);
```

Reglas:

- `index`: `status` default `pending`, `type` default `all`, `per_page` default 20 con máximo 100, `page` mínimo 1. Mapear cada `User` del paginador a `RequestResource` usando `$user->student_data ?? $user->parent_data`. Devolver `data` y `meta` (`current_page`, `last_page`, `per_page`, `total`).
- `showStudent`: cargar `media` y `parents`; devolver el resource.
- `showParent`: si el viewer es `branch` y `$parent->students()->exists()` es falso, `abort(404)`; cargar `media` y `students`; devolver el resource.
- `approveStudent`: validar `classroom_id` como `required|uuid|exists:classrooms,id`; llamar al servicio; devolver `apiSuccess($result)`.
- `rejectStudent`, `approveParent`, `rejectParent`: validar visibilidad de padre cuando corresponda y devolver `apiSuccess($result)`.

- [ ] **Step 5: Run tests to verify they pass**

Run (solo con base descartable o en CI): `DB_DATABASE=efe_requests_test ./vendor/bin/pest tests/Feature/Api/RequestsTest.php`
Expected: PASS.

- [ ] **Step 6: Verify syntax and style**

Run: `php -l app/Http/Controllers/Api/Requests/RequestController.php && php -l app/Http/Resources/RequestResource.php && php -l routes/api.php`
Expected: sin errores.
Run: `./vendor/bin/pint --dirty`
Expected: sin errores.

- [ ] **Step 7: Commit**

```bash
git add app/Http/Controllers/Api/Requests/RequestController.php \
  app/Http/Resources/RequestResource.php routes/api.php tests/Feature/Api/RequestsTest.php
git commit -m "feat(api): expose admin request list, detail and review actions"
```

---

### Task 3: Modelo, datos y providers mobile

**Files:**
- Create: `lib/features/requests/domain/request_model.dart`
- Create: `lib/features/requests/data/request_api.dart`
- Create: `lib/features/requests/data/request_repository.dart`
- Create: `lib/features/requests/providers/request_provider.dart`
- Test: `test/requests/request_data_test.dart`

**Interfaces:**
- Produces: `enum RequestKind { student, parent }`
- Produces: `RequestModel` (Freezed), `RequestChild`, `RequestMedia`.
- Produces: `RequestApi.getRequests`, `getStudentRequest`, `getParentRequest`, `approveStudent`, `rejectStudent`, `approveParent`, `rejectParent`.
- Produces: `RequestRepository.getRequests`, `getRequest(RequestKind, String)`, `Future<bool> approve(RequestModel, {String? classroomId})`, `Future<bool> reject(RequestModel)`.
- Produces: `requestRepositoryProvider`, `requestListProvider`, `requestDetailProvider`, `requestClassroomOptionsProvider`, `RequestListState`, `RequestListNotifier`.
- Consumes: `ApiClient`, `classroomRepositoryProvider`, `PageResult`.

- [ ] **Step 1: Write the failing data tests**

Crear `test/requests/request_data_test.dart` con un `_FakeRequestApi implements RequestApi` que registra llamadas y devuelve payloads. Casos:

- `parses a page of student and parent requests`: payload con `type`, `id`, `attributes` (`kind`, `fullname`, `status`, `children_count`) y meta; verificar `PageResult.data`, `kind`, `childrenCount`, `total`.
- `parses a student detail with media`: payload con `media`; verificar `RequestMedia.collectionName` y `url`.
- `parses a parent detail with children`: verificar `children` y `childrenCount`.
- `approve student sends classroom_id`: llamar `repository.approve(request, classroomId: 'c1')` y verificar la llamada.
- `approve parent sends no body`: verificar la llamada.
- `reject dispatches by kind`: verificar endpoints de alumno y padre.
- `list notifier forwards search, status and type and resets page`: verificar llamadas y que `setSearch`/`setStatus`/`setType` pidan página 1.
- `classroom options provider uses server search`: con un `classroomRepositoryProvider` fake, verificar `getClassrooms(search: 'inglés', page: 1, limit: 50)`.

- [ ] **Step 2: Run tests to verify they fail**

Run: `flutter test test/requests/request_data_test.dart`
Expected: FAIL — los archivos no existen.

- [ ] **Step 3: Implement domain models**

`RequestKind`, `RequestModel`, `RequestChild`, `RequestMedia` con Freezed y `fromJson` tolerante a respuestas planas y con `attributes`. `RequestKind` se parsea desde `attrs['kind']` con fallback a `student`.

- [ ] **Step 4: Implement API y repositorio**

`RequestApi` usa `ApiClient.get/post`. `RequestRepository` parsea `PageResult<RequestModel>` y `RequestModel`, traduce `DioException` a `ApiException` y devuelve `bool changed` en `approve`/`reject`.

- [ ] **Step 5: Implement providers**

`RequestListNotifier` con `state.status = 'pending'`, `state.type = 'all'`, `load`, `refresh`, `retry`, `setSearch`, `setStatus`, `setType`, `goToPage`. El constructor llama a `load()` como `StudentListNotifier`. `requestDetailProvider` es `FutureProvider.family<RequestModel, ({RequestKind kind, String id})>`. `requestClassroomOptionsProvider` es `FutureProvider.family<List<ClassroomModel>, String>` y llama `getClassrooms(search: value, page: 1, limit: 50)`.

- [ ] **Step 6: Generate Freezed code**

Run: `dart run build_runner build --delete-conflicting-outputs`
Expected: genera `request_model.freezed.dart`.

- [ ] **Step 7: Run tests to verify they pass**

Run: `flutter test test/requests/request_data_test.dart`
Expected: PASS.

- [ ] **Step 8: Commit**

```bash
git add lib/features/requests test/requests/request_data_test.dart
git commit -m "feat(requests): add mobile models, repository and providers"
```

---

### Task 4: Menú, ruta y pantalla de lista

**Files:**
- Create: `lib/features/requests/screens/request_list_screen.dart`
- Create: `lib/features/requests/screens/widgets/request_tile.dart`
- Modify: `lib/features/menu/domain/menu_entry.dart`
- Modify: `lib/features/menu/screens/menu_screen.dart`
- Modify: `lib/app/router.dart`
- Modify: `lib/l10n/app_es.arb`, `lib/l10n/app_en.arb`
- Test: `test/requests/request_list_screen_test.dart`
- Test: `test/menu/menu_entry_test.dart`, `test/menu/menu_screen_test.dart`

**Interfaces:**
- Consumes: `requestListProvider`, `RequestModel`, `RequestKind`.
- Produces: `RequestListScreen`, `RequestTile`.
- Produces: `MenuSection.requests`, ruta `/requests`.

- [ ] **Step 1: Write the failing menu tests**

En `test/menu/menu_entry_test.dart`:

- Cambiar “twelve” por “thirteen” y esperar 13 en `MenuEntry.all`.
- Agregar un test `requests only for admin, branch and sede`; para `admin`, `branch`, `sede` contiene `MenuSection.requests`; para `student`, `parent`, `professor`, `unknown`, `''` no.
- Agregar `requests` a la lista de secciones apiladas.

En `test/menu/menu_screen_test.dart`:

- Cambiar el nombre del test de admin a trece secciones y agregar `Solicitudes` a los labels.
- Mantener que admin no ve Notificaciones ni Cuotas.

- [ ] **Step 2: Run menu tests to verify they fail**

Run: `flutter test test/menu`
Expected: FAIL — `MenuSection.requests` no existe.

- [ ] **Step 3: Implement menú y ruta**

- Agregar `requests` a `MenuSection` después de `courses`.
- Agregar `MenuEntry` con `group: MenuGroup.academic`, `icon: PhosphorIconsRegular.clipboardText`, `route: '/requests'`.
- `isVisibleFor`: `requests` solo `admin`/`branch`.
- `menu_screen.dart`: `case MenuSection.requests: return l10n.menuRequests;`.
- `router.dart`: `GoRoute(path: '/requests', builder: ... RequestListScreen())` como ruta top-level.

- [ ] **Step 4: Write the failing list screen test**

Crear `test/requests/request_list_screen_test.dart` con un `RequestRepository` fake y `ProviderScope` override. Casos:

- `shows student and parent requests`: la lista muestra ambos nombres, “Alumno”/“Padre/Tutor” y los badges de estado.
- `filtering by parent requests asks the repository for type parent`: tocar el chip “Padres/Tutores” y verificar la llamada.
- `empty state when there are no requests`: verificar el texto de vacío.
- `error state offers retry`: repositorio que lanza; verificar `ErrorView` y el botón de reintento.

- [ ] **Step 5: Implement lista y l10n**

- `RequestListScreen` con `LargeTitleBar`, `AppSearchBar` con debounce de 350 ms, chips de estado y tipo, `RequestTile`, `PaginationBar`, `ListShimmer`, `EmptyState`, `ErrorView` y `RefreshIndicator`.
- `RequestTile` con `AppCard`, `AppAvatar`, nombre, email/DNI, badge de estado, etiqueta de tipo y conteo de hijos para padres.
- Agregar a ambos ARB: `menuRequests`, `requestsTitle`, `requestsSearchHint`, `requestsTypeAll`, `requestsTypeStudents`, `requestsTypeParents`, `requestsEmptyTitle`, `requestsEmptySubtitle`, `requestsEmptySearch`, `requestsLoadError`, `requestsKindStudent`, `requestsKindParent`, `requestsChildrenCount`.

- [ ] **Step 6: Regenerate l10n and run tests**

Run: `flutter gen-l10n`
Run: `flutter test test/menu test/requests/request_list_screen_test.dart`
Expected: PASS.

- [ ] **Step 7: Analyze**

Run: `flutter analyze --no-fatal-infos`
Expected: sin errores.

- [ ] **Step 8: Commit**

```bash
git add lib/features/requests lib/features/menu lib/app/router.dart \
  lib/l10n/app_es.arb lib/l10n/app_en.arb lib/l10n/app_localizations*.dart \
  test/requests/request_list_screen_test.dart test/menu
git commit -m "feat(requests): add admin requests section and list screen"
```

---

### Task 5: Detalle, documentación y acciones

**Files:**
- Create: `lib/features/requests/screens/request_detail_screen.dart`
- Create: `lib/features/requests/screens/widgets/request_media_section.dart`
- Create: `lib/features/requests/screens/widgets/classroom_picker_sheet.dart`
- Modify: `lib/app/router.dart`
- Modify: `lib/l10n/app_es.arb`, `lib/l10n/app_en.arb`
- Test: `test/requests/request_detail_screen_test.dart`

**Interfaces:**
- Consumes: `requestDetailProvider`, `requestClassroomOptionsProvider`, `RequestRepository`.
- Produces: `RequestDetailScreen({required RequestKind kind, required String id, String? parentId})`
- Produces: `RequestMediaSection`, `ClassroomPickerSheet`.

- [ ] **Step 1: Write the failing detail tests**

Crear `test/requests/request_detail_screen_test.dart` con repositorio fake y overrides. Casos:

- `tapping a request in the list opens its detail`: usar un `GoRouter` con `/requests` y `/requests/:kind/:id`; verificar la navegación.
- `pending student shows approve and reject`: verificar ambos botones.
- `approved student hides actions`: no hay botones.
- `approve student opens the classroom picker and sends the selected course`: tocar Aceptar, elegir un curso, confirmar; verificar `repo.approve(request, classroomId: 'c1')`.
- `reject asks for confirmation and calls the repository`: confirmar y verificar `repo.reject`.
- `parent detail lists children and opens the child request with parentId`: tocar un hijo y verificar la navegación a `/requests/student/{id}?parentId={parentId}`.
- `parent detail refreshes after a child action`: el repo devuelve primero un padre pending y luego un padre approved; al volver del hijo, no se muestra “Aprobar tutor”.
- `classroom picker searches on the server`: escribir “inglés” y verificar la llamada al repositorio de aulas con `search: 'inglés'`.

- [ ] **Step 2: Run tests to verify they fail**

Run: `flutter test test/requests/request_detail_screen_test.dart`
Expected: FAIL — las pantallas no existen.

- [ ] **Step 3: Implement `RequestDetailScreen`**

- `LargeTitleBar(title: l10n.requestsTitle)`.
- Cabecera con nombre, tipo y `StatusBadge`.
- Datos personales con `InfoRow` y `studentsInfo*` reutilizados; teléfono/dirección solo para padres.
- `RequestMediaSection` para documentación.
- Para padres: `SectionHeader` y lista de hijos; cada hijo navega a `/requests/student/{id}?parentId={request.id}`; al volver con `true`, invalidar el detalle del padre y refrescar la lista.
- `bottomNavigationBar` solo si `status == pending`: `PillButton` Aceptar y botón outlined Rechazar.
- Aceptar alumno: `showModalBottomSheet<ClassroomModel>` con `ClassroomPickerSheet`; luego `AlertDialog` de confirmación; llamar `repository.approve`.
- Aceptar padre: `AlertDialog` con el texto de aprobación de tutor; llamar `repository.approve`.
- Rechazar: `AlertDialog` con el texto según tipo; llamar `repository.reject`.
- En éxito: si `changed == false` mostrar `requestsNoChange`; en cualquier caso `Navigator.pop(context, true)`.
- En error: SnackBar `requestsActionError`.

- [ ] **Step 4: Implement widgets**

- `RequestMediaSection`: muestra DNI frente, selfie y otros; abre la URL con `launchUrl(..., mode: LaunchMode.externalApplication)`; si falla, SnackBar `requestsOpenDocumentError`.
- `ClassroomPickerSheet`: `ConsumerStatefulWidget` con búsqueda debounced 350 ms, `requestClassroomOptionsProvider`, estados carga/vacío/error y retorno del curso elegido.

- [ ] **Step 5: Add route and l10n**

- `router.dart`: dentro de `/requests`, `GoRoute(path: ':kind/:id', builder: ...)` parsea `kind` con fallback a `student` y lee `parentId` del query.
- Agregar a ambos ARB: `requestsDetailLoadError`, `requestsSectionDocuments`, `requestsNoDocuments`, `requestsSectionChildren`, `requestsPhone`, `requestsAddress`, `requestsOpenDocumentError`, `requestsActionApprove`, `requestsActionReject`, `requestsApproveTitle`, `requestsApproveStudentBody`, `requestsApproveParentTitle`, `requestsApproveParentBody`, `requestsRejectTitle`, `requestsRejectStudentBody`, `requestsRejectParentBody`, `requestsApproveConfirm`, `requestsRejectConfirm`, `requestsApprovedSuccess`, `requestsRejectedSuccess`, `requestsNoChange`, `requestsActionError`, `requestsClassroomPickerTitle`, `requestsClassroomPickerSearch`, `requestsClassroomPickerEmpty`, `requestsClassroomPickerLoadError`, `requestsClassroomPickerConfirm`.

- [ ] **Step 6: Regenerate l10n and run tests**

Run: `flutter gen-l10n`
Run: `flutter test test/requests`
Expected: PASS.

- [ ] **Step 7: Analyze**

Run: `flutter analyze --no-fatal-infos`
Expected: sin errores.

- [ ] **Step 8: Commit**

```bash
git add lib/features/requests lib/app/router.dart \
  lib/l10n/app_es.arb lib/l10n/app_en.arb lib/l10n/app_localizations*.dart \
  test/requests/request_detail_screen_test.dart
git commit -m "feat(requests): add request detail, documents and review actions"
```

---

### Task 6: Verificación integral y QA manual

**Files:**
- No nuevos archivos de producción.
- Verificar: `docs/superpowers/specs/2026-11-13-solicitudes-admin-mobile-design.md`.

- [ ] **Step 1: Backend verification**

Run en el worktree backend:

```bash
php -l app/Services/RequestSearchService.php
php -l app/Services/RequestReviewService.php
php -l app/Http/Controllers/Api/Requests/RequestController.php
php -l app/Http/Resources/RequestResource.php
php -l routes/api.php
./vendor/bin/pint --dirty
```

Expected: sin errores de sintaxis ni de estilo. Los tests Pest quedan para CI o base descartable.

- [ ] **Step 2: Mobile verification**

Run en el worktree mobile:

```bash
flutter gen-l10n
flutter analyze --no-fatal-infos
flutter test
```

Expected: `No issues found!` y todos los tests PASS.

- [ ] **Step 3: Manual QA**

Con la API local y un admin:

- Ver “Solicitudes” en el menú; con padre/alumno/profesor no aparece.
- Lista pendiente combinada; buscar por nombre, email y DNI.
- Filtrar Aprobadas/Rechazadas; una solicitud rechazada sigue visible.
- Aprobar un alumno con curso; verificar el aula vinculada.
- Aprobar un tutor; luego abrir un hijo, aprobarlo y volver: el tutor se ve actualizado.
- Rechazar un alumno y un tutor; verificar que sus accesos quedan eliminados.
- Repetir una acción sobre una solicitud ya resuelta: mensaje de “ya estaba resuelta”, sin cambios.
- Buscar un curso que no esté en la primera página del selector y aprobar con él.
- Abrir DNI y selfie desde el detalle.

- [ ] **Step 4: Commit de cierre (si hubo ajustes)**

```bash
git add -A
git commit -m "test(requests): verify admin request flow end to end"
```

---

## Self-Review

- **Spec coverage:** menú, lista, detalle alumno, detalle padre, documentación, aprobación/rechazo, permisos admin/sede, búsqueda, filtros, paginación, i18n, tests y QA están cubiertos por Tasks 1-6.
- **Step scan:** cada paso tiene una acción y un resultado verificable; los pasos de test incluyen nombre y aserciones; los de implementación incluyen firmas y archivos.
- **Type consistency:** `RequestKind`, `RequestModel`, `RequestSearchService::paginate(User, ...)`, `RequestReviewService::*` y las rutas se usan con los mismos nombres en todas las tareas.
- **Review Focus:** los cinco riesgos tienen tests en Task 1 (sede, rechazadas, idempotencia), Task 2 (sede/padre 404, idempotencia) y Task 5 (refresh de padre, búsqueda de curso).
- **Proportion:** el plan describe decisiones e interfaces; no transcribe los cuerpos de implementación.
