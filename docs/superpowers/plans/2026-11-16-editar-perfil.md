# Editar perfil (datos, foto y contraseña) — Plan de implementación

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Permitir que cualquier usuario edite su nombre, email, foto y contraseña desde una pantalla nueva, con los cambios reflejados en toda la app y en el chat.

**Architecture:** Backend Laravel agrega el endpoint de contraseña, sincroniza las filas de rol propias al editar datos y expone el avatar en las respuestas de auth. Flutter agrega una capa `profile/` (API, repositorio, notifier), una pantalla `/profile/edit` y mantiene `authProvider` como única fuente del usuario mediante `AuthNotifier.applyUser`.

**Tech Stack:** Flutter 3.44 / Dart 3.12, Riverpod 2, go_router 14, dio 5, `file_picker` 8, Laravel + Sanctum + Spatie Media Library, Pest, l10n ARB ES/EN.

**Spec:** Diseño aprobado en la conversación (2026-11-16).

## Global Constraints

- No agregar dependencias Flutter nuevas: usar `file_picker` y `dio` existentes.
- Foto: jpg/jpeg/png/gif, máximo 2 MB (2048 KB), tal como valida el backend.
- Contraseña: mínimo 8 caracteres, confirmada.
- Email: único en `users`, en minúsculas.
- El nombre/email editado actualiza `users` y **solo** las filas de rol cuyo `user_id` sea el del usuario autenticado. Nunca tocar el `student_data` de un hijo alcanzado por `current_selected_id`.
- "Cerrar otras sesiones" = borrar solo tokens Sanctum distintos al actual. No tocar sesiones web ni registros push.
- Todos los textos nuevos en ES y EN, con las claves en `app_es.arb` y `app_en.arb`, regenerando `lib/l10n/app_localizations*.dart`.
- `flutter analyze` sin errores nuevos (la base tiene avisos informativos) y `flutter test` sin fallos nuevos (la base tiene 2 fallos preexistentes).
- En el repo Laravel NO ejecutar Pest/`php artisan test`: usa la misma base de desarrollo y la borra (ver `AGENTS.md`). Los tests se escriben para CI; la verificación local es `php -l` y revisión.
- Commits chicos, uno por tarea, con mensajes `feat:`/`test:`.

## Review Focus

1. **Padre que edita su perfil:** su `student_data` hijo no debe cambiar. Test en Task 2.
2. **Foto en el límite:** exactamente 2 MB se acepta; 2 MB + 1 byte se rechaza en cliente y servidor. Tests en Tasks 4 y 11.
3. **Contraseña actual incorrecta:** debe mostrar el error en el campo correcto y no cerrar sesión. Tests en Tasks 3 y 12.
4. **Email ya registrado:** 422 debe mostrarse sin perder lo escrito. Tests en Tasks 6 y 10.
5. **Fallo de red al subir la foto:** el spinner termina, se muestra error y el avatar anterior queda visible. Test en Task 11.

---

## Task 0: Línea base

**Files:** ninguno.

- [ ] **Step 1: Verificar el estado inicial**

En el worktree móvil:

```bash
flutter analyze
flutter test
```

Expected: analyze sin errores (los avisos informativos de la base son aceptables); tests con solo los 2 fallos preexistentes conocidos.

En el repo Laravel no se corre Pest (ver Global Constraints).

---

## Task 1: Exponer el avatar en las respuestas de autenticación

**Files:**
- Modify: `/opt/dev/efe-app/.worktrees/editar-perfil/app/Models/User.php`
- Modify: `/opt/dev/efe-app/.worktrees/editar-perfil/app/Http/Controllers/Api/Profile/ProfileController.php`
- Modify: `/opt/dev/efe-app/.worktrees/editar-perfil/app/Http/Controllers/Api/Auth/MeController.php`
- Modify: `/opt/dev/efe-app/.worktrees/editar-perfil/app/Http/Controllers/Api/Auth/LoginController.php`
- Test: `/opt/dev/efe-app/.worktrees/editar-perfil/tests/Feature/Api/AuthTest.php`
- Test: `/opt/dev/efe-app/.worktrees/editar-perfil/tests/Feature/Api/ProfileTest.php`

**Interfaces:**
- Produces: `User::avatarUrl(): ?string`.
- Produces: clave JSON `avatar` en `data.user` del login, en `data` de `/auth/me` y en `data` del `PATCH /profile`.

- [ ] **Step 1: Escribir los tests que fallan**

En `AuthTest.php`:

```php
test('login and me expose the avatar url', function () {
    Storage::fake('public');
    $user = User::factory()->create(['password' => bcrypt('password123')]);
    $user->asStringKeyed()
        ->addMedia(UploadedFile::fake()->image('avatar.png', 100, 100))
        ->toMediaCollection('avatar');

    $login = $this->postJson('/api/v1/auth/login', [
        'email' => $user->email,
        'password' => 'password123',
    ])->assertOk();

    expect($login->json('data.user.avatar'))->toBeString()->toContain('avatar');

    Sanctum::actingAs($user);
    $me = $this->getJson('/api/v1/auth/me')->assertOk();
    expect($me->json('data.avatar'))->toBeString()->toContain('avatar');
});

test('login and me return a null avatar when there is no media', function () {
    $user = User::factory()->create(['password' => bcrypt('password123')]);

    $login = $this->postJson('/api/v1/auth/login', [
        'email' => $user->email,
        'password' => 'password123',
    ])->assertOk();
    expect($login->json('data.user.avatar'))->toBeNull();

    Sanctum::actingAs($user);
    expect($this->getJson('/api/v1/auth/me')->json('data.avatar'))->toBeNull();
});
```

Añadir `use Illuminate\Http\UploadedFile;` y `use Illuminate\Support\Facades\Storage;`.

En `ProfileTest.php`, ampliar el test existente de `show` para exigir `avatar` y otro para el update:

```php
test('authenticated user can update profile and receives avatar key', function () {
    $user = createAdminForProfile();
    Sanctum::actingAs($user);

    $this->patchJson('/api/v1/profile', [
        'name' => 'Updated Name',
        'email' => $user->email,
    ])->assertOk()->assertJsonStructure(['data' => ['avatar']]);
});
```

- [ ] **Step 2: Correr y ver fallar**

No ejecutar Pest. Verificar que los tests escritos cubren la clave `avatar`.

- [ ] **Step 3: Implementar `avatarUrl()` y usarlo**

En `User.php`, junto a `getFullnameAttribute()`:

```php
public function avatarUrl(): ?string
{
    $media = \Spatie\MediaLibrary\MediaCollections\Models\Media::query()
        ->where('model_type', $this->getMorphClass())
        ->where('model_id', (string) $this->getKey())
        ->where('collection_name', 'avatar')
        ->first();

    return $media?->getUrl();
}
```

Reemplazar el método privado `avatarUrl()` de `ProfileController` por `$user->avatarUrl()`. Agregar `'avatar' => $user->avatarUrl()` en:
- `ProfileController@show`
- `ProfileController@update`
- `MeController@show`
- el array `user` de `LoginController@login`

- [ ] **Step 4: Verificar sintaxis**

```bash
docker run --rm --entrypoint php -v /opt/dev/efe-app/.worktrees/editar-perfil:/app megalomaniac-prod -l /app/app/Models/User.php
```

Repetir para cada archivo PHP tocado. Expected: `No syntax errors detected`.

- [ ] **Step 5: Commit**

```bash
git -C /opt/dev/efe-app/.worktrees/editar-perfil add app/Models/User.php app/Http/Controllers/Api/Profile/ProfileController.php app/Http/Controllers/Api/Auth/MeController.php app/Http/Controllers/Api/Auth/LoginController.php tests/Feature/Api/AuthTest.php tests/Feature/Api/ProfileTest.php
git -C /opt/dev/efe-app/.worktrees/editar-perfil commit -m "feat: expose avatar in auth and profile responses"
```

---

## Task 2: Sincronizar las filas de rol propias al editar nombre/email

**Files:**
- Modify: `/opt/dev/efe-app/.worktrees/editar-perfil/app/Http/Controllers/Api/Profile/ProfileController.php`
- Test: `/opt/dev/efe-app/.worktrees/editar-perfil/tests/Feature/Api/ProfileTest.php`

**Interfaces:**
- Consumes: `User::avatarUrl()` de Task 1.
- Produces: `PATCH /profile` actualiza `users`, `professor_data`, `parent_data`, `user_data` y el `student_data` propio, en una transacción.

- [ ] **Step 1: Escribir los tests**

```php
test('profile update syncs owned role records but not a parent child', function () {
    $parent = User::factory()->create(['name' => 'Old', 'email' => 'old@example.com']);
    $parentData = \App\Models\ParentData::factory()->create([
        'user_id' => $parent->id,
        'fullname' => 'Old',
        'email' => 'old@example.com',
    ]);
    $child = \App\Models\StudentData::factory()->create([
        'user_id' => null,
        'fullname' => 'Child Name',
        'email' => 'child@example.com',
    ]);
    $parent->update(['current_selected_id' => $child->id]);

    Sanctum::actingAs($parent);
    $this->patchJson('/api/v1/profile', [
        'name' => 'New Name',
        'email' => 'new@example.com',
    ])->assertOk();

    $this->assertDatabaseHas('parent_data', [
        'id' => $parentData->id,
        'fullname' => 'New Name',
        'email' => 'new@example.com',
    ]);
    $this->assertDatabaseHas('student_data', [
        'id' => $child->id,
        'fullname' => 'Child Name',
        'email' => 'child@example.com',
    ]);
});

test('profile update syncs every owned role record', function () {
    $user = User::factory()->create();
    $professor = \App\Models\ProfessorData::factory()->create(['user_id' => $user->id]);
    $userData = \App\Models\UserData::factory()->create([
        'user_id' => $user->id,
        'role' => 'admin',
    ]);
    $student = \App\Models\StudentData::factory()->create(['user_id' => $user->id]);

    Sanctum::actingAs($user);
    $this->patchJson('/api/v1/profile', [
        'name' => 'Synced Name',
        'email' => 'synced@example.com',
    ])->assertOk();

    foreach ([
        ['professor_data', $professor->id],
        ['user_data', $userData->id],
        ['student_data', $student->id],
    ] as [$table, $id]) {
        $this->assertDatabaseHas($table, [
            'id' => $id,
            'fullname' => 'Synced Name',
            'email' => 'synced@example.com',
        ]);
    }
});

test('profile update rolls back when the users update fails', function () {
    $user = User::factory()->create();
    $parent = \App\Models\ParentData::factory()->create([
        'user_id' => $user->id,
        'fullname' => 'Original',
    ]);

    Sanctum::actingAs($user);
    $this->patchJson('/api/v1/profile', [
        'name' => 'Changed',
        'email' => User::factory()->create()->email,
    ])->assertStatus(422);

    $this->assertDatabaseHas('parent_data', [
        'id' => $parent->id,
        'fullname' => 'Original',
    ]);
});
```

- [ ] **Step 2: Implementar la transacción**

En `ProfileController@update`:

```php
$validated = $request->validated();

DB::transaction(function () use ($user, $validated) {
    $user->update($validated);
    $this->syncOwnedRoleRecords($user, $validated['name'], $validated['email']);
});
```

Método privado:

```php
private function syncOwnedRoleRecords(User $user, string $name, string $email): void
{
    $attributes = ['fullname' => $name, 'email' => $email];

    $user->professorData()->withoutGlobalScopes()->update($attributes);
    $user->parentData()->withoutGlobalScopes()->update($attributes);
    $user->userData()->withoutGlobalScopes()->update($attributes);

    \App\Models\StudentData::withoutGlobalScopes()
        ->where('user_id', $user->id)
        ->update($attributes);
}
```

Importar `Illuminate\Support\Facades\DB`. No usar `$user->studentData()` porque con `current_selected_id` apunta al hijo.

- [ ] **Step 3: Verificar sintaxis**

```bash
docker run --rm --entrypoint php -v /opt/dev/efe-app/.worktrees/editar-perfil:/app megalomaniac-prod -l /app/app/Http/Controllers/Api/Profile/ProfileController.php
```

- [ ] **Step 4: Commit**

```bash
git -C /opt/dev/efe-app/.worktrees/editar-perfil add app/Http/Controllers/Api/Profile/ProfileController.php tests/Feature/Api/ProfileTest.php
git -C /opt/dev/efe-app/.worktrees/editar-perfil commit -m "feat: sync owned role profiles on profile update"
```

---

## Task 3: Endpoint para cambiar contraseña

**Files:**
- Create: `/opt/dev/efe-app/.worktrees/editar-perfil/app/Http/Requests/ProfilePasswordUpdateRequest.php`
- Modify: `/opt/dev/efe-app/.worktrees/editar-perfil/app/Http/Controllers/Api/Profile/ProfileController.php`
- Modify: `/opt/dev/efe-app/.worktrees/editar-perfil/routes/api.php`
- Test: `/opt/dev/efe-app/.worktrees/editar-perfil/tests/Feature/Api/ProfileTest.php`

**Interfaces:**
- Produces: `PATCH /api/v1/profile/password`, body `{current_password, password, password_confirmation}`.
- Produces: 200 `{data:{message}}`; 422 con `errors.current_password` o `errors.password`.

- [ ] **Step 1: Escribir los tests**

```php
test('user can change password and other tokens are revoked', function () {
    $user = User::factory()->create(['password' => bcrypt('old-password')]);
    $current = $user->createToken('current')->plainTextToken;
    $other = $user->createToken('other');
    $otherId = $other->accessToken->id;

    $this->withHeader('Authorization', "Bearer $current")
        ->patchJson('/api/v1/profile/password', [
            'current_password' => 'old-password',
            'password' => 'new-password',
            'password_confirmation' => 'new-password',
        ])->assertOk();

    expect(Hash::check('new-password', $user->fresh()->password))->toBeTrue();
    $this->assertDatabaseMissing('personal_access_tokens', ['id' => $otherId]);
    $this->withHeader('Authorization', "Bearer $current")
        ->getJson('/api/v1/auth/me')->assertOk();
});

test('password change rejects a wrong current password', function () {
    $user = User::factory()->create(['password' => bcrypt('old-password')]);
    Sanctum::actingAs($user);

    $this->patchJson('/api/v1/profile/password', [
        'current_password' => 'wrong',
        'password' => 'new-password',
        'password_confirmation' => 'new-password',
    ])->assertStatus(422)->assertJsonValidationErrors('current_password');
});

test('password change validates length and confirmation', function () {
    $user = User::factory()->create(['password' => bcrypt('old-password')]);
    Sanctum::actingAs($user);

    $this->patchJson('/api/v1/profile/password', [
        'current_password' => 'old-password',
        'password' => 'short',
        'password_confirmation' => 'different',
    ])->assertStatus(422)->assertJsonValidationErrors('password');
});

test('unauthenticated user cannot change password', function () {
    $this->patchJson('/api/v1/profile/password', [])->assertStatus(401);
});
```

Añadir `use Illuminate\Support\Facades\Hash;`.

- [ ] **Step 2: Implementar request, ruta y controlador**

`ProfilePasswordUpdateRequest`:

```php
public function rules(): array
{
    return [
        'current_password' => ['required', 'string'],
        'password' => ['required', 'string', 'min:8', 'confirmed'],
    ];
}
```

`ProfileController@updatePassword`:

```php
public function updatePassword(ProfilePasswordUpdateRequest $request): JsonResponse
{
    $user = $request->user();
    $validated = $request->validated();

    if (! Hash::check($validated['current_password'], $user->password)) {
        throw ValidationException::withMessages([
            'current_password' => [trans('auth.password')],
        ]);
    }

    $user->update(['password' => Hash::make($validated['password'])]);

    $current = $user->currentAccessToken();
    if ($current && ! $current instanceof \Laravel\Sanctum\TransientToken && $current->exists) {
        $user->tokens()->where('id', '!=', $current->id)->delete();
    }

    return $this->apiSuccess(['message' => 'Password updated successfully.']);
}
```

Importar `Illuminate\Validation\ValidationException`.

Ruta en `routes/api.php`, debajo de `profile/avatar`:

```php
Route::patch('profile/password', [ProfileController::class, 'updatePassword']);
```

- [ ] **Step 3: Verificar sintaxis**

Usar `docker run --rm --entrypoint php -v <worktree>:/app megalomaniac-prod -l <archivo>` para los tres archivos.

- [ ] **Step 4: Commit**

```bash
git -C /opt/dev/efe-app/.worktrees/editar-perfil add app/Http/Requests/ProfilePasswordUpdateRequest.php app/Http/Controllers/Api/Profile/ProfileController.php routes/api.php tests/Feature/Api/ProfileTest.php
git -C /opt/dev/efe-app/.worktrees/editar-perfil commit -m "feat: add profile password update endpoint"
```

---

## Task 4: Cubrir la subida de avatar del perfil

**Files:**
- Test: `/opt/dev/efe-app/.worktrees/editar-perfil/tests/Feature/Api/ProfileTest.php`
- Modify if needed: `/opt/dev/efe-app/.worktrees/editar-perfil/app/Http/Controllers/Api/Profile/ProfileController.php`

**Interfaces:**
- Consumes: `POST /profile/avatar` existente.
- Produces: garantía testeada de reemplazo de media, validación y 401.

- [ ] **Step 1: Escribir los tests**

```php
test('user can upload and replace the profile avatar', function () {
    Storage::fake('public');
    $user = createAdminForProfile();
    Sanctum::actingAs($user);

    $first = $this->postJson('/api/v1/profile/avatar', [
        'avatar' => UploadedFile::fake()->image('one.png', 100, 100),
    ])->assertOk();

    expect($first->json('data.avatar'))->toBeString();
    expect($user->asStringKeyed()->getMedia('avatar'))->toHaveCount(1);

    $this->postJson('/api/v1/profile/avatar', [
        'avatar' => UploadedFile::fake()->image('two.jpg', 100, 100),
    ])->assertOk();

    expect($user->asStringKeyed()->getMedia('avatar'))->toHaveCount(1);
});

test('avatar upload validates type and size', function () {
    Storage::fake('public');
    $user = createAdminForProfile();
    Sanctum::actingAs($user);

    $this->postJson('/api/v1/profile/avatar', [
        'avatar' => UploadedFile::fake()->create('doc.pdf', 10, 'application/pdf'),
    ])->assertStatus(422)->assertJsonValidationErrors('avatar');

    $this->postJson('/api/v1/profile/avatar', [
        'avatar' => UploadedFile::fake()->create('huge.jpg', 3000, 'image/jpeg'),
    ])->assertStatus(422)->assertJsonValidationErrors('avatar');
});

test('unauthenticated user cannot upload an avatar', function () {
    $this->postJson('/api/v1/profile/avatar', [])->assertStatus(401);
});
```

- [ ] **Step 2: Revisar el endpoint existente**

Si el test de reemplazo no puede pasar por lógica del controlador, corregir `uploadAvatar` para borrar la media anterior y volver a crear una sola.

- [ ] **Step 3: Verificar sintaxis**

`php -l` sobre el controlador y el test.

- [ ] **Step 4: Commit**

```bash
git -C /opt/dev/efe-app/.worktrees/editar-perfil add tests/Feature/Api/ProfileTest.php app/Http/Controllers/Api/Profile/ProfileController.php
git -C /opt/dev/efe-app/.worktrees/editar-perfil commit -m "test: cover profile avatar upload and replacement"
```

---

## Task 5: `UserModel` acepta `avatar` y `avatar_url`

**Files:**
- Modify: `lib/features/auth/domain/user_model.dart`
- Test: `test/profile/user_model_avatar_test.dart`

**Interfaces:**
- Produces: `UserModel.avatarUrl` se llena desde `avatar_url` o desde `avatar`.

- [ ] **Step 1: Escribir el test que falla**

```dart
test('parses avatar_url and falls back to avatar', () {
  final withUrl = UserModel.fromJson({
    'data': {'id': 1, 'name': 'Ada', 'email': 'ada@example.com', 'avatar_url': 'https://cdn/a.png'},
  });
  expect(withUrl.avatarUrl, 'https://cdn/a.png');

  final withAvatar = UserModel.fromJson({
    'data': {'id': 1, 'name': 'Ada', 'email': 'ada@example.com', 'avatar': 'https://cdn/b.png'},
  });
  expect(withAvatar.avatarUrl, 'https://cdn/b.png');

  final both = UserModel.fromJson({
    'data': {'id': 1, 'name': 'Ada', 'email': 'ada@example.com', 'avatar_url': 'https://cdn/a.png', 'avatar': 'https://cdn/b.png'},
  });
  expect(both.avatarUrl, 'https://cdn/a.png');

  final none = UserModel.fromJson({
    'data': {'id': 1, 'name': 'Ada', 'email': 'ada@example.com'},
  });
  expect(none.avatarUrl, isNull);
});
```

- [ ] **Step 2: Correr y ver fallar**

```bash
flutter test test/profile/user_model_avatar_test.dart
```

Expected: FAIL en `withAvatar`.

- [ ] **Step 3: Implementar**

```dart
avatarUrl: (attrs['avatar_url'] ?? attrs['avatar'])?.toString(),
```

- [ ] **Step 4: Correr y ver pasar**

```bash
flutter test test/profile/user_model_avatar_test.dart
```

- [ ] **Step 5: Commit**

```bash
git add lib/features/auth/domain/user_model.dart test/profile/user_model_avatar_test.dart
git commit -m "feat: parse avatar key in user model"
```

---

## Task 6: `ErrorInterceptor` entiende los 422 de Laravel

**Files:**
- Modify: `lib/core/api/interceptors/error_interceptor.dart`
- Test: `test/core/error_interceptor_test.dart`

**Interfaces:**
- Produces: `ValidationException.fieldErrors` con claves de Laravel (`email`, `current_password`, etc.) y `detail` con el primer mensaje.

- [ ] **Step 1: Escribir el test que falla**

Usar un adapter falso de Dio:

```dart
class _JsonAdapter implements HttpClientAdapter {
  _JsonAdapter(this.status, this.body);
  final int status;
  final Map<String, dynamic> body;

  @override
  Future<ResponseBody> fetch(RequestOptions options, Stream<Uint8List>? requestStream, Future<void>? cancelFuture) async =>
      ResponseBody.fromString(jsonEncode(body), status, headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      });

  @override
  void close({bool force = false}) {}
}

test('maps Laravel validation errors to field errors', () async {
  final dio = Dio(BaseOptions(baseUrl: 'http://test'));
  dio.httpClientAdapter = _JsonAdapter(422, {
    'message': 'The given data was invalid.',
    'errors': {
      'email': ['The email has already been taken.'],
      'password': ['The password field is required.'],
    },
  });
  dio.interceptors.add(ErrorInterceptor());

  try {
    await dio.patch('/profile', data: {});
    fail('should throw');
  } on DioException catch (e) {
    final error = e.error;
    expect(error, isA<ValidationException>());
    final validation = error as ValidationException;
    expect(validation.fieldErrors['email'], 'The email has already been taken.');
    expect(validation.detail, 'The email has already been taken.');
  }
});
```

- [ ] **Step 2: Correr y ver fallar**

```bash
flutter test test/core/error_interceptor_test.dart
```

Expected: FAIL porque `fieldErrors` está vacío y `detail` es el mensaje genérico.

- [ ] **Step 3: Implementar**

En `_parseFieldErrors`, antes del caso `List`:

```dart
if (errors is Map) {
  for (final entry in errors.entries) {
    final messages = entry.value;
    if (messages is List && messages.isNotEmpty) {
      fieldErrors[entry.key.toString()] = messages.first.toString();
    }
  }
  return fieldErrors;
}
```

En `_extractErrorDetail`, antes de devolver `data['message']`:

```dart
if (errors is Map && errors.isNotEmpty) {
  final first = errors.values.first;
  if (first is List && first.isNotEmpty) return first.first.toString();
}
```

- [ ] **Step 4: Correr y ver pasar**

```bash
flutter test test/core/error_interceptor_test.dart
```

- [ ] **Step 5: Commit**

```bash
git add lib/core/api/interceptors/error_interceptor.dart test/core/error_interceptor_test.dart
git commit -m "feat: parse laravel validation errors"
```

---

## Task 7: Capa de datos de perfil

**Files:**
- Create: `lib/features/profile/domain/avatar_upload_file.dart`
- Create: `lib/features/profile/data/profile_api.dart`
- Create: `lib/features/profile/data/profile_repository.dart`
- Create: `lib/features/profile/providers/profile_provider.dart`
- Test: `test/profile/profile_repository_test.dart`

**Interfaces:**
- Produces: `AvatarUploadFile({required Uint8List bytes, required String name})`.
- Produces: `ProfileRepository.getProfile() → Future<UserModel>`, `updateProfile({name,email}) → Future<UserModel>`, `uploadAvatar({bytes,filename}) → Future<String>`, `changePassword({currentPassword,password,passwordConfirmation}) → Future<void>`.
- Produces: `profileApiProvider`, `profileRepositoryProvider`.

- [ ] **Step 1: Escribir los tests que fallan**

`_FakeProfileApi implements ProfileApi` con respuestas configurables y captura de `FormData`. Tests:
- `getProfile` parsea `{data:{...avatar...}}`.
- `updateProfile` envía `name` y `email` por `PATCH /profile`.
- `uploadAvatar` envía `FormData` con el archivo en el campo `avatar` y devuelve la URL.
- `changePassword` envía los tres campos por `PATCH /profile/password`.
- Un `DioException` con `ValidationException` se preserva como `ValidationException`.

Ejemplo del test de upload:

```dart
test('uploadAvatar posts the file in the avatar field', () async {
  final api = _FakeProfileApi()
    ..avatarResponse = Response(
      requestOptions: RequestOptions(path: '/profile/avatar'),
      data: {'data': {'avatar': 'https://cdn/new.png'}},
    );
  final repo = ProfileRepository(api);

  final url = await repo.uploadAvatar(
    bytes: Uint8List.fromList([1, 2, 3]),
    filename: 'photo.png',
  );

  expect(url, 'https://cdn/new.png');
  final form = api.lastUpload!;
  expect(form.files.single.key, 'avatar');
  expect(form.files.single.value.filename, 'photo.png');
});
```

- [ ] **Step 2: Correr y ver fallar**

```bash
flutter test test/profile/profile_repository_test.dart
```

- [ ] **Step 3: Implementar**

`ProfileApi`:

```dart
Future<Response> show() => _client.get('/profile');
Future<Response> update({required String name, required String email}) =>
    _client.patch('/profile', data: {'name': name, 'email': email});
Future<Response> uploadAvatar(FormData data) => _client.upload(
      '/profile/avatar',
      data,
      options: Options(
        sendTimeout: const Duration(minutes: 2),
        receiveTimeout: const Duration(minutes: 2),
      ),
    );
Future<Response> changePassword({
  required String currentPassword,
  required String password,
  required String passwordConfirmation,
}) =>
    _client.patch('/profile/password', data: {
      'current_password': currentPassword,
      'password': password,
      'password_confirmation': passwordConfirmation,
    });
```

`ProfileRepository.uploadAvatar`:

```dart
final form = FormData.fromMap({
  'avatar': MultipartFile.fromBytes(bytes, filename: filename),
});
final response = await _api.uploadAvatar(form);
final url = response.data['data']?['avatar']?.toString() ?? '';
if (url.isEmpty) throw ApiException(message: 'Avatar no disponible');
return url;
```

Mapear `DioException` igual que los otros repositorios, preservando `ValidationException`.

Providers:

```dart
final profileApiProvider = Provider<ProfileApi>((ref) => ProfileApi(ref.watch(apiClientProvider)));
final profileRepositoryProvider = Provider<ProfileRepository>(
  (ref) => ProfileRepository(ref.watch(profileApiProvider)),
);
```

- [ ] **Step 4: Correr y ver pasar**

```bash
flutter test test/profile/profile_repository_test.dart
```

- [ ] **Step 5: Commit**

```bash
git add lib/features/profile/domain/avatar_upload_file.dart lib/features/profile/data/profile_api.dart lib/features/profile/data/profile_repository.dart lib/features/profile/providers/profile_provider.dart test/profile/profile_repository_test.dart
git commit -m "feat: add profile data layer"
```

---

## Task 8: `AuthNotifier.applyUser` y `ProfileEditNotifier`

**Files:**
- Modify: `lib/features/auth/providers/auth_provider.dart`
- Modify: `lib/features/profile/providers/profile_provider.dart`
- Test: `test/profile/profile_edit_notifier_test.dart`

**Interfaces:**
- Consumes: `ProfileRepository` de Task 7.
- Produces: `AuthNotifier.applyUser(UserModel user) → void`.
- Produces: `ProfileEditState({savingProfile, uploadingAvatar, savingPassword, fieldErrors})`.
- Produces: `ProfileEditNotifier.saveProfile({name,email}) → Future<bool>`, `uploadAvatar({bytes,filename}) → Future<String?>`, `changePassword({currentPassword,newPassword,confirmation}) → Future<bool>`, `clearFieldErrors() → void`.
- Produces: `profileEditProvider` (`StateNotifierProvider.autoDispose`).

- [ ] **Step 1: Escribir los tests que fallan**

Usar el patrón existente de `_NeverAuthRepository` para sembrar un usuario sin disparar red:

```dart
test('saveProfile updates the auth user and keeps the avatar', () async {
  final auth = _TestAuthNotifier()..seed(const UserModel(
    id: '1', name: 'Old', email: 'old@example.com', avatarUrl: 'https://cdn/a.png',
  ));
  final repo = _FakeProfileRepository()
    ..updateResult = const UserModel(
      id: '1', name: 'New', email: 'new@example.com', role: 'admin',
    );
  final container = ProviderContainer(overrides: [
    authProvider.overrideWith((ref) => auth),
    profileRepositoryProvider.overrideWithValue(repo),
  ]);
  addTearDown(container.dispose);

  final ok = await container.read(profileEditProvider.notifier)
      .saveProfile(name: 'New', email: 'new@example.com');

  expect(ok, isTrue);
  expect(container.read(authProvider).user?.name, 'New');
  expect(container.read(authProvider).user?.avatarUrl, 'https://cdn/a.png');
});
```

Añadir tests equivalentes para:
- `uploadAvatar` actualiza `avatarUrl`.
- `changePassword` devuelve `true` y no cambia el usuario.
- `ValidationException` llena `fieldErrors`.
- Un error genérico devuelve `false` sin cambiar el usuario.

- [ ] **Step 2: Correr y ver fallar**

```bash
flutter test test/profile/profile_edit_notifier_test.dart
```

- [ ] **Step 3: Implementar**

En `AuthNotifier`:

```dart
void applyUser(UserModel user) {
  state = state.copyWith(status: AuthStatus.authenticated, user: user);
}
```

En `profile_provider.dart`:

```dart
class ProfileEditState {
  final bool savingProfile;
  final bool uploadingAvatar;
  final bool savingPassword;
  final Map<String, String> fieldErrors;

  const ProfileEditState({
    this.savingProfile = false,
    this.uploadingAvatar = false,
    this.savingPassword = false,
    this.fieldErrors = const {},
  });

  ProfileEditState copyWith({...});
}
```

`ProfileEditNotifier` recibe `Ref` y `ProfileRepository`. En cada operación:
1. limpiar `fieldErrors` y prender el flag;
2. llamar al repositorio;
3. en éxito, aplicar el usuario cuando corresponda y devolver `true`/URL;
4. en `ValidationException`, guardar `fieldErrors` y devolver `false`/`null`;
5. en cualquier otro error, devolver `false`/`null`;
6. apagar el flag.

Para `saveProfile`, fusionar el avatar y branch actuales:

```dart
final current = _ref.read(authProvider).user;
final merged = updated.copyWith(
  avatarUrl: current?.avatarUrl,
  branchName: current?.branchName,
);
_ref.read(authProvider.notifier).applyUser(merged);
```

Provider:

```dart
final profileEditProvider =
    StateNotifierProvider.autoDispose<ProfileEditNotifier, ProfileEditState>(
  (ref) => ProfileEditNotifier(ref, ref.watch(profileRepositoryProvider)),
);
```

- [ ] **Step 4: Correr y ver pasar**

```bash
flutter test test/profile/profile_edit_notifier_test.dart
```

- [ ] **Step 5: Commit**

```bash
git add lib/features/auth/providers/auth_provider.dart lib/features/profile/providers/profile_provider.dart test/profile/profile_edit_notifier_test.dart
git commit -m "feat: add profile edit notifier"
```

---

## Task 9: Textos ES/EN

**Files:**
- Modify: `lib/l10n/app_es.arb`
- Modify: `lib/l10n/app_en.arb`
- Regenerated: `lib/l10n/app_localizations*.dart`

**Interfaces:**
- Produces: claves usadas por las Tasks 10-12.

- [ ] **Step 1: Agregar las claves**

ES:

```json
"profileEditProfileTitle": "Editar perfil",
"profileEditPhotoSection": "Foto de perfil",
"profileEditChangePhoto": "Cambiar foto",
"profileEditPhotoHint": "JPG, PNG o GIF · máx. 2 MB",
"profileEditPhotoInvalid": "Elegí una imagen JPG, PNG o GIF de hasta 2 MB.",
"profileEditPhotoUploaded": "Foto actualizada.",
"profileEditPhotoError": "No se pudo subir la foto.",
"profileEditDataSection": "Datos personales",
"profileEditNameLabel": "Nombre",
"profileEditEmailLabel": "Email",
"profileEditSave": "Guardar cambios",
"profileEditSaved": "Perfil actualizado.",
"profileEditSaveError": "No se pudo actualizar el perfil.",
"profileEditEmailInUse": "Ese email ya está en uso.",
"profileEditPasswordSection": "Contraseña",
"profileEditCurrentPassword": "Contraseña actual",
"profileEditNewPassword": "Nueva contraseña",
"profileEditConfirmPassword": "Confirmar contraseña",
"profileEditPasswordSave": "Cambiar contraseña",
"profileEditPasswordSaved": "Contraseña actualizada.",
"profileEditPasswordError": "No se pudo cambiar la contraseña.",
"profileEditCurrentPasswordIncorrect": "La contraseña actual no es correcta.",
"profileEditPasswordInvalid": "La contraseña no es válida.",
"profileEditShowPassword": "Mostrar contraseña",
"profileEditHidePassword": "Ocultar contraseña"
```

EN: traducciones equivalentes (`Edit profile`, `Profile photo`, `Change photo`, `JPG, PNG or GIF · max 2 MB`, etc.).

- [ ] **Step 2: Regenerar**

```bash
flutter gen-l10n
```

- [ ] **Step 3: Verificar**

```bash
flutter analyze
```

Expected: sin errores nuevos.

- [ ] **Step 4: Commit**

```bash
git add lib/l10n/app_es.arb lib/l10n/app_en.arb lib/l10n/app_localizations.dart lib/l10n/app_localizations_es.dart lib/l10n/app_localizations_en.dart
git commit -m "feat: add edit profile translations"
```

---

## Task 10: Ruta y formulario de datos

**Files:**
- Create: `lib/features/profile/screens/edit_profile_screen.dart`
- Modify: `lib/app/router.dart`
- Test: `test/profile/edit_profile_data_test.dart`

**Interfaces:**
- Consumes: `profileEditProvider`, `AuthNotifier.applyUser`.
- Produces: `EditProfileScreen({super.key, Future<AvatarUploadFile?> Function()? pickAvatar})`.
- Produces: ruta `/profile/edit`.

- [ ] **Step 1: Escribir los tests que fallan**

Tests:
- Renderiza el nombre y email actuales.
- Guardar con nombre vacío muestra `validationRequired`.
- Email inválido muestra `validationInvalidEmail`.
- Guardar válido llama a `saveProfile` con los valores y muestra `profileEditSaved`.
- Un 422 de email muestra `profileEditEmailInUse` y conserva el texto.

Para inyectar dependencias, override `authProvider` con un `_TestAuthNotifier` sembrado y `profileRepositoryProvider` con un fake.

- [ ] **Step 2: Correr y ver fallar**

```bash
flutter test test/profile/edit_profile_data_test.dart
```

- [ ] **Step 3: Implementar la pantalla**

Estructura:

```dart
class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key, this.pickAvatar});
  final Future<AvatarUploadFile?> Function()? pickAvatar;
  ...
}
```

- `Scaffold` con `AppColors.backgroundFor(isDark)`.
- `LargeTitleBar(title: l10n.profileEditProfileTitle, showBackButton: true)`.
- `ListView` con `AppCard` para datos.
- `TextFormField` de nombre y email, inicializados desde `authProvider.user`.
- Botón `PillButton` o `FilledButton` con spinner mientras `savingProfile`.
- Al guardar: validar; `await notifier.saveProfile(...)`; si `true`, snackbar `profileEditSaved`; si `false`, si `fieldErrors['email']` mostrar `profileEditEmailInUse`, si no `profileEditSaveError`.
- Un bloque superior `Center(child: AppAvatar(imageUrl: user?.avatarUrl, name: user?.name ?? '', size: 96, showGradientRing: true))` como placeholder; Task 11 lo reemplaza por el editor.

Ruta en `router.dart`, dentro de la rama de perfil:

```dart
GoRoute(
  path: 'edit',
  builder: (context, state) => const EditProfileScreen(),
),
```

- [ ] **Step 4: Correr y ver pasar**

```bash
flutter test test/profile/edit_profile_data_test.dart
```

- [ ] **Step 5: Commit**

```bash
git add lib/features/profile/screens/edit_profile_screen.dart lib/app/router.dart test/profile/edit_profile_data_test.dart
git commit -m "feat: add edit profile route and data form"
```

---

## Task 11: Editor de foto de perfil

**Files:**
- Modify: `lib/features/profile/screens/edit_profile_screen.dart`
- Test: `test/profile/edit_profile_avatar_test.dart`

**Interfaces:**
- Consumes: `pickAvatar` inyectable y `ProfileEditNotifier.uploadAvatar`.
- Produces: bloque de avatar tocable, preview local y subida inmediata.

- [ ] **Step 1: Escribir los tests que fallan**

Tests:
- Tocar el avatar abre el picker inyectado y, al devolver una imagen válida, llama a `uploadAvatar` y muestra `profileEditPhotoUploaded`.
- Extensión inválida (`.webp`) muestra `profileEditPhotoInvalid` y no sube.
- Archivo de 2 MB + 1 byte muestra `profileEditPhotoInvalid` y no sube.
- Error de repositorio muestra `profileEditPhotoError`, apaga el spinner y conserva el avatar anterior.
- Cancelar el picker no hace nada.

Para la imagen válida, usar un PNG 1x1 real en `Uint8List`.

- [ ] **Step 2: Correr y ver fallar**

```bash
flutter test test/profile/edit_profile_avatar_test.dart
```

- [ ] **Step 3: Implementar**

- `_defaultPickAvatar()` con `FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['jpg','jpeg','png','gif'], withData: true)`.
- Validar extensión y `bytes.length <= 2 * 1024 * 1024`.
- Estado local: `AvatarUploadFile? _preview`, `bool _uploading`, `String? _photoError`.
- Al elegir: guardar preview y llamar `notifier.uploadAvatar(bytes: ..., filename: ...)`.
- UI: `GestureDetector` sobre un `Stack`:
  - si `_preview != null`, `ClipOval(Image.memory(_preview!.bytes, width: 96, height: 96, fit: BoxFit.cover))`;
  - si no, `AppAvatar(...)`;
  - badge de cámara (`PhosphorIconsRegular.camera`) en la esquina;
  - overlay `CircularProgressIndicator` mientras sube.
- Al éxito: snackbar `profileEditPhotoUploaded`, limpiar preview.
- Al error: snackbar `profileEditPhotoError`, conservar la URL anterior.
- Añadir `Semantics(label: l10n.profileEditChangePhoto, button: true)`.

- [ ] **Step 4: Correr y ver pasar**

```bash
flutter test test/profile/edit_profile_avatar_test.dart
```

- [ ] **Step 5: Commit**

```bash
git add lib/features/profile/screens/edit_profile_screen.dart test/profile/edit_profile_avatar_test.dart
git commit -m "feat: add avatar editor to profile"
```

---

## Task 12: Formulario de contraseña

**Files:**
- Modify: `lib/features/profile/screens/edit_profile_screen.dart`
- Test: `test/profile/edit_profile_password_test.dart`

**Interfaces:**
- Consumes: `ProfileEditNotifier.changePassword`.
- Produces: bloque de contraseña con validación local, obscuros y errores del servidor.

- [ ] **Step 1: Escribir los tests que fallan**

Tests:
- Contraseña nueva corta muestra `validationPasswordLength`.
- Confirmación distinta muestra `validationPasswordsDoNotMatch`.
- Guardado válido llama a `changePassword`, limpia los campos y muestra `profileEditPasswordSaved`.
- `fieldErrors['current_password']` muestra `profileEditCurrentPasswordIncorrect`.
- Error genérico muestra `profileEditPasswordError`.

- [ ] **Step 2: Correr y ver fallar**

```bash
flutter test test/profile/edit_profile_password_test.dart
```

- [ ] **Step 3: Implementar**

- Tres `TextFormField`: actual, nueva, confirmar.
- `obscureText` con toggles (`PhosphorIconsRegular.eye` / `eyeSlash`).
- Validadores: `AppValidators.required` para la actual, `AppValidators.password` para la nueva, `AppValidators.confirmPassword` para la confirmación.
- `AppCard` con título `profileEditPasswordSection`.
- Botón con spinner mientras `savingPassword`.
- Al guardar: validar; llamar `notifier.changePassword(...)`.
- Si `true`: limpiar controllers y snackbar `profileEditPasswordSaved`.
- Si `false`: si `fieldErrors['current_password']` existe, mostrar `profileEditCurrentPasswordIncorrect`; si no, `profileEditPasswordError`. También si `fieldErrors['password']` existe, mostrar `profileEditPasswordInvalid`.

- [ ] **Step 4: Correr y ver pasar**

```bash
flutter test test/profile/edit_profile_password_test.dart
```

- [ ] **Step 5: Commit**

```bash
git add lib/features/profile/screens/edit_profile_screen.dart test/profile/edit_profile_password_test.dart
git commit -m "feat: add password form to profile editor"
```

---

## Task 13: Navegación desde el perfil y verificación final

**Files:**
- Modify: `lib/features/profile/screens/profile_screen.dart`
- Test: `test/profile/profile_edit_navigation_test.dart`

**Interfaces:**
- Consumes: ruta `/profile/edit` de Task 10.
- Produces: tile "Editar perfil" navega a la pantalla nueva.

- [ ] **Step 1: Escribir el test que falla**

Montar un `GoRouter` con `/profile` y `/profile/edit` (la segunda con un `Scaffold` con el texto `edit-target`) y verificar que tocar `Editar perfil` muestra `edit-target`.

- [ ] **Step 2: Correr y ver fallar**

```bash
flutter test test/profile/profile_edit_navigation_test.dart
```

- [ ] **Step 3: Implementar la navegación**

En `profile_screen.dart`, cambiar `onTap: () {}` por:

```dart
onTap: () => context.push('/profile/edit'),
```

- [ ] **Step 4: Verificación completa**

```bash
dart format --output=none --set-exit-if-changed .
flutter analyze
flutter test
```

Expected: formato sin cambios, analyze sin errores nuevos, tests sin fallos nuevos (los 2 preexistentes siguen).

- [ ] **Step 5: Commit**

```bash
git add lib/features/profile/screens/profile_screen.dart test/profile/profile_edit_navigation_test.dart
git commit -m "feat: open profile editor from profile screen"
```

---

## Autorevisión del plan

- **Cobertura del diseño:** nombre/email (Tasks 2, 5, 7, 8, 10), foto (Tasks 1, 4, 7, 8, 11), contraseña (Tasks 3, 7, 8, 12), avatar visible (Tasks 1, 5), 422 (Tasks 6, 10, 12), navegación (Task 13), l10n (Task 9), tests y verificación (Task 13).
- **Consistencia de tipos:** `AvatarUploadFile.bytes` es `Uint8List` en todas las capas; `uploadAvatar` devuelve `Future<String>` en repositorio y `Future<String?>` en el notifier; `applyUser` recibe `UserModel`.
- **Riesgo principal:** el update de filas de rol. El plan usa `user_id` explícito para `student_data`, nunca `$user->studentData()`.
