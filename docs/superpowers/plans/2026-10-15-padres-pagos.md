# Pantalla Pagos de padres (etapa 2) — Plan de implementación

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** El padre ve todas las cuotas de sus hijos ordenadas (vencidas → pendientes → pagadas) con la mora total, sube/reemplaza comprobantes de pago (quedan en revisión para administración) y descarga la factura de las pagadas — con autorización correcta en la API y sin cambios para otros roles.

**Architecture:** Backend: `SystemCollectionsFeesPolicy` + `is_overdue` en el resource + rama padre de `/fees` (lista completa ordenada, sin cursor) + `invoice-link` firmado. Flutter: `ParentFeesScreen` (`/payments`), `ParentFeeDetailScreen` (`/payments/:id`), `ParentFeeCard`, `ParentFeeProofSheet`; `FeeListScreen`/`FeeDetailScreen` quedan para los demás roles.

**Tech Stack:** Flutter 3.x + Riverpod 2 + go_router 14.8.1 + freezed (build_runner) + file_picker 6 + url_launcher 6; Laravel 11 (`efe-app`, contenedor `dev-efe`).

**Spec:** `docs/superpowers/specs/2026-10-15-padres-pagos-design.md`

## Global Constraints

- La policy espeja la cadena que usa `applyRoleFilter` (SystemStudents→SystemParents→ParentData vía `parent_app_id`): “lo que la lista muestra es lo que la policy permite”.
- `/fees`: **solo la rama padre cambia** (lista completa ordenada sin cursor, meta `{cursor: null, has_more: false, total: N}`); admin/sucursal/alumno conservan el comportamiento actual con cursor por id.
- **efe-app: NO ejecutar Pest / `php artisan test`** (AGENTS.md). Verificación backend: `php -l`, `./vendor/bin/pint`, tinker en el contenedor `dev-efe`.
- Montos con `AppFormatters.formatCurrency` (etapa 1 R9: `1.300.000,00 $`, símbolo pospuesto) y comparaciones de test contra el formatter, nunca strings prefijo-`$`.
- Textos ES+EN en ARB + `flutter gen-l10n`; sin strings hardcodeados.
- Claro y oscuro; contraste ≥4.5:1; `primarySoft` solo relleno decorativo.
- Gate de analyze: **sin issues nuevos** (baseline: 45 issues `info`/`warning`, 0 `error`).
- Un solo request para la lista de padres (llega completa).
- Commits por tarea (mensajes `feat:`/`fix:`/`docs:` en español, estilo del repo).

## Review Focus

1. Cuota `cancelled` o estado desconocido ⇒ card con etiqueta muted de fallback, sin excepción. (Task 6)
2. `under_review` por `proof_status` **o** por `status` ⇒ “En revisión” sin acción. (Task 6)
3. Factura sin PDF (404) ⇒ snackbar “Factura no disponible”, sin crash. (Task 9)
4. Archivo >10 MB o extensión inválida ⇒ rechazo cliente sin llamar a la API. (Task 7)
5. CTA global: 0 accionables ⇒ oculta; exactamente 1 ⇒ sheet directo; 2+ ⇒ selector. (Task 8)
6. Reemplazo de comprobante (subir con `under_review`) ⇒ permitido y refresca detalle/lista. (Tasks 7 y 9)

---

### Task 1: Policy de autorización de cuotas (API)

**Files:**
- Create: `/opt/dev/efe-app/app/Policies/SystemCollectionsFeesPolicy.php`
- Modify: `/opt/dev/efe-app/app/Http/Controllers/Api/Fees/FeeController.php`
- Test: `/opt/dev/efe-app/tests/Feature/Api/FeesPolicyTest.php` (escribir, **no ejecutar**)

**Interfaces:**
- Consumes: `SystemStudents::parents()` (belongsToMany `system_parents_system_students`), `SystemParents::ParentData()` (belongsTo por `parent_app_id`), `User::hasRole`, `User::studentData`, `SystemStudents::student_app_id`.
- Produces: abilities `view`, `uploadProof`, `downloadInvoice`, `update`, `pay`, `manage`; 403 para no autorizados. `applyRoleFilter` del listado queda igual.

- [ ] **Step 1: Escribir el test Pest (no ejecutar)**

Crear `tests/Feature/Api/FeesPolicyTest.php` (fixtures propios; **no** reusar funciones de otros archivos Pest para evitar colisiones de nombres):

```php
<?php

use App\Models\SystemCollectionsFees;
use App\Models\SystemParents;
use App\Models\SystemStudents;
use App\Models\SystemStudentsFamilyGroup;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Http\UploadedFile;
use Illuminate\Support\Facades\DB;
use Laravel\Sanctum\Sanctum;

uses(RefreshDatabase::class);

function createFeePolicyStudent(): SystemStudents
{
    $group = SystemStudentsFamilyGroup::factory()->create();
    return SystemStudents::withoutGlobalScopes()->create([
        'family_group_id' => $group->id, 'active' => true,
        'name' => fake()->firstName(), 'lastname' => fake()->lastName(),
        'type_document' => 'DNI', 'birth_date' => fake()->date(),
        'address' => fake()->address(), 'city' => fake()->city(),
        'province' => fake()->state(), 'phone' => fake()->phoneNumber(),
        'document_number' => fake()->unique()->numerify('########'),
        'email' => fake()->unique()->safeEmail(), 'school' => fake()->word(),
        'grade' => '1ro', 'inscription_date' => fake()->date(),
        'inscription_year' => 2026, 'inscription_price' => 25000,
        'pure_quota' => 25000, 'student_price' => 25000, 'last_quota' => 25000,
    ]);
}

function createFeePolicyFee(SystemStudents $student, array $overrides = []): SystemCollectionsFees
{
    return SystemCollectionsFees::withoutGlobalScope('isNotRegistration')->create(array_merge([
        'student_id' => $student->id, 'number_fee' => 1, 'month' => 3, 'year' => 2026,
        'payment_date' => '2026-03-05', 'to_pay' => 25000, 'subsidy' => 0,
        'branch_subsidy' => 0, 'recharge' => 0, 'paid' => 0, 'owe' => 0, 'favor' => 0,
        'total' => 25000, 'status' => 'pending',
    ], $overrides));
}

function createFeePolicyParentOf(SystemStudents $student): array
{
    $user = User::factory()->create();
    $user->studentData()->delete();
    $user->professorData()->delete();
    $user->userData()->delete();
    $parent = $user->parentData()->create(['fullname' => 'Padre Test', 'email' => $user->email]);

    $systemParentId = DB::table('system_parents')->insertGetId([
        'name' => 'Padre', 'lastname' => 'Test', 'address' => '-', 'city' => '-',
        'province' => '-', 'phone' => '-', 'workplace' => '-', 'type' => 'padre',
        'family_group_id' => $student->family_group_id, 'parent_app_id' => $parent->id,
        'created_at' => now(), 'updated_at' => now(),
    ]);
    DB::table('system_parents_system_students')->insert([
        'parent_id' => $systemParentId, 'student_id' => $student->id,
    ]);

    return [$user, $parent];
}

test('parent can view and upload proof for own child fee', function () {
    $student = createFeePolicyStudent();
    $fee = createFeePolicyFee($student);
    [$user] = createFeePolicyParentOf($student);
    Sanctum::actingAs($user);

    $this->getJson("/api/v1/fees/{$fee->id}")->assertOk();

    $this->post("/api/v1/fees/{$fee->id}/upload-proof", [
        'proof' => UploadedFile::fake()->image('proof.jpg'),
    ])->assertOk();
});

test('parent cannot view or upload proof for another family fee', function () {
    $ownStudent = createFeePolicyStudent();
    $otherFee = createFeePolicyFee(createFeePolicyStudent());
    [$user] = createFeePolicyParentOf($ownStudent);
    Sanctum::actingAs($user);

    $this->getJson("/api/v1/fees/{$otherFee->id}")->assertForbidden();
    $this->post("/api/v1/fees/{$otherFee->id}/upload-proof", [
        'proof' => UploadedFile::fake()->image('proof.jpg'),
    ])->assertForbidden();
});

// Además (misma estructura):
// - student: ve solo su propia cuota (student_app_id = studentData.id) y NO puede uploadProof (403).
// - admin: ve/actualiza/paga cualquier cuota; parent NO puede pay/update (403).
// - professor: 403 en show.
```

- [ ] **Step 2: Implementar la policy**

```php
<?php

namespace App\Policies;

use App\Models\SystemCollectionsFees;
use App\Models\User;

class SystemCollectionsFeesPolicy
{
    public function view(User $user, SystemCollectionsFees $fee): bool
    {
        return $this->canAccess($user, $fee);
    }

    public function downloadInvoice(User $user, SystemCollectionsFees $fee): bool
    {
        return $this->canAccess($user, $fee);
    }

    public function uploadProof(User $user, SystemCollectionsFees $fee): bool
    {
        if ($user->hasRole(['admin', 'branch'])) {
            return true;
        }

        return $user->hasRole('parent') && $this->isParentOfFee($user, $fee);
    }

    public function update(User $user, SystemCollectionsFees $fee): bool
    {
        return $user->hasRole(['admin', 'branch']);
    }

    public function pay(User $user, SystemCollectionsFees $fee): bool
    {
        return $user->hasRole(['admin', 'branch']);
    }

    public function manage(User $user): bool
    {
        return $user->hasRole(['admin', 'branch']);
    }

    private function canAccess(User $user, SystemCollectionsFees $fee): bool
    {
        if ($user->hasRole(['admin', 'branch'])) {
            return true;
        }

        if ($user->hasRole('parent')) {
            return $this->isParentOfFee($user, $fee);
        }

        if ($user->hasRole('student')) {
            return $fee->student?->student_app_id === $user->studentData?->id;
        }

        return false;
    }

    private function isParentOfFee(User $user, SystemCollectionsFees $fee): bool
    {
        return (bool) $fee->student?->parents()
            ->whereHas('ParentData', fn ($q) => $q->where('user_id', $user->id))
            ->exists();
    }
}
```

(Laravel la descubre por convención `App\Models\SystemCollectionsFees` → `App\Policies\SystemCollectionsFeesPolicy`.)

- [ ] **Step 3: Aplicar `authorize` en el controller**

En `app/Http/Controllers/Api/Fees/FeeController.php` (ya usa `AuthorizesRequests`):
- `show`: `$this->authorize('view', $fee);`
- `update`: `$this->authorize('update', $fee);`
- `pay`: `$this->authorize('pay', $fee);`
- `uploadProof`: `$this->authorize('uploadProof', $fee);`
- `invoice`: `$this->authorize('downloadInvoice', $fee);`
- `generate`, `bulkUpdate`, `sendReminders`, `export`: `$this->authorize('manage', SystemCollectionsFees::class);`

- [ ] **Step 4: Verificar sintaxis y estilo**

Run: `php -l app/Policies/SystemCollectionsFeesPolicy.php && php -l app/Http/Controllers/Api/Fees/FeeController.php && php -l tests/Feature/Api/FeesPolicyTest.php`
Expected: `No syntax errors detected` ×3
Run: `./vendor/bin/pint app/Policies/SystemCollectionsFeesPolicy.php app/Http/Controllers/Api/Fees/FeeController.php tests/Feature/Api/FeesPolicyTest.php && ./vendor/bin/pint --test ...` (mismos paths)
Expected: PASS

- [ ] **Step 5: Verificación live (tinker en `dev-efe`; NO Pest)**

```bash
docker exec dev-efe php artisan tinker --execute '
$fee = App\Models\SystemCollectionsFees::whereHas("student.parents", fn($q) => $q->whereNotNull("parent_app_id"))->first();
$parent = $fee->student->parents()->whereNotNull("parent_app_id")->first()->ParentData;
$user = $parent->user;
$other = App\Models\SystemCollectionsFees::where("id", "!=", $fee->id)->first();
echo json_encode([
  "own_view" => $user->can("view", $fee),
  "own_upload" => $user->can("uploadProof", $fee),
  "foreign_view" => $user->can("view", $other),
  "own_pay" => $user->can("pay", $fee),
], JSON_UNESCAPED_UNICODE);
'
```
Expected: `{"own_view":true,"own_upload":true,"foreign_view":false,"own_pay":false}` (receta validada: la base tiene 230 vínculos `system_parents.parent_app_id` y cuotas con padre vinculado).

- [ ] **Step 6: Commit**

```bash
git add app/Policies/SystemCollectionsFeesPolicy.php app/Http/Controllers/Api/Fees/FeeController.php tests/Feature/Api/FeesPolicyTest.php
git commit -m "feat(api): policy de autorizacion para cuotas (padre/alumno/admin)"
```

---

### Task 2: `is_overdue` + lista completa ordenada para padres

**Files:**
- Modify: `/opt/dev/efe-app/app/Models/SystemCollectionsFees.php`
- Modify: `/opt/dev/efe-app/app/Http/Resources/FeeResource.php`
- Modify: `/opt/dev/efe-app/app/Http/Controllers/Api/Fees/FeeController.php` (`index`)
- Test: `/opt/dev/efe-app/tests/Feature/Api/FeesParentListTest.php` (escribir, **no ejecutar**)

**Interfaces:**
- Consumes: `scopeInMora` (regla de vencida), fixtures de Task 1 (mismos helpers locales, nombres únicos `createFeeList*`).
- Produces: `SystemCollectionsFees::isInMora(): bool`; `FeeResource.attributes.is_overdue`; rama padre de `GET /fees` con lista completa ordenada.

- [ ] **Step 1: Escribir el test Pest (no ejecutar)**

```php
// Mismos helpers de fixtures que FeesPolicyTest (duplicados con nombres createFeeList*).
test('parent fee list returns all fees ordered overdue first with is_overdue', function () {
    $student = createFeeListStudent();
    [$user] = createFeeListParentOf($student);
    // vencida (mes anterior), pendiente (mes actual), pagada
    createFeeListFee($student, ['month' => now()->subMonthNoOverflow()->month, 'year' => now()->subMonthNoOverflow()->year, 'status' => 'pending', 'total' => 25000, 'paid' => 0]);
    createFeeListFee($student, ['month' => now()->month, 'year' => now()->year, 'status' => 'pending', 'total' => 25000, 'paid' => 0]);
    createFeeListFee($student, ['month' => now()->subMonthsNoOverflow(2)->month, 'year' => now()->subMonthsNoOverflow(2)->year, 'status' => 'paid', 'total' => 25000, 'paid' => 25000, 'owe' => 0]);
    Sanctum::actingAs($user);

    $response = $this->getJson('/api/v1/fees?per_page=2');

    $response->assertOk()
        ->assertJsonPath('meta.has_more', false)          // lista completa, sin cursor
        ->assertJsonPath('meta.cursor', null)
        ->assertJsonPath('data.0.attributes.is_overdue', true)
        ->assertJsonPath('data.1.attributes.is_overdue', false)
        ->assertJsonPath('data.2.attributes.status', 'paid');
});

test('admin fee list keeps cursor pagination and is_overdue', function () {
    // admin con 3 cuotas; per_page=2 → meta.has_more true, cursor no nulo; is_overdue presente.
});
```

- [ ] **Step 2: Implementar `isInMora` + resource**

En `SystemCollectionsFees` (junto al scope, con comentario cruzado “misma regla que `scopeInMora`”):

```php
public function isInMora(): bool
{
    return in_array($this->status, ['pending', 'partial'], true)
        && (float) $this->total > (float) $this->paid
        && ((int) $this->year < now()->year
            || ((int) $this->year === now()->year && (int) $this->month < now()->month));
}
```

En `FeeResource::attributes`: agregar `'is_overdue' => $this->resource->isInMora(),` a la lista (junto a `status`/`proof_status`).

- [ ] **Step 3: Implementar la rama padre de `index`**

En `FeeController@index`, después de `applyRoleFilter` + `applyFilters`:

```php
if ($request->user()->hasRole('parent')) {
    $fees = $query
        ->orderByRaw(
            "CASE
                WHEN status IN ('pending','partial') AND total > paid
                    AND (year < ? OR (year = ? AND CAST(month AS INTEGER) < ?))
                THEN 0
                WHEN status IN ('pending','partial') THEN 1
                ELSE 2
            END",
            [now()->year, now()->year, now()->month]
        )
        ->orderByDesc('year')
        ->orderByDesc('month')
        ->orderByDesc('id')
        ->get();

    return response()->json([
        'data' => FeeResource::collection($fees)->response()->getData(true)['data'],
        'meta' => ['cursor' => null, 'has_more' => false, 'total' => $fees->count()],
    ]);
}
```

(`paginateCursor` pagina por keyset de `id` con `orderBy id asc`; por eso la lista ordenada va completa y solo para padres.)

- [ ] **Step 4: Verificar sintaxis y estilo**

Run: `php -l app/Models/SystemCollectionsFees.php && php -l app/Http/Resources/FeeResource.php && php -l app/Http/Controllers/Api/Fees/FeeController.php && php -l tests/Feature/Api/FeesParentListTest.php`
Expected: sin errores
Run: `./vendor/bin/pint <4 archivos> && ./vendor/bin/pint --test <4 archivos>`
Expected: PASS

- [ ] **Step 5: Verificación live (tinker; NO Pest)**

```bash
docker exec dev-efe php artisan tinker --execute '
$parent = App\Models\ParentData::whereHas("students")->first();
$studentIds = App\Models\SystemStudents::whereHas("parents", fn($q) => $q->where("parent_app_id", $parent->id))->pluck("id");
$fees = App\Models\SystemCollectionsFees::whereIn("student_id", $studentIds)
    ->orderByRaw("CASE WHEN status IN (\"pending\",\"partial\") AND total > paid AND (year < ? OR (year = ? AND CAST(month AS INTEGER) < ?)) THEN 0 WHEN status IN (\"pending\",\"partial\") THEN 1 ELSE 2 END", [now()->year, now()->year, now()->month])
    ->orderByDesc("year")->orderByDesc("month")->orderByDesc("id")->limit(10)->get();
echo $fees->map(fn($f) => ["id" => $f->id, "status" => $f->status, "is_overdue" => $f->isInMora()])->toJson();
'
```
Expected: JSON con cuotas ordenadas y `is_overdue` coherente con `status`/fecha.

- [ ] **Step 6: Commit**

```bash
git add app/Models/SystemCollectionsFees.php app/Http/Resources/FeeResource.php app/Http/Controllers/Api/Fees/FeeController.php tests/Feature/Api/FeesParentListTest.php
git commit -m "feat(api): is_overdue y lista completa ordenada de cuotas para padres"
```

---

### Task 3: Factura por URL firmada (`invoice-link` + `invoice-file`)

**Files:**
- Modify: `/opt/dev/efe-app/routes/api.php`
- Modify: `/opt/dev/efe-app/app/Http/Controllers/Api/Fees/FeeController.php`
- Test: `/opt/dev/efe-app/tests/Feature/Api/FeesInvoiceLinkTest.php` (escribir, **no ejecutar**)

**Interfaces:**
- Consumes: Task 1 (policy `downloadInvoice`), lógica actual de `invoice` (ingreso → media receipts/invoices → download).
- Produces: `GET /fees/{fee}/invoice-link` (auth) → `{data: {url}}` firmada 10 min; `GET /fees/{fee}/invoice-file` (público, `signed`) → stream del PDF.

- [ ] **Step 1: Escribir el test Pest (no ejecutar)**

```php
test('invoice-link returns a signed url for an authorized fee', function () {
    // parent own fee (fixtures Task 1, nombres createFeeInvoice*)
    Sanctum::actingAs($user);
    $response = $this->getJson("/api/v1/fees/{$fee->id}/invoice-link");
    $response->assertOk();
    $url = $response->json('data.url');
    expect($url)->toContain('signature=');
    expect(\Illuminate\Support\Facades\URL::hasValidSignature(
        \Illuminate\Http\Request::create($url)
    ))->toBeTrue();
});

test('invoice-file rejects missing or tampered signature', function () {
    $student = createFeeInvoiceStudent();
    $fee = createFeeInvoiceFee($student);
    [$user] = createFeeInvoiceParentOf($student);
    Sanctum::actingAs($user);

    $url = $this->getJson("/api/v1/fees/{$fee->id}/invoice-link")->json('data.url');
    $this->getJson("/api/v1/fees/{$fee->id}/invoice-file")->assertForbidden(); // sin firma
    $this->getJson($url.'&x=1')->assertForbidden();                            // firma manipulada
});

test('invoice-file with valid signature but non-paid fee returns 404', function () {
    // firma válida generada con URL::temporarySignedRoute → GET → 404 "Factura no disponible"
});
```

- [ ] **Step 2: Implementar en el controller**

Extraer de `invoice` el cuerpo a `private function buildInvoiceDownload(SystemCollectionsFees $fee)` (misma lógica y 404s) y agregar:

```php
use Illuminate\Support\Facades\URL;

public function invoiceLink(SystemCollectionsFees $fee): JsonResponse
{
    $this->authorize('downloadInvoice', $fee);

    return $this->apiSuccess([
        'url' => URL::temporarySignedRoute(
            'api.fees.invoice-file',
            now()->addMinutes(10),
            ['fee' => $fee->id],
        ),
    ]);
}

public function invoiceFile(SystemCollectionsFees $fee)
{
    return $this->buildInvoiceDownload($fee);
}

public function invoice(SystemCollectionsFees $fee)
{
    $this->authorize('downloadInvoice', $fee);

    return $this->buildInvoiceDownload($fee);
}
```

- [ ] **Step 3: Rutas**

En `routes/api.php`: dentro del grupo `auth:sanctum`, junto a la ruta `invoice`: `Route::get('fees/{fee}/invoice-link', [FeeController::class, 'invoiceLink']);`. **Fuera** del grupo auth (pero dentro del prefijo `v1`):

```php
Route::get('fees/{fee}/invoice-file', [FeeController::class, 'invoiceFile'])
    ->middleware('signed')
    ->name('fees.invoice-file');
```

- [ ] **Step 4: Verificar sintaxis/estilo y rutas**

Run: `php -l app/Http/Controllers/Api/Fees/FeeController.php && php -l routes/api.php && php -l tests/Feature/Api/FeesInvoiceLinkTest.php`
Run: `./vendor/bin/pint <3 archivos> && ./vendor/bin/pint --test <3 archivos>`
Run: `docker exec dev-efe php artisan route:list --path=invoice`
Expected: `invoice-link` (auth) + `invoice-file` (signed) + `invoice` existentes.

- [ ] **Step 5: Verificación live (tinker; NO Pest)**

```bash
docker exec dev-efe php artisan tinker --execute '
$fee = App\Models\SystemCollectionsFees::whereHas("student.parents", fn($q) => $q->whereNotNull("parent_app_id"))->first();
$url = Illuminate\Support\Facades\URL::temporarySignedRoute("api.fees.invoice-file", now()->addMinutes(10), ["fee" => $fee->id]);
$valid = Illuminate\Support\Facades\URL::hasValidSignature(Illuminate\Http\Request::create($url));
$tampered = Illuminate\Support\Facades\URL::hasValidSignature(Illuminate\Http\Request::create($url."&x=1"));
echo json_encode(["url" => $url, "valid" => $valid, "tampered" => $tampered], JSON_UNESCAPED_UNICODE);
'
```
Expected: `valid: true`, `tampered: false`.

- [ ] **Step 6: Commit**

```bash
git add routes/api.php app/Http/Controllers/Api/Fees/FeeController.php tests/Feature/Api/FeesInvoiceLinkTest.php
git commit -m "feat(api): factura de cuota por URL firmada temporal"
```

---

### Task 4: Claves l10n de Pagos

**Files:**
- Modify: `lib/l10n/app_es.arb`, `lib/l10n/app_en.arb`
- Regenerar: `lib/l10n/app_localizations*.dart` (`flutter gen-l10n`)

**Interfaces:**
- Produces (getters l10n): `feesUploadProofAction`, `feesReplaceProofAction`, `feesInvoiceAction`, `feesInvoiceUnavailable`, `feesChooseFeeTitle`, `feesProofStatusReview`, `feesProofPickFile`, `feesProofHint`, `feesProofSuccess`, `feesProofError`.

- [ ] **Step 1: Agregar claves en `app_es.arb`**

```json
"feesUploadProofAction": "Subir comprobante",
"feesReplaceProofAction": "Reemplazar comprobante",
"feesInvoiceAction": "Ver factura",
"feesInvoiceUnavailable": "Factura no disponible",
"feesChooseFeeTitle": "Elegí la cuota",
"feesProofStatusReview": "Comprobante en revisión",
"feesProofPickFile": "Elegir archivo",
"feesProofHint": "JPG, PNG o PDF · hasta 10 MB",
"feesProofSuccess": "Comprobante subido. Un administrador lo revisará.",
"feesProofError": "No se pudo subir el comprobante"
```

- [ ] **Step 2: Agregar las mismas claves en `app_en.arb`**

`"Upload receipt"`, `"Replace receipt"`, `"View invoice"`, `"Invoice unavailable"`, `"Choose the installment"`, `"Receipt under review"`, `"Choose file"`, `"JPG, PNG or PDF · up to 10 MB"`, `"Receipt uploaded. An administrator will review it."`, `"Could not upload the receipt"`.

- [ ] **Step 3: Regenerar y verificar**

Run: `flutter gen-l10n && grep -c "feesUploadProofAction\|feesProofSuccess" lib/l10n/app_localizations.dart`
Expected: ≥2
Run: `flutter analyze`
Expected: sin issues nuevos (45 pre-existentes)

- [ ] **Step 4: Commit**

```bash
git add lib/l10n/
git commit -m "feat(ui): copy de la pantalla Pagos de padres (es/en)"
```

---

### Task 5: `FeeModel` (estados de comprobante) + API/repo de subida y factura

**Files:**
- Modify: `lib/features/fees/domain/fee_model.dart` (+ regenerar `.freezed.dart`)
- Modify: `lib/features/fees/data/fee_api.dart`
- Modify: `lib/features/fees/data/fee_repository.dart`
- Test: `test/fees/fee_repository_test.dart` (+ fakes que implementen `FeeApi`)
- Regenerar: `dart run build_runner build --delete-conflicting-outputs`

**Interfaces:**
- Produces: `FeeModel.proofStatus` (String, default `''`), `FeeModel.isOverdue` (bool, default false), `FeeModel.owe` (double, default 0); `FeeApi.uploadProof(String feeId, {required List<int> bytes, required String filename})`; `FeeApi.getInvoiceLink(String feeId)`; `FeeRepository.uploadProof(...)`, `FeeRepository.getInvoiceUrl(String feeId) → Future<String>` (parsea `response.data['data']['url']`).

- [ ] **Step 1: Escribir los tests que fallan**

En `test/fees/fee_repository_test.dart` (extender `_FakeFeeApi` con capturas `lastUploadProof` / `lastInvoiceLinkId` y los métodos nuevos):

```dart
test('parses proof status, is_overdue and owe', () async { /* getFee con attributes {proof_status: 'under_review', is_overdue: true, owe: 1200.5} */ });

test('uploadProof posts multipart with the proof field', () async {
  final repository = FeeRepository(_FakeFeeApi());
  await repository.uploadProof('f1', bytes: [1, 2, 3], filename: 'proof.jpg');
  final captured = (_api as _FakeFeeApi).lastUploadProof!;
  expect(captured.$1, 'f1');
  expect(captured.$2.files.first.key, 'proof');
  expect(captured.$2.files.first.value.filename, 'proof.jpg');
});

test('getInvoiceUrl returns the signed url', () async {
  // getInvoiceLink → {'data': {'url': 'https://x/fees/1/invoice-file?...'}} → retorna la url
});
```

- [ ] **Step 2: Correr y verificar que fallan**

Run: `flutter test test/fees/fee_repository_test.dart`
Expected: FAIL de compilación (campos/métodos nuevos no existen)

- [ ] **Step 3: Implementar modelo + API + repo**

- `fee_model.dart`: `@Default('') String proofStatus`, `@Default(false) bool isOverdue`, `@Default(0.0) double owe` + parse de `proof_status`, `is_overdue`, `owe` en `fromJson` (bool tolerante: `value == true || value == 1 || value == '1'`).
- `fee_api.dart`:

```dart
Future<Response> uploadProof(String feeId,
        {required List<int> bytes, required String filename}) =>
    _client.post('/fees/$feeId/upload-proof',
        data: FormData()
          ..files.add(MapEntry('proof', MultipartFile.fromBytes(bytes, filename: filename))));

Future<Response> getInvoiceLink(String feeId) =>
    _client.get('/fees/$feeId/invoice-link');
```

- `fee_repository.dart`: `uploadProof` (manejo `DioException` existente) y `getInvoiceUrl` que parsea `response.data['data']['url']?.toString() ?? ''`.
- Actualizar **los dos** fakes que implementan `FeeApi`: `test/fees/fee_repository_test.dart:12` y `test/app/fees_routes_test.dart:81` (agregar `uploadProof`/`getInvoiceLink`).
- `dart run build_runner build --delete-conflicting-outputs`.

- [ ] **Step 4: Correr y verificar que pasan**

Run: `flutter test test/fees/`
Expected: PASS (nuevos + existentes)

- [ ] **Step 5: Analyze + commit**

```bash
git add lib/features/fees/ test/fees/
git commit -m "feat(fees): modelo con estado de comprobante y subida/factura en api y repo"
```

---

### Task 6: Widget tarjeta de cuota de padres

**Files:**
- Create: `lib/features/fees/screens/widgets/parent_fee_card.dart`
- Test: `test/fees/parent_fee_card_test.dart`

**Interfaces:**
- Consumes: `FeeModel` (Task 5), tokens etapa 1 (`dangerInk`/`darkDangerInk`, `present`, `primary`, `mutedFor`), `AppFormatters.formatCurrency`.
- Produces: `ParentFeeCard({required FeeModel fee, required String childName, required VoidCallback onTap, VoidCallback? onPay})` (el call site usa `childName: fee.studentName`).

- [ ] **Step 1: Escribir los tests que fallan**

```dart
// helper _fee({status, isOverdue, proofStatus, owe, month, year})
testWidgets('renders overdue fee with danger line and pay pill', ...);
//  'Julio 2026', 'Vencido · ${AppFormatters.formatCurrency(...)}', 'Ana Pérez', tap pill → onPay
testWidgets('renders pending without danger color', ...);
testWidgets('renders partial with owed amount', ...);      // 'Parcial · debe $X'
testWidgets('renders under review from proof_status or status without action', ...); // 'En revisión · $X'; onPay null
testWidgets('renders paid with check and no action', ...); // 'Pagado' + icono check
testWidgets('unknown status falls back to muted system label', ...); // p.ej. 'cancelled' no crashea
testWidgets('tapping the card fires onTap', ...);
```

- [ ] **Step 2: Correr y verificar que fallan**

Run: `flutter test test/fees/parent_fee_card_test.dart`
Expected: FAIL (widget no existe)

- [ ] **Step 3: Implementar el widget**

`AppCard(onTap, padding 11/13)` con: `Row(Expanded(Column(título 'Julio 2026' 12/w800 `inkFor`; línea de estado 10/w700 según reglas del spec §7.2; hijo 10 `mutedFor`)), acción)`. Reglas de estado (helper privado `_FeeLine {text, color}`):
- `paid` → `Pagado` `present` (acción: icono `check` 14/w800 `present`).
- `under_review` (por `proofStatus` o `status`) → `En revisión · $monto` `primary` (sin acción).
- `isOverdue && partial` → `Parcial · debe {formatCurrency(owe)}` `dangerInk/darkDangerInk` (con pill Pagar).
- `isOverdue` → `Vencido · {formatCurrency(toPay)}` `dangerInk/darkDangerInk` (pill Pagar).
- `partial` → `Parcial · debe …` `mutedFor` (pill Pagar).
- otros (`pending` y desconocidos) → etiqueta del sistema (`feeStatusLabel`) `mutedFor` (pill Pagar si no es `cancelled`).

Pill Pagar: `Container` r9, padding h12 v6, fondo `dangerInk`/`darkDangerInk`, texto `parentPayAction` 10/w800 blanco/`darkDangerSoft`, `Material/InkWell` con `onTap: onPay`.

- [ ] **Step 4: Correr y verificar que pasan**

Run: `flutter test test/fees/parent_fee_card_test.dart`
Expected: PASS

- [ ] **Step 5: Analyze + commit**

```bash
git add lib/features/fees/screens/widgets/parent_fee_card.dart test/fees/parent_fee_card_test.dart
git commit -m "feat(fees): tarjeta de cuota con estados para padres"
```

---

### Task 7: Sheet de subida de comprobante

**Files:**
- Create: `lib/features/fees/screens/widgets/parent_fee_proof_sheet.dart`
- Test: `test/fees/parent_fee_proof_sheet_test.dart`

**Interfaces:**
- Consumes: `FeeRepository.uploadProof` (Task 5), l10n de Task 4, `PillButton`.
- Produces: `ProofUploadFile({required List<int> bytes, required String name})`; `ParentFeeProofSheet({required FeeModel fee, Future<ProofUploadFile?> Function()? pickFile})` — picker inyectable (default: `FilePicker.platform.pickFiles(type: custom, allowedExtensions: [jpg,jpeg,png,pdf], withData: true)`); `pop(true)` en éxito.

- [ ] **Step 1: Escribir los tests que fallan**

```dart
// 1) pick válido → preview con nombre + botón habilitado → subir → pop(true) y el repo recibió bytes/filename.
// 2) extensión inválida (p.ej. .exe) → error inline, sin llamar al repo.
// 3) >10MB → error inline, sin llamar al repo.
// 4) error 422 del repo → mensaje inline (feesProofError) y el sheet sigue abierto.
// 5) sin archivo → botón Subir deshabilitado.
```

- [ ] **Step 2: Correr y verificar que fallan**

Run: `flutter test test/fees/parent_fee_proof_sheet_test.dart`
Expected: FAIL (sheet no existe)

- [ ] **Step 3: Implementar el sheet**

Patrón `material_form_sheet`/`create_qualification_sheet`: `showModalBottomSheet` r16, drag handle, título `feesUploadProofAction`/`feesReplaceProofAction` (según `under_review`), línea de contexto (mes · hijo · monto), botón `feesProofPickFile` con `OutlinedButton`/`AppCard`, hint `feesProofHint`, preview (nombre + tamaño en KB/MB), `PillButton` Subir con `isLoading`. Validación cliente: extensión ∈ {jpg,jpeg,png,pdf} y `bytes.length <= 10 * 1024 * 1024`. Éxito: `Navigator.pop(context, true)`.

- [ ] **Step 4: Correr y verificar que pasan**

Run: `flutter test test/fees/parent_fee_proof_sheet_test.dart`
Expected: PASS

- [ ] **Step 5: Analyze + commit**

```bash
git add lib/features/fees/screens/widgets/parent_fee_proof_sheet.dart test/fees/parent_fee_proof_sheet_test.dart
git commit -m "feat(fees): sheet para subir comprobante de pago"
```

---

### Task 8: `ParentFeesScreen` (pantalla Pagos)

**Files:**
- Create: `lib/features/fees/screens/parent_fees_screen.dart`
- Create: `test/fees/parent_fees_screen_test.dart`

**Interfaces:**
- Consumes: `parentFeesProvider` (**nuevo**, mismo `FeeListNotifier` sin filtros: `StateNotifierProvider<FeeListNotifier, FeeListState>((ref) => FeeListNotifier(ref.watch(feeRepositoryProvider)))`), `dashboardProvider` (mora), `ParentFeeCard` (Task 6), `ParentFeeProofSheet` (Task 7), `PillButton`.
- Produces: `ParentFeesScreen` (usada por Task 10 en `/payments`); navega a `/payments/{feeId}`.

- [ ] **Step 1: Escribir los tests que fallan**

Scaffold: fakes de auth/dashboard + `feeRepositoryProvider` override con lista fake; pump con `MaterialApp` + GoRouter plano con ruta dummy `/payments/:id` → `Text('fee:${id}')`.

```dart
// 1) muestra mora total del dashboard en el header; oculta el tile si mora 0.
// 2) lista los fee cards en el orden del provider (vencida, pendiente, pagada).
// 3) tap en card y en pill → fee:<id>.
// 4) CTA: con 1 accionable → abre el sheet directo (encuentra feesUploadProofAction);
//    con 2+ → abre 'Elegí la cuota' → elegir → sheet;
//    con 0 accionables → CTA oculta.
// 5) vacío → EmptyState (feesEmptyTitle); error → ErrorView con retry; loading → shimmer.
// 6) dark mode sin excepciones.
```

- [ ] **Step 2: Correr y verificar que fallan**

Run: `flutter test test/fees/parent_fees_screen_test.dart`
Expected: FAIL (pantalla no existe)

- [ ] **Step 3: Implementar la pantalla**

Estructura: `Scaffold` → `Column`:
1. Header: `GradientHeader(child: Column(título 'Cuotas' 14/w800 `onPrimary`; tile mora: `Container` overlay 12%, r14, padding 12/14, centrado: label `parentMoraTotal` 10 `onPrimaryMuted` + monto 22/w900 `onPrimary` — oculto si mora 0 o sin dato))`.
2. `Expanded(RefreshIndicator(lista))`: scroll controller + `loadMore`; estados: shimmer (3 `LoadingShimmer` 68/16), `ErrorView(feesLoadError, retry)`, `EmptyState(feesEmptyTitle)`, cards (`ParentFeeCard(fee: f, childName: f.studentName, …)`) con gap 9.
3. CTA: si `accionables.isNotEmpty` → `Padding(PillButton(feesUploadProofAction))`; `accionables = fees.where((f) => f.status != 'paid' && !_isUnderReview(f))`.
   - 1 accionable → `showModalBottomSheet(ParentFeeProofSheet(fee: …))`; al `pop(true)` → snackbar `feesProofSuccess` + `ref.read(parentFeesProvider.notifier).refresh()`.
   - 2+ → `_FeePickerSheet` (privado; filas hijo · mes/año · monto/estado) → sheet de subida.
4. Pull-to-refresh: `parentFeesProvider.refresh()` + `dashboardProvider.refresh()`.

- [ ] **Step 4: Correr y verificar que pasan**

Run: `flutter test test/fees/parent_fees_screen_test.dart`
Expected: PASS

- [ ] **Step 5: Analyze + commit**

```bash
git add lib/features/fees/screens/parent_fees_screen.dart lib/features/fees/providers/fee_provider.dart test/fees/parent_fees_screen_test.dart
git commit -m "feat(fees): pantalla Pagos de padres con mora, lista y subida de comprobante"
```

---

### Task 9: `ParentFeeDetailScreen`

**Files:**
- Create: `lib/features/fees/screens/parent_fee_detail_screen.dart`
- Test: `test/fees/parent_fee_detail_screen_test.dart`

**Interfaces:**
- Consumes: `feeDetailProvider` (existente), `ParentFeeProofSheet` (Task 7), `FeeRepository.getInvoiceUrl` (Task 5), `ScreenHeader`, `url_launcher`.
- Produces: `ParentFeeDetailScreen({required String feeId, Future<bool> Function(Uri)? openUrl})` (launcher inyectable para tests; default `launchUrl(uri, mode: externalApplication)`).

- [ ] **Step 1: Escribir los tests que fallan**

```dart
// 1) cuota pendiente: muestra montos/estado y botón 'Subir comprobante' (sin 'Ver factura').
// 2) cuota under_review: botón 'Reemplazar comprobante' + fila 'Comprobante en revisión'.
// 3) cuota pagada: 'Ver factura' visible y subir oculto; tap factura → openUrl recibe la url del repo.
// 4) factura 404 (repo lanza ApiException 404) → snackbar 'Factura no disponible', sin crash.
// 5) subida exitosa → invalida detalle y lista (el repo de detalle se vuelve a pedir).
```

- [ ] **Step 2: Correr y verificar que fallan**

Run: `flutter test test/fees/parent_fee_detail_screen_test.dart`
Expected: FAIL (pantalla no existe)

- [ ] **Step 3: Implementar la pantalla**

`Scaffold` → `Column(ScreenHeader(feesDetailTitle(number)), Expanded(...))`: card con filas (hijo, mes/año, estado con badge, a pagar/pagado/total, debe si `owe > 0`, comprobante si `under_review`, método/fecha si pagada) + acciones al pie: `PillButton` subir/reemplazar (si no pagada; al `pop(true)` → snackbar `feesProofSuccess` + `ref.invalidate(feeDetailProvider(feeId))` + `ref.invalidate(parentFeesProvider)`) y botón `feesInvoiceAction` (si pagada; `getInvoiceUrl` → `openUrl`; 404 → snackbar `feesInvoiceUnavailable`).

- [ ] **Step 4: Correr y verificar que pasan**

Run: `flutter test test/fees/parent_fee_detail_screen_test.dart`
Expected: PASS

- [ ] **Step 5: Analyze + commit**

```bash
git add lib/features/fees/screens/parent_fee_detail_screen.dart test/fees/parent_fee_detail_screen_test.dart
git commit -m "feat(fees): detalle de cuota de padres con comprobante y factura"
```

---

### Task 10: Routing — `/payments` nueva pantalla + `/payments/:id`

**Files:**
- Modify: `lib/app/router.dart`
- Modify: `test/app/bottom_nav_test.dart`

**Interfaces:**
- Consumes: `ParentFeesScreen` (Task 8), `ParentFeeDetailScreen` (Task 9), `parentFeesProvider` (Task 8).
- Produces: `/payments` → `ParentFeesScreen`; `/payments/:id` anidada (push dentro del branch 1); el resto de rutas intactas.

- [ ] **Step 1: Actualizar/agregar tests que fallan**

En `test/app/bottom_nav_test.dart`: cambiar la expectativa del test de Pagos a `find.byType(ParentFeesScreen)` y sumar `parentFeesProvider.overrideWith((ref) => FeeListNotifier(_FakeFeeRepository()))`; extender `_FakeFeeRepository` con `getFee` (devuelve un FeeModel de prueba). Test nuevo:

```dart
testWidgets('parent opens fee detail from Pagos and keeps the tab', (tester) async {
  await _pumpApp(tester, 'parent');
  await tester.tap(navLabel('Pagos'));
  await tester.pumpAndSettle();
  await tester.tap(find.byType(ParentFeeCard).first);
  await tester.pumpAndSettle();
  expect(find.byType(ParentFeeDetailScreen), findsOneWidget);
  // el pill activo sigue en 'Pagos'
  final pill = tester.widget<AnimatedContainer>(find.ancestor(
      of: navLabel('Pagos'), matching: find.byType(AnimatedContainer)));
  expect((pill.decoration as BoxDecoration).color, AppColors.primary);
});
```

- [ ] **Step 2: Correr y verificar que fallan**

Run: `flutter test test/app/bottom_nav_test.dart`
Expected: FAIL (ruta `/payments/:id` y pantalla nueva no cableadas)

- [ ] **Step 3: Implementar en `lib/app/router.dart`**

En el branch 1: `/payments` pasa a `builder: (context, state) => const ParentFeesScreen()` con child:

```dart
GoRoute(
  path: ':id',
  builder: (context, state) => ParentFeeDetailScreen(
    feeId: state.pathParameters['id']!,
  ),
),
```

- [ ] **Step 4: Correr y verificar que pasan**

Run: `flutter test test/app/bottom_nav_test.dart && flutter analyze`
Expected: PASS y sin issues nuevos

- [ ] **Step 5: Commit**

```bash
git add lib/app/router.dart test/app/bottom_nav_test.dart
git commit -m "feat(nav): pantalla Pagos de padres y detalle en la ruta /payments/:id"
```

---

### Task 11: Limpieza de `FeeListScreen` + cierre de suite

**Files:**
- Modify: `lib/features/fees/screens/fee_list_screen.dart`
- Delete: `test/fees/fee_parent_scope_widget_test.dart`
- Test: `test/fees/fee_list_notifier_test.dart` / `fee_repository_test.dart` (verificar que siguen verdes)

**Interfaces:**
- Consumes: pantallas nuevas (Tasks 8/9) ya cubren el flujo de padres.
- Produces: `FeeListScreen` sin ramas de padre (queda con búsqueda para los demás roles); `parentSelectedStudentProvider` conservado solo para el listado de aulas.

- [ ] **Step 1: Eliminar las ramas de padre de `fee_list_screen.dart`**

Quitar: el `ref.listen` de `parentSelectedStudentProvider` y el sync post-build, el `_buildParentChildSelector()`, la condición `isParent && state.studentId == null` del empty state y los imports que queden sin uso (`authProvider` solo si ya no se usa; `relations`/`selected_child` providers). La búsqueda y el resto quedan igual.

- [ ] **Step 2: Borrar el test viejo del selector**

```bash
git rm test/fees/fee_parent_scope_widget_test.dart
```

- [ ] **Step 3: Correr la suite completa y analyze**

Run: `flutter test`
Expected: PASS (los casos nuevos de Tasks 6-10 reemplazan la cobertura del selector)
Run: `flutter analyze`
Expected: sin issues nuevos

- [ ] **Step 4: Commit**

```bash
git add -A
git commit -m "refactor(fees): quitar ramas de padre del listado generico (los padres usan Pagos)"
```

---

## Cierre

- [ ] **Verificación final (móvil):** `flutter gen-l10n && flutter analyze && flutter test` → todo verde.
- [ ] **Verificación final (backend):** `php -l` + `pint --test` + tinkers de Tasks 1-3 (sin Pest).
- [ ] **Regresión manual sugerida:** padre (Pagos: orden, mora, subir/reemplazar comprobante, factura; home intacto), admin (listado de cuotas con cursor intacto), profesor/estudiante sin cambios.
