# Materiales del profesor (CRUD + subida) — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Que un profesor cree, edite, elimine y suba archivos de material en la pestaña Materiales de sus aulas asignadas (mismo alcance para admin/branch), con paridad de campos respecto de la creación web.

**Architecture:** Backend: policy de materiales acotada por asignación, requests/controlador con `files[]`, `student_ids`, categorías válidas, visibilidad y `available_until`; borrado limpia media. Mobile: `MaterialApi` + `MaterialRepository` nuevos (la lista sigue en `ClassroomRepository`), modelo con `studentIds`, y UI sobre los patrones existentes (bottom sheet tipo `CreateQualificationSheet`, barra inferior tipo pantalla de Notas, `AppCard` + menú por ítem).

**Tech Stack:** Laravel 11 + Pest (tests escritos, no ejecutados), Flutter 3.x, Riverpod 2, `file_picker` (ya presente), ARB es/en.

**Spec:** `docs/superpowers/specs/2026-10-07-estados-normalizados-y-materiales-profesor-design.md`

## Global Constraints

- Sin dependencias nuevas.
- Todos los textos de la app vía ARB (es/en) + `flutter gen-l10n`.
- `efe-app`: **no ejecutar Pest** (borra la base de desarrollo); verificar con `./vendor/bin/pint` y `php -l`. Tests Pest igual se escriben.
- `efe-app`: rama `feat/materiales-profesor` (desde `preprod`). No tocar el panel web ni notificaciones a alumnos.
- `efe_mobile`: rama `feat/estados-y-materiales` (compartida con el plan de estados), commits convencionales (`feat(api):`, `feat(materials):`, `feat(classroom):`).
- Reusar `AppCard`, `EmptyState`, `ErrorView`, `PagedTabList`, patrón de bottom sheet y `ApiException`.
- Verificación mobile: `flutter analyze` (0 issues) y `flutter test` en verde.

## Review Focus

- Editar sin elegir archivos: no llama a `replaceFiles` y conserva los archivos actuales.
- Visibilidad específica sin alumnos: bloqueada en el cliente (mínimo 1), no llega al API.
- 403 o error de red: sheet abierto con error inline; eliminar/crear desde el listado con snackbar de error, sin crash.
- Material legado sin archivos (`public_url` vacío): el tile y el sheet no rompen.
- Más de 10 archivos o un archivo de más de 50 MB: rechazado en el cliente con mensaje claro.

---

### Task 1: Backend — policy de materiales acotada por asignación

**Files:**
- Modify: `app/Policies/MaterialPolicy.php`
- Modify: `tests/Feature/Api/MaterialsTest.php`

**Interfaces:**
- Consumes: `Classrooms::professor()` (belongsToMany con `classroom_professor`), `$user->hasRole([...])`.
- Produces: `view/update/delete(User, Material)` con profesor solo de aulas asignadas; `create(User, ?string $classroomId = null)` con profesor solo de aula asignada. Admin/branch sin cambios. Alumno/padre sin cambios.

- [ ] **Step 1: Escribir/actualizar los tests Pest**

En `tests/Feature/Api/MaterialsTest.php`:

```php
test('professor can create material in an assigned classroom', function () {
    $professorData = createProfessorForMaterials();
    Sanctum::actingAs($professorData['user']);
    $classroom = Classrooms::factory()->create();
    $classroom->professor()->attach($professorData['professor']->id);

    $this->postJson('/api/v1/materials', [
        'name' => 'Material del Profesor',
        'classroom_id' => $classroom->id,
    ])->assertStatus(201);
});

test('professor cannot create material in a classroom not assigned', function () {
    $professorData = createProfessorForMaterials();
    Sanctum::actingAs($professorData['user']);
    $classroom = Classrooms::factory()->create();

    $this->postJson('/api/v1/materials', [
        'name' => 'Material',
        'classroom_id' => $classroom->id,
    ])->assertStatus(403);
});

// Análogos: professor can view/update/delete material of an assigned classroom,
// y 403 para view/update/delete de un aula no asignada (usar GET/PUT/DELETE
// /api/v1/materials/{id} y adjuntar el profesor con $classroom->professor()->attach(...)).
```

Además: actualizar el test existente `professor can create material` (línea ~151) para asignar el aula (`$classroom->professor()->attach($professorData['professor']->id);`), porque hoy crea en un aula sin asignar y con la policy nueva debe dar 403.

- [ ] **Step 2: Implementar la policy**

`MaterialPolicy`: helper privado `professorAssigned(User $user, ?string $classroomId): bool` → `Classrooms::whereKey($classroomId)->whereHas('professor', fn ($q) => $q->where('professor_data.user_id', $user->id))->exists()`; `view` de profesor → `$this->professorAssigned($user, $material->classroom_id)`; `create(User $user, ?string $classroomId = null)` → admin/branch true, profesor `professorAssigned(...)`, resto false; `update`/`delete` → admin/branch true, profesor `professorAssigned($user, $material->classroom_id)`, resto false. Alumno/padre de `view` quedan igual que hoy.

En `MaterialController@store` el authorize pasa el aula: `$this->authorize('create', [Material::class, $validated['classroom_id']]);`.

- [ ] **Step 3: Verificar estilo**

Run (en `/opt/dev/efe-app`): `./vendor/bin/pint app/Policies/MaterialPolicy.php app/Http/Controllers/Api/Materials/MaterialController.php tests/Feature/Api/MaterialsTest.php && php -l app/Policies/MaterialPolicy.php`
Expected: sin errores. (No correr Pest.)

- [ ] **Step 4: Commit**

```bash
git add app/Policies/MaterialPolicy.php app/Http/Controllers/Api/Materials/MaterialController.php tests/Feature/Api/MaterialsTest.php
git commit -m "feat(api): acotar materiales del profesor a sus aulas asignadas"
```

---

### Task 2: Backend — files[], student_ids, visibilidad y limpieza de media

**Files:**
- Modify: `app/Http/Requests/Api/Materials/StoreMaterialRequest.php`, `UpdateMaterialRequest.php`, `app/Http/Controllers/Api/Materials/MaterialController.php`, `app/Http/Controllers/Api/Classrooms/ClassroomController.php` (`materials`)
- Modify: `tests/Feature/Api/MaterialsTest.php`

**Interfaces:**
- Consumes: `Material::CATEGORIES` (`['Vocabulario', 'Gramática', 'Exámenes', 'Tareas', 'Audio', 'Otro']`), `Material::students()` (belongsToMany `material_student`), Spatie media collection `materials`.
- Produces: store/update/upload/destroy según spec; `GET /classrooms/{id}/materials` devuelve cada material con `students` (ids).

- [ ] **Step 1: Escribir los tests Pest**

```php
test('store accepts multiple files and specific students', function () {
    $admin = createAdminForMaterials();
    Sanctum::actingAs($admin);
    Storage::fake('public');
    $classroom = Classrooms::factory()->create();
    $student = StudentData::factory()->create();

    $response = $this->post('/api/v1/materials', [
        'name' => 'Unidad 1',
        'classroom_id' => $classroom->id,
        'visibility' => 'specific',
        'student_ids' => [$student->id],
        'files' => [
            UploadedFile::fake()->create('guia.pdf', 10, 'application/pdf'),
            UploadedFile::fake()->create('audio.mp3', 10, 'audio/mpeg'),
        ],
    ]);

    $response->assertStatus(201);
    $material = Material::latest('created_at')->first();
    expect($material->getMedia('materials'))->toHaveCount(2);
    $this->assertDatabaseHas('material_student', [
        'material_id' => $material->id,
        'student_id' => $student->id,
    ]);
});

test('update to visibility all detaches students', function () {
    // material con visibility specific + student attach; PATCH visibility=all;
    // assertDatabaseMissing('material_student', ...)
});

test('upload replaces the whole media set with files[]', function () {
    // material con 1 media; POST /upload con files[] (2 archivos);
    // getMedia('materials') toHaveCount(2)
});

test('destroy clears the media collection', function () {
    // material con media; DELETE; assert media table sin filas del modelo
});

test('classroom materials listing includes linked students', function () {
    // student attach al aula y al material; GET /classrooms/{id}/materials
    // assertJsonPath('data.0.students.0.id', $student->id)
});
```

Imports nuevos: `Illuminate\Http\UploadedFile`, `Illuminate\Support\Facades\Storage`.

- [ ] **Step 2: Implementar requests**

`StoreMaterialRequest`: `name` required max 255; `description` nullable max 1000; `type` nullable max 255; `category` nullable `in:` CATEGORIES; `classroom_id` required exists; `visibility` nullable `in:all,specific`; `available_until` nullable date `after:now`; `student_ids` `required_if:visibility,specific` array + `student_ids.*` exists:student_data,id; `files` nullable array max 10 + `files.*` file max 51200; `file` nullable file max 51200 (legado).

`UpdateMaterialRequest`: `name` sometimes; `description`/`type`/`category` nullable (category `in:` CATEGORIES); `visibility` sometimes `in:all,specific`; `available_until` nullable date; `student_ids` nullable array + exists.

- [ ] **Step 3: Implementar el controlador**

- `store`: autorizar con `[Material::class, $validated['classroom_id']]`; juntar `$request->file('files', [])` + `file` legado; `unset` de `files`, `file`, `student_ids`; `visibility ??= 'all'`; crear; adjuntar cada archivo a la colección `materials`; `public_url` = primer media; si `specific` → `students()->sync($studentIds)`; `load(['classroom', 'students'])`; 201.
- `update`: autorizar; guardar `student_ids` aparte; `update($validated)`; si `visibility` resultante es `all` → `detach()`; si no y vienen ids → `sync($ids)`; devolver resource.
- `upload`: validar `files` `required_without:file` array max 10 y `files.*` file max 51200 (más `file` legado); `clearMediaCollection('materials')`; adjuntar set; actualizar `public_url`; devolver resource.
- `destroy`: `clearMediaCollection('materials')` antes del `delete()`.
- `ClassroomController@materials`: `$classroom->materials()->with('students:id')->orderBy(...)` (si Eloquent no incluye las columnas pivote, caer a `with('students')`).

- [ ] **Step 4: Verificar estilo**

Run: `./vendor/bin/pint app/Http/Requests/Api/Materials app/Http/Controllers/Api/Materials app/Http/Controllers/Api/Classrooms/ClassroomController.php tests/Feature/Api/MaterialsTest.php && php -l app/Http/Controllers/Api/Materials/MaterialController.php`
Expected: sin errores.

- [ ] **Step 5: Commit**

```bash
git add app/Http/Requests/Api/Materials app/Http/Controllers/Api/Materials app/Http/Controllers/Api/Classrooms/ClassroomController.php tests/Feature/Api/MaterialsTest.php
git commit -m "feat(api): materiales con multiples archivos, alumnos y media limpia"
```

---

### Task 3: Mobile — modelo con alumnos vinculados y tipo de archivo

**Files:**
- Modify: `lib/features/classrooms/domain/material_model.dart` (+ regenerar `.freezed.dart`)
- Create: `lib/features/classrooms/domain/material_upload_file.dart`, `lib/features/classrooms/domain/material_type.dart`
- Test: `test/classrooms/material_model_test.dart`, `test/classrooms/material_type_test.dart`

**Interfaces:**
- Produces: `MaterialModel.studentIds` (`List<String>`, default `[]`); `MaterialUploadFile({required String name, int size, String? path, Uint8List? bytes})`; `String materialTypeFor(String fileName)` → `pdf|image|video|audio|link|other`.

- [ ] **Step 1: Escribir los tests que fallan**

`test/classrooms/material_model_test.dart` (agregar casos):

```dart
test('parses student ids from the detail relationships', () {
  final model = MaterialModel.fromJson({
    'data': {
      'id': 'm1',
      'attributes': {'name': 'Guía'},
      'relationships': {
        'students': {'data': [{'type': 'students', 'id': 's1'}, {'type': 'students', 'id': 's2'}]},
      },
    },
  });
  expect(model.studentIds, ['s1', 's2']);
});

test('parses student ids from the classroom listing', () {
  final model = MaterialModel.fromJson({
    'id': 'm1',
    'name': 'Guía',
    'students': [{'id': 's1'}],
  });
  expect(model.studentIds, ['s1']);
});
```

`test/classrooms/material_type_test.dart`: `materialTypeFor('guia.pdf') == 'pdf'`, `foto.JPG → image`, `video.mp4 → video`, `tema.mp3 → audio`, `enlace.url → link`, `notas.docx → other`.

- [ ] **Step 2: Correr y verificar que fallan**

Run: `flutter test test/classrooms/material_model_test.dart test/classrooms/material_type_test.dart`
Expected: FAIL (campos y archivos inexistentes).

- [ ] **Step 3: Implementar y regenerar**

- `MaterialModel`: agregar `@Default([]) List<String> studentIds`; parsear de `json['relationships']['students']['data']` o `json['data']['relationships']['students']['data']`, y del array directo `json['students']` (listado), tomando `id` de cada elemento.
- `material_upload_file.dart` y `material_type.dart` con las firmas de arriba.
- Run: `dart run build_runner build --delete-conflicting-outputs`
Expected: `material_model.freezed.dart` regenerado.

- [ ] **Step 4: Correr y verificar**

Run: `flutter test test/classrooms/material_model_test.dart test/classrooms/material_type_test.dart`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/features/classrooms/domain test/classrooms/material_model_test.dart test/classrooms/material_type_test.dart
git commit -m "feat(materials): modelo con alumnos vinculados y tipo de archivo"
```

---

### Task 4: Mobile — MaterialApi, MaterialRepository y provider

**Files:**
- Modify: `lib/core/api/api_client.dart` (`upload` acepta `Options?`)
- Create: `lib/features/classrooms/data/material_api.dart`, `lib/features/classrooms/data/material_repository.dart`, `lib/features/classrooms/providers/material_provider.dart`
- Test: `test/classrooms/material_repository_test.dart`

**Interfaces:**
- Consumes: `ApiClient.upload/get/patch/delete`, `ClassroomApi.getClassroomStudents`, `MaterialUploadFile`, `MaterialModel`, `StudentModel`, `PageResult`, `ApiException`.
- Produces:
  - `MaterialApi.createMaterial(FormData)`, `updateMaterial(String id, Map<String, dynamic> data)`, `replaceFiles(String id, FormData data)`, `deleteMaterial(String id)`, `getMaterial(String id)`.
  - `MaterialRepository.createMaterial({required String classroomId, required String name, String? description, String? type, String? category, String? visibility, String? availableUntil, List<String> studentIds = const [], required List<MaterialUploadFile> files}) → Future<MaterialModel>`
  - `updateMaterial(String id, {String? name, String? description, String? type, String? category, String? visibility, String? availableUntil, List<String>? studentIds}) → Future<MaterialModel>`
  - `replaceFiles(String id, {required List<MaterialUploadFile> files, String? type}) → Future<MaterialModel>`
  - `deleteMaterial(String id) → Future<void>`
  - `getMaterial(String id) → Future<MaterialModel>`
  - `getClassroomStudents(String classroomId) → Future<List<StudentModel>>` (todas las páginas, `limit: 100`)
  - `materialRepositoryProvider`.

- [ ] **Step 1: Escribir los tests que fallan**

`test/classrooms/material_repository_test.dart` con `_FakeMaterialApi implements MaterialApi` (registra `FormData`/payloads) y `_FakeClassroomApi implements ClassroomApi`:

El `_FakeMaterialApi` implementa los 5 métodos de `MaterialApi` (los no usados lanzan `UnimplementedError()`); el `_FakeClassroomApi` implementa `getClassroomStudents` y deja el resto con `UnimplementedError()`.

- `createMaterial` arma `FormData` con `classroom_id`, `name`, `visibility` y N entradas con clave `files[]`; `publicUrl` del material parseado.
- `updateMaterial` manda solo los campos no nulos (p. ej. `{'name': 'X', 'visibility': 'specific', 'student_ids': [...]}`).
- `replaceFiles` llama a `POST /materials/{id}/upload` con `files[]`.
- `deleteMaterial` llama al endpoint.
- `getMaterial` parsea el detalle con `studentIds`.
- `getClassroomStudents` recorre páginas (fake: 100 + 50, `total: 150`) → 150 alumnos y 2 llamadas.
- `DioException` → `ApiException`.

- [ ] **Step 2: Correr y verificar que fallan**

Run: `flutter test test/classrooms/material_repository_test.dart`
Expected: FAIL (no existen las clases).

- [ ] **Step 3: Implementar**

- `ApiClient.upload(String path, FormData data, {Options? options}) => dio.post(path, data: data, options: options);`
- `MaterialApi` usa `Options(sendTimeout: Duration(minutes: 5), receiveTimeout: Duration(minutes: 5))` en create/replaceFiles.
- `MaterialRepository`: `_buildFormData(fields, files)` — campos simples como `MapEntry(key, value.toString())`, listas como `key[]`, archivos como `files[]` (`MultipartFile.fromBytes` si `bytes != null`, si no `fromFile(path)`); `availableUntil` ISO 8601; `_handleDioError` igual que los demás repos.
- `material_provider.dart`: `materialApiProvider` + `materialRepositoryProvider` (depende de `apiClientProvider` y `classroomApiProvider`).

- [ ] **Step 4: Correr y verificar**

Run: `flutter test test/classrooms/material_repository_test.dart`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/core/api/api_client.dart lib/features/classrooms/data/material_api.dart lib/features/classrooms/data/material_repository.dart lib/features/classrooms/providers/material_provider.dart test/classrooms/material_repository_test.dart
git commit -m "feat(materials): api y repositorio de materiales"
```

---

### Task 5: Mobile — MaterialFormSheet (crear/editar)

**Files:**
- Create: `lib/features/classrooms/screens/widgets/material_form_sheet.dart`
- Modify: `lib/l10n/app_es.arb`, `lib/l10n/app_en.arb`
- Test: `test/classrooms/material_form_sheet_test.dart`

**Interfaces:**
- Consumes: `materialRepositoryProvider`, `MaterialUploadFile`, `materialTypeFor`, `Material::CATEGORIES` (hardcode `const materialCategories = ['Vocabulario', 'Gramática', 'Exámenes', 'Tareas', 'Audio', 'Otro']`), `file_picker` (solo en el picker por defecto).
- Produces: `MaterialFormSheet({required String classroomId, MaterialModel? material, Future<List<MaterialUploadFile>> Function()? pickFiles})`; devuelve `true` por `Navigator.pop` si guardó.

Claves ARB nuevas: `materialFormTitleNew/Edit`, `materialFormName`, `materialFormCategory`, `materialFormDescription`, `materialFormFiles`, `materialFormPickFiles`, `materialFormVisibility`, `materialFormVisibilityAll` ("Todos"/"Everyone"), `materialFormVisibilitySpecific` ("Alumnos específicos"/"Specific students"), `materialFormAvailableUntil`, `materialFormClearDate`, `materialFormSave`, `materialFormNameRequired`, `materialFormFilesRequired`, `materialFormFilesTooMany`, `materialFormFileTooLarge`, `materialFormStudentsRequired`, `materialFormError`, `materialFormDetailError`.

- [ ] **Step 1: Escribir los tests que fallan** (`test/classrooms/material_form_sheet_test.dart`, con fake de `MaterialRepository` que implementa sus 6 métodos)

```dart
await tester.pumpWidget(ProviderScope(
  overrides: [materialRepositoryProvider.overrideWithValue(fakeRepo)],
  child: localizedApp(
    home: Scaffold(body: MaterialFormSheet(
      classroomId: 'c1',
      pickFiles: () async => [
        MaterialUploadFile(name: 'guia.pdf', size: 1000, path: '/tmp/guia.pdf'),
      ],
    )),
  ),
));
await tester.pumpAndSettle();
```

- Guardar sin nombre ni archivos → muestra `materialFormNameRequired` y `materialFormFilesRequired`.
- Picker inyectado devuelve 2 archivos → se ven los chips con los nombres.
- 11 archivos → `materialFormFilesTooMany`; archivo de `51 * 1024 * 1024` → `materialFormFileTooLarge`.
- Visibilidad específica + tocar guardar sin alumnos → `materialFormStudentsRequired`.
- Visibilidad específica → se listan los alumnos del fake (`getClassroomStudents`).
- Crear OK: `createMaterial` recibe `name`, `category`, `visibility`, `studentIds`, `files`; el sheet se cierra (`true`).
- Editar `material` existente: precarga nombre y `studentIds` (vía `getMaterial`); si no se eligen archivos, **no** llama a `replaceFiles` (Review Focus); si se eligen, llama a `replaceFiles` y `type` = `materialTypeFor(primer archivo)`.
- `createMaterial` lanza `ApiException` → `materialFormError` inline y el sheet sigue abierto.

- [ ] **Step 2: Correr y verificar que fallan**

Run: `flutter test test/classrooms/material_form_sheet_test.dart`
Expected: FAIL (no existe el sheet).

- [ ] **Step 3: Implementar + ARB**

- Estructura visual igual a `CreateQualificationSheet` (handle, contenedor redondeado, `SingleChildScrollView` con `viewInsets`, botón guardar con spinner).
- Campos: nombre, dropdown de categoría (incluye opción vacía), descripción multiline, archivos (botón + chips nombre/tamaño), visibilidad (segmented o dropdown), lista de alumnos con checkbox cuando es específica (carga con `getClassroomStudents`, spinner y retry), `available_until` con `showDatePicker` + `showTimePicker` y botón limpiar.
- Picker por defecto: `FilePicker.platform.pickFiles(allowMultiple: true, withData: kIsWeb)`.
- Validaciones cliente (1..10 archivos, ≤50 MB c/u, específicos con ≥1 alumno, nombre no vacío).
- En edición: `getMaterial(id)` al abrir para `studentIds` y campos; error → estado con `materialFormDetailError` + retry.
- `flutter gen-l10n`.

- [ ] **Step 4: Correr y verificar**

Run: `flutter test test/classrooms/material_form_sheet_test.dart`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/features/classrooms/screens/widgets/material_form_sheet.dart lib/l10n test/classrooms/material_form_sheet_test.dart
git commit -m "feat(materials): formulario de crear y editar material"
```

---

### Task 6: Mobile — pestaña Materiales con CTA, menú y eliminación

**Files:**
- Modify: `lib/features/auth/domain/user_model.dart`, `lib/features/classrooms/screens/classroom_detail_screen.dart`, `lib/features/classrooms/screens/widgets/classroom_related_tabs.dart`, `lib/features/classrooms/screens/widgets/material_tile.dart`
- Modify: `lib/l10n/app_es.arb`, `app_en.arb`
- Test: `test/classrooms/material_actions_test.dart`

**Interfaces:**
- Consumes: `MaterialFormSheet` (Task 5), `materialRepositoryProvider`, `classroomMaterialsProvider`, `MaterialModel.studentIds`.
- Produces: `UserModelRoleX.canManageMaterials` (profesor/admin/branch); `ClassroomMaterialsTab({required String classroomId, bool canManage = false})`; `MaterialTile({required MaterialModel material, bool canManage = false, VoidCallback? onEdit, VoidCallback? onDelete})`.

Claves ARB nuevas: `materialsAdd` ("Cargar material"), `materialsCreated`, `materialsUpdated`, `materialsDeleted`, `materialsDeleteError`, `materialsEdit`, `materialsDelete`, `materialsDeleteTitle`, `materialsDeleteMessage` ("También se borran sus archivos."), `materialsDeleteCancel`, `materialsDeleteConfirm`, `materialsStudentCount(count)` (plural ICU).

- [ ] **Step 1: Escribir los tests que fallan** (`test/classrooms/material_actions_test.dart`)

- Profesor: en la pestaña Materiales se ve "Cargar material" y el menú "⋮" del tile (con material cargado); alumno: no ve ninguno de los dos.
- Tile con `visibility: 'specific'` y 2 `studentIds` → chip "2 alumnos".
- Tile con `publicUrl` vacío (legado sin archivo) renderiza sin excepción (Review Focus).
- Tocar "Cargar material" abre el sheet (`materialFormTitleNew`).
- Tocar Editar abre el sheet con el nombre precargado.
- Tocar Eliminar → diálogo → confirmar → `deleteMaterial` llamado, lista refrescada y snackbar "Material eliminado".
- `deleteMaterial` lanza → snackbar `materialsDeleteError`, sin crash.
- Crear desde el listado OK → `createMaterial` llamado, sheet cerrado, snackbar "Material publicado".

Pump: `ClassroomDetailScreen` con overrides de `authRepositoryProvider` (profesor/alumno), `classroomRepositoryProvider` (fake con aula y materiales mutables) y `materialRepositoryProvider` (fake). Los fakes se definen en el archivo nuevo copiando los de `test/classrooms/classroom_detail_screen_test.dart` (convención de la suite: cada test file define los suyos).

- [ ] **Step 2: Correr y verificar que fallan**

Run: `flutter test test/classrooms/material_actions_test.dart`
Expected: FAIL (la pestaña no tiene CTA ni menú).

- [ ] **Step 3: Implementar + ARB**

- `UserModelRoleX.canManageMaterials`: `const allowed = {'professor', 'admin', 'branch'}; return allowed.contains(role) || roles.any(allowed.contains);`
- `ClassroomDetailScreen`: pasar `canManage: user.canManageMaterials` a `ClassroomMaterialsTab`.
- `ClassroomMaterialsTab`: `PagedTabList` envuelto en `Expanded` dentro de una `Column`; barra inferior "Cargar material" (patrón `_LoadGradeBar`) si `canManage`; abre `MaterialFormSheet` en `showModalBottomSheet<bool>`; al volver `true` → `ref.invalidate(classroomMaterialsProvider(classroomId))` + snackbar (creado/actualizado según `material == null`).
- `MaterialTile`: acciones opcionales (menú `⋮` con Editar/Eliminar) cuando `canManage`; chip `materialsStudentCount(studentIds.length)` si `visibility == 'specific'`.
- Eliminar: `AlertDialog` con `materialsDeleteTitle/Message/Cancel/Confirm`; al confirmar, `deleteMaterial` → invalidate + snackbar; `catch` → snackbar `materialsDeleteError`.
- `flutter gen-l10n`.

- [ ] **Step 4: Correr y verificar**

Run: `flutter test test/classrooms`
Expected: PASS (nuevos y existentes).

- [ ] **Step 5: Commit**

```bash
git add lib/features/auth/domain/user_model.dart lib/features/classrooms/screens lib/l10n test/classrooms/material_actions_test.dart
git commit -m "feat(classroom): materiales del profesor con carga, edicion y borrado"
```

---

### Task 7: Cierre

- [ ] **Step 1: Verificación mobile**

Run: `flutter gen-l10n && flutter analyze && flutter test`
Expected: 0 issues, suite completa en verde.

- [ ] **Step 2: Verificación backend**

Run (en `/opt/dev/efe-app`): `./vendor/bin/pint --test app/Policies/MaterialPolicy.php app/Http/Requests/Api/Materials app/Http/Controllers/Api/Materials app/Http/Controllers/Api/Classrooms/ClassroomController.php`
Expected: sin cambios pendientes. (`php -l` sobre los archivos tocados.)

- [ ] **Step 3: Prueba manual (contra API dev, usuario profesor)**

Checklist: aula asignada → Materiales → Cargar material (2 archivos + específicos) → Editar (reemplazar archivos) → Eliminar; aula no asignada → 403; alumno → sin acciones. Registrar el resultado en el commit/PR.

- [ ] **Step 4: Commit final si quedó algo pendiente**

```bash
git add -A && git commit -m "chore(materials): cierre de verificacion"
```
