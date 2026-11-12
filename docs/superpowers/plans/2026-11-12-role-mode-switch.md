# Selector de modo por rol — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Permitir que un usuario con varios roles reales elija con qué rol usar la app móvil, y que todas las pantallas y listados respeten ese modo activo.

**Architecture:** El modo activo vive en el token de Sanctum (`personal_access_tokens.active_role`). `User::activeRole()` resuelve token → sesión web → rol primario. La API expone `roles` reales en `/auth/me` y el endpoint `switch-role` cambia el modo. La app guarda el rol efectivo en `AuthState`, muestra un selector en el home y en Perfil, y refresca los providers dependientes del rol.

**Tech Stack:** Laravel 11 + Sanctum + PostgreSQL (backend), Flutter 3.44 + Riverpod + GoRouter + Dio (app), Pest para tests backend, Flutter Test para la app.

**Spec:** `docs/superpowers/specs/2026-11-12-role-mode-switch-design.md`

## Global Constraints

- Backend worktree: `/opt/dev/efe-app/.worktrees/feat-role-mode-switch` (branch `feat-role-mode-switch`).
- App worktree: `/home/defaultuser/.local/share/opencode/worktree/2e09a3/feat-role-mode-switch` (branch `feat-role-mode-switch`).
- **No ejecutar la suite Pest contra la base de desarrollo.** `efe-app/AGENTS.md` prohíbe `php artisan test`/Pest sobre la DB de dev porque usa `RefreshDatabase`. Ejecutar solo en CI o con una `DB_DATABASE` descartable. Si no hay DB descartable, dejar el paso marcado como bloqueado y verificar por HTTP/tinker.
- Backend: `./vendor/bin/pint` debe pasar en cada tarea.
- App: `flutter analyze` y `flutter test` deben pasar antes de cerrar cada tarea. Si el entorno no tiene Flutter, ejecutar en CI o en el entorno del usuario; no cerrar la tarea sin esa verificación.
- No cambiar el modelo de permisos: las policies y los chequeos de autorización siguen usando `hasRole()` con roles reales. `activeRole()` es solo alcance de datos/UI.
- No incluir el rol fantasma `student` que aparece por `current_selected_id` en el selector.
- No crear homes nuevos para admin, branch o alumno; usan el dashboard genérico existente.
- No cambiar el comportamiento de la web.
- Strings nuevos en `lib/l10n/app_es.arb` y `app_en.arb`; regenerar con `flutter gen-l10n` y no editar a mano `app_localizations*.dart`.

## Review Focus

These are the five failure modes most likely to bite a user; each has a test in the task that owns the code.

1. **Profe-padre en modo padre recibe 403 en el aula/material de su hijo** — `ClassroomsPolicy::view` y `MaterialPolicy::view` cortan en la rama profesor. Test in Task 5.
2. **El modo se pierde al refrescar el token o al reiniciar la app** — `/auth/refresh` debe copiar `active_role` y `/auth/me` debe devolver el rol activo. Test in Task 2.
3. **Un padre con hijo seleccionado ve “Modo Alumno” fantasma** — `getSwitchableRoles()` debe excluirlo y el endpoint debe rechazarlo. Test in Tasks 1 and 2.
4. **El switch recrea el router y destruye la hoja/push** — `routerProvider` debe observar solo `AuthStatus`; el tab central debe resolverse por rol activo. Test in Task 7.
5. **Datos del modo anterior quedan en providers persistentes** — invalidar relaciones, aulas, cuotas, chat, etc. después de actualizar el rol. Test in Task 9.

---

### Task 1: Backend — token-scoped active role foundation

**Files:**
- Create: `database/migrations/2026_11_12_000000_add_active_role_to_personal_access_tokens_table.php`
- Create: `app/Models/PersonalAccessToken.php`
- Modify: `app/Providers/AppServiceProvider.php` (boot method)
- Modify: `app/Models/User.php` (`activeRole`, add `getSwitchableRoles`, `realStudentData`)
- Test: `tests/Feature/Api/RoleModeFoundationTest.php`

**Interfaces:**
- Consumes: nothing.
- Produces:
  - `App\Models\PersonalAccessToken` with `active_role` fillable.
  - `User::activeRole(): string`
  - `User::getSwitchableRoles(): array`
  - `User::realStudentData(): ?\App\Models\StudentData`

- [ ] **Step 1: Write the failing foundation tests**

Create `tests/Feature/Api/RoleModeFoundationTest.php`:

```php
<?php

use App\Models\StudentData;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;

uses(RefreshDatabase::class);

function createProfessorParentUserForRoleMode(): User
{
    $user = User::factory()->create();
    $user->studentData()->delete();
    $user->userData()->delete();
    $user->professorData()->create([
        'fullname' => 'Profe Multi Rol',
        'email' => $user->email,
    ]);
    $parent = $user->parentData()->create([
        'fullname' => 'Padre Multi Rol',
        'email' => $user->email,
    ]);
    $parent->students()->attach(StudentData::factory()->create());

    return $user;
}

test('active role comes from the current token', function () {
    $user = createProfessorParentUserForRoleMode();
    $newToken = $user->createToken('test');
    $newToken->accessToken->forceFill(['active_role' => 'parent'])->save();

    $user->withAccessToken($newToken->accessToken->fresh());

    expect($user->activeRole())->toBe('parent');
});

test('switchable roles exclude the ghost student role', function () {
    $user = createProfessorParentUserForRoleMode();
    $child = $user->parentData->students->first();
    $user->update(['current_selected_id' => $child->id]);

    expect($user->getSwitchableRoles())->toBe(['professor', 'parent']);
});

test('switchable roles include a real student record', function () {
    $user = User::factory()->create();
    $user->studentData()->delete();
    $user->professorData()->delete();
    $user->userData()->delete();
    $user->parentData()->create([
        'fullname' => 'Padre Alumno',
        'email' => $user->email,
    ]);
    StudentData::factory()->create(['user_id' => $user->id]);

    expect($user->getSwitchableRoles())->toContain('parent', 'student')
        ->and($user->getSwitchableRoles())->not->toContain('user');
});
```

- [ ] **Step 2: Run the tests to verify they fail**

Run (only with a disposable DB, or in CI):
`DB_DATABASE=efe_role_mode_test ./vendor/bin/pest tests/Feature/Api/RoleModeFoundationTest.php`
Expected: FAIL — `getSwitchableRoles()`/`activeRole()` do not exist or return the primary role.

- [ ] **Step 3: Implement the migration and custom token model**

Migration: add a nullable `active_role` string to `personal_access_tokens` after `abilities`, with a `down()` that drops it.

`app/Models/PersonalAccessToken.php`:

```php
<?php

namespace App\Models;

use Laravel\Sanctum\PersonalAccessToken as SanctumPersonalAccessToken;

class PersonalAccessToken extends SanctumPersonalAccessToken
{
    protected $fillable = [
        'name',
        'token',
        'abilities',
        'expires_at',
        'active_role',
    ];
}
```

In `AppServiceProvider::boot()` register `Sanctum::usePersonalAccessTokenModel(PersonalAccessToken::class);`.

- [ ] **Step 4: Implement `User::activeRole()`, `getSwitchableRoles()` and `realStudentData()`**

`activeRole()` resolution order:
1. `$token = $this->currentAccessToken();` — only if `$token` is not `Laravel\Sanctum\TransientToken`, `$token->exists` is true, and `$token->getAttribute('active_role')` is in `getSwitchableRoles()`.
2. `request()->hasSession()` and `request()->session()->get('active_role')` is in `getRoles()` (web keeps its session behavior).
3. `$this->role()`.

`getSwitchableRoles()` returns known real roles only:
- `professor` if `professorData()->withoutGlobalScopes()->exists()`
- `parent` if `parentData()->withoutGlobalScopes()->exists()`
- `admin`/`branch` if `userData()->withoutGlobalScopes()->first()?->role` is one of those
- `student` if `realStudentData()` is not null
- `array_values(array_unique($roles))`, excluding `user`.

`realStudentData()` returns `StudentData::withoutGlobalScopes()->where('user_id', $this->id)->first()`.

Do **not** change `getRoles()`; it keeps the ghost student for permissions/web.

Optional optimization: if `getSwitchableRoles()` is called several times in one request, memoize it on the `User` instance and clear the cache after `refresh()`/`update()`. Correctness does not depend on it.

- [ ] **Step 5: Run the tests to verify they pass**

Run: `DB_DATABASE=efe_role_mode_test ./vendor/bin/pest tests/Feature/Api/RoleModeFoundationTest.php`
Expected: PASS.

- [ ] **Step 6: Format and commit**

```bash
cd /opt/dev/efe-app/.worktrees/feat-role-mode-switch
./vendor/bin/pint app/Models/User.php app/Models/PersonalAccessToken.php app/Providers/AppServiceProvider.php database/migrations/2026_11_12_000000_add_active_role_to_personal_access_tokens_table.php tests/Feature/Api/RoleModeFoundationTest.php
git add app/Models/User.php app/Models/PersonalAccessToken.php app/Providers/AppServiceProvider.php database/migrations/2026_11_12_000000_add_active_role_to_personal_access_tokens_table.php tests/Feature/Api/RoleModeFoundationTest.php
git commit -m "feat(api): add token-scoped active role foundation"
```

---

### Task 2: Backend — switch endpoint and auth responses

**Files:**
- Modify: `app/Http/Controllers/Api/UserData/UserDataController.php` (`switchRole`)
- Modify: `app/Http/Controllers/Api/Auth/MeController.php` (`show`, `refresh`)
- Modify: `app/Http/Controllers/Api/Auth/LoginController.php` (`login` response)
- Modify: `app/Http/Controllers/Api/Auth/RegisterController.php` (`register` response)
- Modify: `app/Http/Controllers/Api/Profile/ProfileController.php` (`show`, `update`)
- Test: `tests/Feature/Api/RoleSwitchApiTest.php`

**Interfaces:**
- Consumes: `User::activeRole()`, `User::getSwitchableRoles()`, `User::realStudentData()` from Task 1.
- Produces:
  - `POST /api/v1/user-data/switch-role` → `{ data: { role: string, roles: string[], selected_student_id: string|null } }`
  - `/api/v1/auth/me` → `{ data: { ..., role: string, roles: string[] } }` with `role` = active role.

- [ ] **Step 1: Write the failing API tests**

Create `tests/Feature/Api/RoleSwitchApiTest.php` with a helper that creates a professor+parent user, a child, and returns `[user, child]`. Then add these tests:

```php
test('switch role persists on the current token and me returns it', function () {
    [$user] = createMultiRoleUserForRoleSwitch();
    $token = $user->createToken('test')->plainTextToken;

    $this->withToken($token)
        ->postJson('/api/v1/user-data/switch-role', ['role' => 'parent'])
        ->assertOk()
        ->assertJsonPath('data.role', 'parent')
        ->assertJsonPath('data.roles', ['professor', 'parent']);

    expect($user->tokens()->first()->active_role)->toBe('parent');

    $this->withToken($token)
        ->getJson('/api/v1/auth/me')
        ->assertOk()
        ->assertJsonPath('data.role', 'parent')
        ->assertJsonPath('data.roles', ['professor', 'parent']);
});

test('switch role rejects the ghost student role', function () {
    [$user, $child] = createMultiRoleUserForRoleSwitch();
    $user->update(['current_selected_id' => $child->id]);
    $token = $user->createToken('test')->plainTextToken;

    $this->withToken($token)
        ->postJson('/api/v1/user-data/switch-role', ['role' => 'student'])
        ->assertStatus(422);
});

test('switching to professor does not clear the selected child', function () {
    [$user, $child] = createMultiRoleUserForRoleSwitch();
    $user->update(['current_selected_id' => $child->id]);
    $token = $user->createToken('test')->plainTextToken;

    $this->withToken($token)
        ->postJson('/api/v1/user-data/switch-role', ['role' => 'professor'])
        ->assertOk();

    expect($user->fresh()->current_selected_id)->toBe($child->id);
});

test('refresh preserves the active role', function () {
    [$user] = createMultiRoleUserForRoleSwitch();
    $token = $user->createToken('test')->plainTextToken;

    $this->withToken($token)
        ->postJson('/api/v1/user-data/switch-role', ['role' => 'parent'])
        ->assertOk();

    $response = $this->withToken($token)
        ->postJson('/api/v1/auth/refresh')
        ->assertOk();

    $newToken = $response->json('data.token');

    $this->withToken($newToken)
        ->getJson('/api/v1/auth/me')
        ->assertJsonPath('data.role', 'parent');
});
```

- [ ] **Step 2: Run the tests to verify they fail**

Run: `DB_DATABASE=efe_role_mode_test ./vendor/bin/pest tests/Feature/Api/RoleSwitchApiTest.php`
Expected: FAIL — the switch does not persist on the token and `/auth/me` still returns `role()`.

- [ ] **Step 3: Implement the switch endpoint**

In `UserDataController::switchRole`:
- Validate `role` with `required|string`.
- Resolve `$switchable = $user->getSwitchableRoles()`.
- If `! in_array($role, $switchable, true)`, return `apiError('Invalid role.', 422, ...)`.
- If `$request->hasSession()`, put `active_role` in the session.
- Resolve `$token = $request->user()->currentAccessToken()`. If it is not `TransientToken`, `forceFill(['active_role' => $role])->save()`.
- `current_selected_id`:
  - `student`: set to `$user->realStudentData()?->id`.
  - `parent`: keep the current value if it is one of `$user->parentData?->students`; otherwise set the first linked child id.
  - `professor`, `admin`, `branch`: do not change it.
- Return `['role' => $role, 'roles' => $user->fresh()->getSwitchableRoles(), 'selected_student_id' => $user->fresh()->current_selected_id]`.

- [ ] **Step 4: Update auth/profile responses and refresh**

- `MeController::show`: `'role' => $user->activeRole()`, `'roles' => $user->getSwitchableRoles()`.
- `MeController::refresh`: capture `$activeRole = $user->activeRole()` before deleting the old token; after `createToken`, set the new token's `active_role` to `$activeRole` and return the token.
- `LoginController::login`: `'role' => $user->role()`, `'roles' => $user->getSwitchableRoles()`.
- `RegisterController::register`: `'roles' => $user->getSwitchableRoles()`.
- `ProfileController::show` and `update`: `'role' => $user->activeRole()`, `'roles' => $user->getSwitchableRoles()` where applicable.

- [ ] **Step 5: Run the tests to verify they pass**

Run: `DB_DATABASE=efe_role_mode_test ./vendor/bin/pest tests/Feature/Api/RoleSwitchApiTest.php`
Expected: PASS.

- [ ] **Step 6: Format and commit**

```bash
cd /opt/dev/efe-app/.worktrees/feat-role-mode-switch
./vendor/bin/pint app/Http/Controllers/Api/UserData/UserDataController.php app/Http/Controllers/Api/Auth/MeController.php app/Http/Controllers/Api/Auth/LoginController.php app/Http/Controllers/Api/Auth/RegisterController.php app/Http/Controllers/Api/Profile/ProfileController.php tests/Feature/Api/RoleSwitchApiTest.php
git add app/Http/Controllers/Api/UserData/UserDataController.php app/Http/Controllers/Api/Auth/MeController.php app/Http/Controllers/Api/Auth/LoginController.php app/Http/Controllers/Api/Auth/RegisterController.php app/Http/Controllers/Api/Profile/ProfileController.php tests/Feature/Api/RoleSwitchApiTest.php
git commit -m "feat(api): switch active role per token and expose it in auth"
```

---

### Task 3: Backend — core data scoping (dashboard, classrooms, students, fees)

**Files:**
- Modify: `app/Http/Controllers/Api/Statistics/StatisticsController.php` (`dashboard`, `fees`)
- Modify: `app/Http/Controllers/Api/Classrooms/ClassroomController.php` (`scopeToRole`)
- Modify: `app/Http/Controllers/Api/Students/StudentController.php` (`applyRoleFilter`)
- Modify: `app/Http/Controllers/Api/Fees/FeeController.php` (`index` parent branch, `applyRoleFilter`)
- Test: `tests/Feature/Api/RoleScopingCoreTest.php`

**Interfaces:**
- Consumes: active role from the token.
- Produces: the same response shapes, scoped by `activeRole()` instead of `role()`/`hasRole()`.

- [ ] **Step 1: Write the failing scoping tests**

Create a scenario helper that returns a professor+parent user, a child linked to the parent, a child's classroom, a professor-only classroom, and a child fee. Write these assertions:

```php
test('parent mode scopes dashboard classrooms students and fees', function () {
    [$user, $child, $childClassroom, $professorClassroom, $fee] = createRoleScopingScenario();
    $token = $user->createToken('test')->plainTextToken;

    $this->withToken($token)
        ->postJson('/api/v1/user-data/switch-role', ['role' => 'parent'])
        ->assertOk();

    $this->withToken($token)
        ->getJson('/api/v1/statistics/dashboard')
        ->assertOk()
        ->assertJsonPath('data.role', 'parent');

    $classrooms = $this->withToken($token)->getJson('/api/v1/classrooms')->json('data');
    expect(collect($classrooms)->pluck('id'))->toContain($childClassroom->id)
        ->not->toContain($professorClassroom->id);

    $students = $this->withToken($token)->getJson('/api/v1/students')->json('data');
    expect(collect($students)->pluck('id'))->toContain($child->id);

    $fees = $this->withToken($token)->getJson('/api/v1/fees')->json('data');
    expect(collect($fees)->pluck('id'))->toContain($fee->id);
});

test('professor mode scopes classrooms to the professor', function () {
    [$user, , , $professorClassroom] = createRoleScopingScenario();
    $token = $user->createToken('test')->plainTextToken;

    $this->withToken($token)
        ->postJson('/api/v1/user-data/switch-role', ['role' => 'professor'])
        ->assertOk();

    $classrooms = $this->withToken($token)->getJson('/api/v1/classrooms')->json('data');
    expect(collect($classrooms)->pluck('id'))->toContain($professorClassroom->id);
});
```

- [ ] **Step 2: Run the tests to verify they fail**

Run: `DB_DATABASE=efe_role_mode_test ./vendor/bin/pest tests/Feature/Api/RoleScopingCoreTest.php`
Expected: FAIL — the professor branch wins and the parent mode returns professor data.

- [ ] **Step 3: Implement the core scoping changes**

- `StatisticsController::dashboard`: `$role = $user->activeRole();`
- `StatisticsController::fees`: `$role = $user->activeRole();`
- `ClassroomController::scopeToRole`: resolve `$active = $user->activeRole();` and branch on it:
  - admin/branch → full query
  - professor → assigned classrooms
  - parent → linked children's classrooms
  - student → own classrooms
  - default → no rows
- `StudentController::applyRoleFilter`: same active-role branching. Keep the parent branch before student so a parent's ghost student role does not narrow the result.
- `FeeController::index`: replace the `hasRole('parent') && ! hasRole(['admin','branch'])` condition with `$user->activeRole() === 'parent'`.
- `FeeController::applyRoleFilter`: branch on `activeRole()` with admin/branch → all, parent → linked children, student → own fees, default → no rows.

Do not change `FeeController::authorizeStudentFees` or policy authorization.

- [ ] **Step 4: Run the tests to verify they pass**

Run: `DB_DATABASE=efe_role_mode_test ./vendor/bin/pest tests/Feature/Api/RoleScopingCoreTest.php`
Expected: PASS.

- [ ] **Step 5: Format and commit**

```bash
cd /opt/dev/efe-app/.worktrees/feat-role-mode-switch
./vendor/bin/pint app/Http/Controllers/Api/Statistics/StatisticsController.php app/Http/Controllers/Api/Classrooms/ClassroomController.php app/Http/Controllers/Api/Students/StudentController.php app/Http/Controllers/Api/Fees/FeeController.php tests/Feature/Api/RoleScopingCoreTest.php
git add app/Http/Controllers/Api/Statistics/StatisticsController.php app/Http/Controllers/Api/Classrooms/ClassroomController.php app/Http/Controllers/Api/Students/StudentController.php app/Http/Controllers/Api/Fees/FeeController.php tests/Feature/Api/RoleScopingCoreTest.php
git commit -m "feat(api): scope core mobile data by active role"
```

---

### Task 4: Backend — remaining scoping and chat

**Files:**
- Modify: `app/Http/Controllers/Api/Materials/MaterialController.php` (two scope blocks)
- Modify: `app/Http/Controllers/Api/Observations/ObservationController.php`
- Modify: `app/Http/Controllers/Api/Qualifications/QualificationController.php` (visibility and list scopes)
- Modify: `app/Http/Controllers/Api/Parents/ParentController.php`
- Modify: `app/Http/Controllers/Api/Homework/HomeworkController.php`
- Modify: `app/Http/Controllers/Api/Absences/AbsenceController.php`
- Modify: `app/Http/Controllers/Api/Professors/ProfessorController.php`
- Modify: `app/Services/BirthdayService.php` (default role)
- Modify: `app/Services/ChatQueryService.php` (admin branch in list/suggestions)
- Test: `tests/Feature/Api/RoleScopingRemainingTest.php`

**Interfaces:**
- Consumes: active role from the token.
- Produces: same response shapes, scoped by active role.

- [ ] **Step 1: Write the failing tests**

Add a material scoping test and a qualification visibility test:

```php
test('parent mode sees materials from the child classroom only', function () {
    [$user, $childClassroom, $professorOnlyClassroom] = createMaterialRoleScenario();
    $token = $user->createToken('test')->plainTextToken;

    $this->withToken($token)
        ->postJson('/api/v1/user-data/switch-role', ['role' => 'parent'])
        ->assertOk();

    $materials = $this->withToken($token)->getJson('/api/v1/materials')->json('data');
    $ids = collect($materials)->pluck('id');

    expect($ids)->toContain($childClassroom->materials->first()->id)
        ->not->toContain($professorOnlyClassroom->materials->first()->id);
});
```

For qualification visibility, create one public and one private observation for the child's classroom, switch to parent, and assert the private one is not returned by `/api/v1/qualifications/boletin/{student}/{classroom}`. Repeat the same for `/boletin/{student}/{classroom}/link` if it is covered by the existing tests.

- [ ] **Step 2: Run the tests to verify they fail**

Run: `DB_DATABASE=efe_role_mode_test ./vendor/bin/pest tests/Feature/Api/RoleScopingRemainingTest.php`
Expected: FAIL — professor precedence still wins.

- [ ] **Step 3: Implement the remaining scoping changes**

Apply the same pattern: resolve `$active = $user->activeRole()` once per scope method and branch on it. Replace only the data-scope `hasRole()` branches; leave authorization checks and `hasRole('admin')` bypasses in `ChatController`/`MessageController` untouched.

- `MaterialController`: both scope blocks (admin/branch → professor → parent → student).
- `ObservationController`: same order.
- `QualificationController`: change `applyRoleFilter` to branch on `activeRole()` with the same admin/branch → professor → parent → student order. In `boletin` (line ~167) and `boletinLink` (line ~283), replace `! hasRole(['admin','branch','professor'])` with an active-role check so parent/student modes hide private observations. Do not change `authorizeBoletin`.
- `ParentController`: same order.
- `HomeworkController`: same order.
- `AbsenceController`: same order.
- `ProfessorController`: same order.
- `BirthdayService`: default argument becomes `$role ?? $user->activeRole()`.
- `ChatQueryService`: replace `$user->hasRole('admin')` with `$activeRole === 'admin'` in the conversation list and suggestion branches. Keep `ChatController`/`MessageController` admin bypasses as actual-role permissions.

- [ ] **Step 4: Run the tests to verify they pass**

Run: `DB_DATABASE=efe_role_mode_test ./vendor/bin/pest tests/Feature/Api/RoleScopingRemainingTest.php`
Expected: PASS.

- [ ] **Step 5: Format and commit**

```bash
cd /opt/dev/efe-app/.worktrees/feat-role-mode-switch
./vendor/bin/pint app/Http/Controllers/Api/Materials/MaterialController.php app/Http/Controllers/Api/Observations/ObservationController.php app/Http/Controllers/Api/Qualifications/QualificationController.php app/Http/Controllers/Api/Parents/ParentController.php app/Http/Controllers/Api/Homework/HomeworkController.php app/Http/Controllers/Api/Absences/AbsenceController.php app/Http/Controllers/Api/Professors/ProfessorController.php app/Services/BirthdayService.php app/Services/ChatQueryService.php tests/Feature/Api/RoleScopingRemainingTest.php
git add app/Http/Controllers/Api/Materials/MaterialController.php app/Http/Controllers/Api/Observations/ObservationController.php app/Http/Controllers/Api/Qualifications/QualificationController.php app/Http/Controllers/Api/Parents/ParentController.php app/Http/Controllers/Api/Homework/HomeworkController.php app/Http/Controllers/Api/Absences/AbsenceController.php app/Http/Controllers/Api/Professors/ProfessorController.php app/Services/BirthdayService.php app/Services/ChatQueryService.php tests/Feature/Api/RoleScopingRemainingTest.php
git commit -m "feat(api): scope remaining mobile endpoints by active role"
```

---

### Task 5: Backend — fix multi-role policy precedence

**Files:**
- Modify: `app/Policies/ClassroomsPolicy.php` (`view`)
- Modify: `app/Policies/MaterialPolicy.php` (`view`)
- Test: `tests/Feature/Api/MultiRolePolicyTest.php`

**Interfaces:**
- Consumes: a professor+parent user, a child's classroom/material.
- Produces: `$user->can('view', $classroom)` and `$user->can('view', $material)` return true in parent mode even when the professor is not assigned.

- [ ] **Step 1: Write the failing test**

```php
test('professor parent can view the child classroom and material', function () {
    [$user, $classroom, $material] = createProfessorParentClassroomScenario();

    expect($user->can('view', $classroom))->toBeTrue();
    expect($user->can('view', $material))->toBeTrue();
});
```

The scenario must give the professor their own `professorData`, give the parent a child enrolled in `$classroom`, and make sure `$classroom` is **not** assigned to the professor.

- [ ] **Step 2: Run the test to verify it fails**

Run: `DB_DATABASE=efe_role_mode_test ./vendor/bin/pest tests/Feature/Api/MultiRolePolicyTest.php`
Expected: FAIL — the professor branch returns `false` before reaching the parent branch.

- [ ] **Step 3: Fix the policies**

In `ClassroomsPolicy::view` and `MaterialPolicy::view`, change the professor branch so it returns `true` only when the professor is assigned; otherwise it falls through to the parent/student branches. Do not change `create`, `update` or `delete`; those remain real-role permissions.

- [ ] **Step 4: Run the test to verify it passes**

Run: `DB_DATABASE=efe_role_mode_test ./vendor/bin/pest tests/Feature/Api/MultiRolePolicyTest.php`
Expected: PASS.

- [ ] **Step 5: Format and commit**

```bash
cd /opt/dev/efe-app/.worktrees/feat-role-mode-switch
./vendor/bin/pint app/Policies/ClassroomsPolicy.php app/Policies/MaterialPolicy.php tests/Feature/Api/MultiRolePolicyTest.php
git add app/Policies/ClassroomsPolicy.php app/Policies/MaterialPolicy.php tests/Feature/Api/MultiRolePolicyTest.php
git commit -m "fix(api): allow multi-role parents to view child classrooms"
```

---

### Task 6: App — role mode data layer and controller

**Files:**
- Create: `lib/features/role_mode/domain/role_switch_result.dart`
- Create: `lib/features/role_mode/data/role_mode_api.dart`
- Create: `lib/features/role_mode/data/role_mode_repository.dart`
- Create: `lib/features/role_mode/providers/role_switch_provider.dart`
- Modify: `lib/features/auth/providers/auth_provider.dart` (add `applyActiveRole`)
- Modify: `lib/features/auth/domain/user_model.dart` (`canManageMaterials`)
- Test: `test/role_mode/role_switch_controller_test.dart`

**Interfaces:**
- Consumes: `ApiClient`, `AuthNotifier`, `UserModel`.
- Produces:
  - `class RoleSwitchResult { final String role; final List<String> roles; final String? selectedStudentId; }`
  - `class RoleModeApi { Future<Response> switchRole(String role); }`
  - `class RoleModeRepository { Future<RoleSwitchResult> switchRole(String role); }`
  - `enum RoleSwitchStatus { idle, switching, error }`
  - `class RoleSwitchState { final RoleSwitchStatus status; final String? error; bool get isSwitching; }`
  - `class RoleSwitchController extends StateNotifier<RoleSwitchState> { RoleSwitchController(Ref ref, RoleModeRepository repository); Future<bool> switchTo(String role); }`
  - `final roleModeApiProvider`, `roleModeRepositoryProvider`, `roleSwitchControllerProvider`.
  - `void AuthNotifier.applyActiveRole({required String role, required List<String> roles})`.

```dart
final roleSwitchControllerProvider =
    StateNotifierProvider<RoleSwitchController, RoleSwitchState>((ref) {
  return RoleSwitchController(ref, ref.watch(roleModeRepositoryProvider));
});
```

- [ ] **Step 1: Write the failing model and controller tests**

`test/role_mode/role_switch_controller_test.dart`:

```dart
test('canManageMaterials follows the active role', () {
  const professor = UserModel(id: '1', name: 'P', email: 'p@test.com', role: 'professor', roles: ['professor', 'parent']);
  const parent = UserModel(id: '1', name: 'P', email: 'p@test.com', role: 'parent', roles: ['professor', 'parent']);

  expect(professor.canManageMaterials, isTrue);
  expect(parent.canManageMaterials, isFalse);
});

test('switchTo updates the auth user and returns true', () async {
  final container = ProviderContainer(
    overrides: [
      authRepositoryProvider.overrideWithValue(_FakeMultiRoleAuthRepository()),
      roleModeRepositoryProvider.overrideWithValue(_FakeRoleModeRepository()),
    ],
  );
  addTearDown(container.dispose);
  await waitForAuth(container);

  final ok = await container.read(roleSwitchControllerProvider.notifier).switchTo('parent');

  expect(ok, isTrue);
  expect(container.read(authProvider).user?.role, 'parent');
  expect(container.read(authProvider).user?.roles, ['professor', 'parent']);
  expect(container.read(roleSwitchControllerProvider).isSwitching, isFalse);
});
```

Define `Future<void> waitForAuth(ProviderContainer container)` in the test file: it polls `container.read(authProvider).user` with `await Future<void>.delayed(Duration.zero)` until non-null, with a bounded loop (for example 50 iterations) so the test fails clearly instead of hanging.

Add a third test where the fake repository throws and expect `ok` false and `state.error` non-null. Include a fake auth repository and a fake role mode repository in the test file.

- [ ] **Step 2: Run the tests to verify they fail**

Run: `flutter test test/role_mode/role_switch_controller_test.dart`
Expected: FAIL — the role mode files and `applyActiveRole` do not exist.

- [ ] **Step 3: Implement the data layer and controller**

- `RoleModeApi.switchRole`: `POST /user-data/switch-role` with `{'role': role}`.
- `RoleModeRepository.switchRole`: parse `response.data['data']` into `RoleSwitchResult`; throw `ApiException` on invalid payload.
- `RoleSwitchController.switchTo`:
  1. set `RoleSwitchStatus.switching`;
  2. call the repository;
  3. `ref.read(authProvider.notifier).applyActiveRole(role: result.role, roles: result.roles)`;
  4. set `parentSelectedStudentProvider` to `result.selectedStudentId` when the new role is `parent`, otherwise `null`;
  5. invalidate the providers listed in Task 9 (Task 9 fills the final list; here call a private `_invalidateRoleScopedProviders()` method);
  6. on success set `idle` and return true;
  7. on error set `error` and return false.

- [ ] **Step 4: Update `AuthNotifier` and `UserModel`**

- `AuthNotifier.applyActiveRole`: if `state.user == null`, return; otherwise `state = state.copyWith(user: state.user!.copyWith(role: role, roles: roles));`.
- `UserModel.canManageMaterials`: return true only when `role` is `professor`, `admin` or `branch`; do not use `roles`.

- [ ] **Step 5: Run the tests to verify they pass**

Run: `flutter test test/role_mode/role_switch_controller_test.dart`
Expected: PASS.

- [ ] **Step 6: Format and commit**

```bash
cd /home/defaultuser/.local/share/opencode/worktree/2e09a3/feat-role-mode-switch
dart format lib/features/role_mode lib/features/auth test/role_mode
flutter analyze
git add lib/features/role_mode lib/features/auth test/role_mode
git commit -m "feat(app): add role mode data layer and switch controller"
```

---

### Task 7: App — navigation follows the active role without recreating the router

**Files:**
- Modify: `lib/app/router.dart` (`routerProvider`, `CustomBottomNav`)
- Modify: `lib/features/classrooms/screens/classroom_history_screen.dart` (reset initial-load flag on role change)
- Test: `test/app/bottom_nav_test.dart`

**Interfaces:**
- Consumes: `AuthNotifier.applyActiveRole`.
- Produces: `routerProvider` observes only `AuthStatus`; the center tab goes to `/payments` for parent and `/classrooms` otherwise.

- [ ] **Step 1: Write the failing navigation tests**

In `test/app/bottom_nav_test.dart`:
- Import `lib/features/classrooms/screens/classroom_list_screen.dart`.
- Make `_FakeAuthRepository` accept `role` and `roles`; make `_pumpApp` return the `ProviderContainer`.
- Add:

```dart
testWidgets('switch does not recreate the router and updates the center tab', (tester) async {
  final container = await _pumpApp(tester, 'parent', roles: ['professor', 'parent']);
  final routerBefore = container.read(routerProvider);

  container.read(authProvider.notifier).applyActiveRole(
        role: 'professor',
        roles: ['professor', 'parent'],
      );
  await tester.pumpAndSettle();

  expect(container.read(routerProvider), same(routerBefore));
  expect(navLabel('Aulas'), findsOneWidget);
  expect(navLabel('Pagos'), findsNothing);

  await tester.tap(navLabel('Aulas'));
  await tester.pumpAndSettle();
  expect(find.byType(ClassroomListScreen), findsOneWidget);
});
```

- [ ] **Step 2: Run the test to verify it fails**

Run: `flutter test test/app/bottom_nav_test.dart`
Expected: FAIL — `routerProvider` is recreated and/or the center tab still points at Pagos.

- [ ] **Step 3: Fix the router**

- Change `routerProvider` to `final authStatus = ref.watch(authProvider.select((s) => s.status));` and use `authStatus` in the redirect. Do not watch the whole `AuthState`.
- Remove `isParent` from the provider and from `StatefulShellBranch(initialLocation: ...)`; leave the branch default.
- In `CustomBottomNav`, for index 1:
  - `isParent` from `ref.watch(authProvider).user?.role == 'parent'`.
  - `onTap` calls `context.go(isParent ? '/payments' : '/classrooms')` instead of `goBranch`.
  - Keep the label/icon logic.
- The other tabs keep `goBranch`.

- [ ] **Step 4: Reset the history screen on role change**

In `classroom_history_screen.dart`, add a `ref.listen` on `authProvider.select((s) => s.user?.role)`. When the role changes, set the initial-load flag to false and trigger the same load path used on first mount. Do not call `setState` after dispose.

- [ ] **Step 5: Run the tests to verify they pass**

Run: `flutter test test/app/bottom_nav_test.dart`
Expected: PASS.

- [ ] **Step 6: Format and commit**

```bash
cd /home/defaultuser/.local/share/opencode/worktree/2e09a3/feat-role-mode-switch
dart format lib/app/router.dart lib/features/classrooms/screens/classroom_history_screen.dart test/app/bottom_nav_test.dart
flutter analyze
flutter test test/app/bottom_nav_test.dart
git add lib/app/router.dart lib/features/classrooms/screens/classroom_history_screen.dart test/app/bottom_nav_test.dart
git commit -m "feat(app): make navigation follow the active role"
```

---

### Task 8: App — mode chip, sheet, profile section and localization

**Files:**
- Create: `lib/features/role_mode/widgets/mode_switch_chip.dart`
- Create: `lib/features/role_mode/widgets/mode_switch_sheet.dart`
- Create: `lib/features/role_mode/widgets/mode_section.dart`
- Create: `lib/features/role_mode/domain/role_labels.dart`
- Modify: `lib/core/widgets/home_header.dart` (optional `badge` slot)
- Modify: `lib/features/dashboard/screens/dashboard_screen.dart`
- Modify: `lib/features/dashboard/screens/parent_home_screen.dart`
- Modify: `lib/features/dashboard/screens/professor_home_screen.dart`
- Modify: `lib/features/profile/screens/profile_screen.dart`
- Modify: `lib/l10n/app_es.arb`, `lib/l10n/app_en.arb`
- Regenerate: `lib/l10n/app_localizations*.dart`
- Test: `test/role_mode/mode_switch_sheet_test.dart`

**Interfaces:**
- Consumes: `roleSwitchControllerProvider`, `authProvider`, `UserModel.roles`.
- Produces:
  - `String roleLabel(AppLocalizations l10n, String role)`
  - `Widget ModeSwitchChip({super.key})`
  - `Widget ModeSection({super.key})`
  - `Future<bool?> showModeSwitchSheet(BuildContext context)`

- [ ] **Step 1: Write the failing widget tests**

`test/role_mode/mode_switch_sheet_test.dart`:
- Pump a `MaterialApp` with a `Consumer`/button that calls `showModeSwitchSheet(context)`.
- Override `authRepositoryProvider` with a professor+parent user and `roleModeRepositoryProvider` with a fake success repository.
- Tap the button, expect the sheet with “Profesor” and “Padre”, tap “Padre”, expect the fake repo called with `parent` and the sheet closed.
- Add an error test: the fake repo throws; expect `roleModeSwitchError` text visible and the sheet still open.

- [ ] **Step 2: Run the tests to verify they fail**

Run: `flutter test test/role_mode/mode_switch_sheet_test.dart`
Expected: FAIL — the widgets and l10n keys do not exist.

- [ ] **Step 3: Add the localization keys**

Add to `app_es.arb` / `app_en.arb`:
- `roleModeTitle`: “Modo de uso” / “Mode”
- `roleModeSubtitle`: “Elegí con qué rol querés usar la app” / “Choose which role to use the app with”
- `roleModeCurrent`: “Modo actual” / “Current mode”
- `roleModeChange`: “Cambiar modo” / “Switch mode”
- `roleModeSwitched`: “Ahora estás en modo {role}” / “You’re now in {role} mode” — declare a `role` String placeholder in both ARB files with `@roleModeSwitched`.
- `roleModeSwitchError`: “No pudimos cambiar el modo. Intentá de nuevo.” / “We couldn’t switch modes. Try again.”
- `roleModeLoading`: “Cambiando modo…” / “Switching mode…”
- `roleModeDescriptionProfessor`, `roleModeDescriptionParent`, `roleModeDescriptionStudent`, `roleModeDescriptionAdmin`, `roleModeDescriptionBranch`.

Run `flutter gen-l10n`.

- [ ] **Step 4: Implement the UI**

- `role_labels.dart`: map `admin`, `branch`, `professor`, `parent`, `student` to the existing `l10n.role*`; fall back to the raw role.
- `HomeHeader`: add `final Widget? badge;` and render it after the title row, before `child`, with a `SizedBox(height: 10)`.
- `ModeSwitchChip`: visible only when `user.roles.length > 1`; a compact pill with the current role label and a swap icon. On tap, `await showModeSwitchSheet(context)`; on `true`, show the success snackbar and `context.go('/dashboard')`.
- `ModeSwitchSheet`: a `ConsumerWidget` bottom sheet with drag handle, title/subtitle, one row per `user.roles`, check on `user.role`, role description, and a spinner/disabled state while switching. On tap, call `switchTo`; on success `Navigator.pop(context, true)`; on error keep the sheet open and show `state.error ?? l10n.roleModeSwitchError`.
- `ModeSection`: a profile `SectionHeader` + `AppCard` row with “Modo actual” and “Cambiar modo”; hidden when `roles.length <= 1`; same sheet flow.
- Wire `badge: const ModeSwitchChip()` into the three `HomeHeader` call sites: `dashboard_screen.dart`, `parent_home_screen.dart`, `professor_home_screen.dart`.
- Add `ModeSection` to `profile_screen.dart` between the account and preferences sections.
- Replace the private role-name helpers in dashboard/profile with `roleLabel` where practical.

- [ ] **Step 5: Run the tests to verify they pass**

Run: `flutter test test/role_mode/mode_switch_sheet_test.dart`
Expected: PASS.

- [ ] **Step 6: Format, analyze and commit**

```bash
cd /home/defaultuser/.local/share/opencode/worktree/2e09a3/feat-role-mode-switch
dart format lib/features/role_mode lib/core/widgets/home_header.dart lib/features/dashboard/screens lib/features/profile/screens test/role_mode
flutter gen-l10n
flutter analyze
flutter test test/role_mode/mode_switch_sheet_test.dart
git add lib/features/role_mode lib/core/widgets/home_header.dart lib/features/dashboard/screens lib/features/profile/screens lib/l10n test/role_mode
git commit -m "feat(app): add role mode switch UI"
```

---

### Task 9: App — refresh role-scoped data after a switch

**Files:**
- Modify: `lib/features/role_mode/providers/role_switch_provider.dart` (`_invalidateRoleScopedProviders`)
- Modify: `lib/core/api/interceptors/error_interceptor.dart` (`_extractErrorDetail`)
- Test: `test/role_mode/role_switch_invalidation_test.dart`

**Interfaces:**
- Consumes: `RoleSwitchController` from Task 6.
- Produces: invalidating the persistent providers after a switch and parsing `ApiResponder` errors.

- [ ] **Step 1: Write the failing invalidation test**

```dart
test('switch invalidates the relations provider', () async {
  var calls = 0;
  final container = ProviderContainer(
    overrides: [
      authRepositoryProvider.overrideWithValue(_FakeMultiRoleAuthRepository()),
      roleModeRepositoryProvider.overrideWithValue(_FakeRoleModeRepository()),
      relationsRepositoryProvider.overrideWithValue(_CountingRelationsRepository(() => calls++)),
    ],
  );
  addTearDown(container.dispose);
  await waitForAuth(container);

  container.read(relationsProvider);
  await container.read(roleSwitchControllerProvider.notifier).switchTo('parent');
  container.read(relationsProvider);

  expect(calls, 2);
});
```

- [ ] **Step 2: Run the test to verify it fails**

Run: `flutter test test/role_mode/role_switch_invalidation_test.dart`
Expected: FAIL — the controller does not invalidate `relationsProvider`.

- [ ] **Step 3: Implement the invalidation list**

In `RoleSwitchController._invalidateRoleScopedProviders()` call `ref.invalidate` for:
- `relationsProvider`, `dashboardProvider`
- `classroomListProvider`, `classroomFiltersProvider`, `classroomDetailProvider`, `classroomStudentsProvider`, `classroomProfessorsProvider`, `classroomMaterialsProvider`, `parentCoursesProvider`, `classroomHistoryProvider`
- `studentListProvider`, `studentDetailProvider`, `studentClassroomsProvider`, `studentAbsencesProvider`, `studentFeesProvider`
- `feeListProvider`, `parentFeesProvider`, `feeDetailProvider`
- `qualificationListProvider`, `boletinProvider`
- `chatListProvider`, `chatUnreadCountProvider`, `messagesProvider`
- `notificationListProvider`, `unreadCountProvider`
- `documentListProvider`, `eventListProvider`, `newsListProvider`

Do not import the search screen provider here; the search screen is a pushed route and is cleared when the shell returns to the dashboard.

Reset or preselect `parentSelectedStudentProvider` **before** invalidating `classroomListProvider`: set it to `result.selectedStudentId` for parent mode and to `null` for the other roles.

- [ ] **Step 4: Fix the error detail parser**

In `ErrorInterceptor._extractErrorDetail`, also read `data['error']['detail']` and `data['message']` before falling back to `err.message`. Keep the existing JSON:API `errors` handling.

- [ ] **Step 5: Run the test to verify it passes**

Run: `flutter test test/role_mode/role_switch_invalidation_test.dart`
Expected: PASS.

- [ ] **Step 6: Format, analyze and commit**

```bash
cd /home/defaultuser/.local/share/opencode/worktree/2e09a3/feat-role-mode-switch
dart format lib/features/role_mode lib/core/api/interceptors/error_interceptor.dart test/role_mode
flutter analyze
flutter test test/role_mode/role_switch_invalidation_test.dart
git add lib/features/role_mode lib/core/api/interceptors/error_interceptor.dart test/role_mode
git commit -m "feat(app): refresh role-scoped data after switching modes"
```

---

### Task 10: Docs and end-to-end verification

**Files:**
- Modify: `/opt/dev/efe-app/.worktrees/feat-role-mode-switch/STATE.md`
- Modify: `/opt/dev/efe-app/.worktrees/feat-role-mode-switch/TASKS.md`
- Modify: `README.md` (feature list)
- Test: manual verification checklist

- [ ] **Step 1: Update backend project state**

Add a session entry to `STATE.md` and update `TASKS.md` with:
- token-scoped active role;
- switch endpoint and auth responses;
- scoping refactor and policy fix;
- pending: deploy and browser/app verification.

- [ ] **Step 2: Update the app feature list**

Add a line to `README.md` under “Características principales”:
“**Modo por rol**: los usuarios con varios roles pueden alternar entre profesor, padre, alumno, admin o branch.”

- [ ] **Step 3: Run the backend verification**

In the backend worktree, with a disposable DB:
```bash
./vendor/bin/pint
DB_DATABASE=efe_role_mode_test ./vendor/bin/pest tests/Feature/Api/RoleModeFoundationTest.php tests/Feature/Api/RoleSwitchApiTest.php tests/Feature/Api/RoleScopingCoreTest.php tests/Feature/Api/RoleScopingRemainingTest.php tests/Feature/Api/MultiRolePolicyTest.php
```
Then, against the dev server, with a real multi-role account:
- login → `/auth/me` returns the primary role and real roles;
- switch to parent → `/auth/me`, `/statistics/dashboard`, `/classrooms`, `/students`, `/fees`, `/chats` reflect parent scope;
- switch to professor → professor scope returns;
- invalid role → 422;
- `/auth/refresh` keeps the mode.

- [ ] **Step 4: Run the app verification**

```bash
cd /home/defaultuser/.local/share/opencode/worktree/2e09a3/feat-role-mode-switch
flutter analyze
flutter test
```
Manual checks on a 320 px-wide device/emulator:
- multi-role user sees “Modo Profesor” in home and Perfil;
- switch to parent changes home, center tab to Pagos, menu and profile badge;
- switch back restores professor;
- kill/relaunch keeps the mode;
- single-role user sees no chip;
- the sheet shows loading, error and success without closing the router.

- [ ] **Step 5: Commit the docs**

```bash
cd /home/defaultuser/.local/share/opencode/worktree/2e09a3/feat-role-mode-switch
git add README.md
git commit -m "docs: document role mode switcher"

cd /opt/dev/efe-app/.worktrees/feat-role-mode-switch
git add STATE.md TASKS.md
git commit -m "docs: record role mode session"
```
