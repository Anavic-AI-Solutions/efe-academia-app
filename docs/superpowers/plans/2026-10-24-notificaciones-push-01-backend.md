# Notificaciones Push — Plan 1: Backend (`efe-app`) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Todas las notificaciones del backend se emiten exactamente una vez por FCM (teléfono) y Reverb (PC), con el canal FCM operativo (hoy roto: 21k jobs fallidos).

**Architecture:** `NotificationService::deliver()` es el emisor único (Reverb `UserNotificationSent` + FCM en cola). Los flujos que hoy solo usan `$user->notify(...)` (WebPush/email) pasan a emitir además vía `NotificationService::sendCopy()`, que reutiliza el copy de cada clase de notificación sin duplicar emisiones en los flujos que ya están pareados.

**Tech Stack:** Laravel 11 (PHP 8.2), `laravel-notification-channels/fcm` **5.1.0** (instalado), `kreait/firebase-php` 7.24.1, cola `database`, Pest + PHPUnit en `tests/`.

**Spec:** `docs/superpowers/specs/2026-10-23-notificaciones-push-telefono-pc-design.md` (repo `efe_mobile`; este plan argumenta desde él).

**Workdir de todas las tareas:** `/opt/dev/efe-app` (repo del backend). El plan se guarda y commitea en `efe_mobile`.

## Global Constraints

- **Sin dependencias composer nuevas**: todo lo necesario ya está instalado (fcm 5.1.0, kreait 7.24.1).
- **`vendor/bin/pint` limpio antes de cada commit** (convención del repo).
- **Un solo emisor por evento**: `NotificationService::sendCopy()` NUNCA se añade donde ya existe `NotificationService::send()` en el mismo flujo. Flujos pareados existentes (no tocar): `AbsencesController` (create + justificación), `NotifyUpcomingEvents`, `ChatService::notifyParticipants`, `StudentDataController` upload, `StudentData/ParentData` otros flows con `send()` vecino.
- **`job_type` exactos permitidos para lo nuevo**: `'general'`, `'académico'`, `'pago'`. Jamás `JobNotification::SYSTEM_TYPES` (`pdf_generation`, `bulk_billing`, `payment_proof`, `arca_rejection`) — esas filas quedan fuera de la lista de la app (`scopeApp`).
- **Orden obligatorio**: crear la notificación **antes** de `->delete()` de usuarios (flujos de rechazo; `User` usa SoftDeletes y la fila sobrevive).
- **FCM va en cola** (`QUEUE_CONNECTION=database`): no enviar síncrono en código de producción; `sendNow` solo en diagnóstico.
- Web push (navegador) e iOS: **fuera de alcance** (spec D5/D6).

## Review Focus

Las siguientes cinco fallas son las que el spec implica y que más van a doler; cada línea queda sujeta al test indicado en su tarea:

1. **Payload FCM pierde `android.priority: high`** → segundo plano Android no entrega de forma fiable → test `toFcm builds notification, data and platform config for fcm v5` (Task 1) afirma `$arr['android']['priority'] === 'high'`.
2. **Doble push en flujos pareados** (añadir `sendCopy` donde ya hay `send()` → dos avisos idénticos) → test `flujos ya pareados no duplican avisos` (Task 4A) afirma `count === 1` tras `events:notify-upcoming`.
3. **El listener de tokens borra tokens válidos en un error transitorio** (FCM caído → se pierde registro del teléfono para siempre) → test `conserva el token ante errores no permanentes` (Task 5) afirma que la fila sigue existiendo.
4. **Tipos nuevos quedan invisibles en la lista de la app** (elegir `job_type` de sistema) → test `aviso de cuota vencida es visible en scopeApp` (Task 4B) afirma que `JobNotification::app()` incluye la fila.
5. **La purga de `failed_jobs` borra jobs ajenos a notificaciones** → pasos 2–4 de Task 2 registran y comparan el conteo de `other` (payload sin `FcmPushNotification`/`WebPushAlert`): debe quedar idéntico.

## File Structure

| Acción | Archivo | Responsabilidad |
|---|---|---|
| Create | `tests/Unit/FcmPushNotificationTest.php` | Contrato del payload FCM v5 |
| Modify | `app/Notifications/FcmPushNotification.php` | `toFcm()` a API 5.1.0 |
| Modify | `.env.example` | Claves FCM de referencia |
| Create | `app/Notifications/ProvidesAppCopy.php` | Interfaz copy {title, body, url} |
| Modify | `app/Notifications/BaseAppNotification.php` | `implements ProvidesAppCopy` |
| Modify | `app/Notifications/FeeOverdueReminder.php` | Copy propio (hoy standalone) |
| Modify | `app/Services/NotificationService.php` | `sendCopy()` + espejo (Task 6) |
| Modify | `app/Jobs/SendBroadcastNotificationJob.php` | Emitir por `sendCopy` |
| Modify | `app/Http/Controllers/TicketsController.php` | Ídem |
| Modify | `app/Http/Controllers/StudentDataController.php` | Ídem (aprobar/rechazar) |
| Modify | `app/Http/Controllers/ParentDataController.php` | Ídem (aprobar/rechazar) |
| Modify | `app/Console/Commands/SendFeeOverdueReminders.php` | Ídem |
| Modify | `app/Jobs/SyncNotionJob.php`, `app/Jobs/SyncNotionCommentsJob.php` | Ídem |
| Modify | `app/Http/Controllers/System/SystemCollectionsFeesPaymentController.php` | Ídem (`paidFee`) |
| Create | `app/Listeners/CleanupInvalidFcmToken.php` | Borra tokens inválidos reportados |
| Modify | `app/Providers/AppServiceProvider.php` | Registra el listener |
| Create | `tests/Feature/NotificationSendCopyTest.php`, `tests/Feature/SendCopyFlowsTest.php`, `tests/Feature/SendCopyFlowsPartBTest.php`, `tests/Feature/CleanupInvalidFcmTokenTest.php`, `tests/Feature/AppNotificationMirrorTest.php` | Tests por tarea |

---

### Task 1: `FcmPushNotification` compatible con `laravel-notification-channels/fcm` 5.1.0

**Contexto (ya diagnosticado):** la clase importa `Resources\AndroidConfig`, `Resources\ApnsConfig` y `Resources\AndroidNotification` que **no existen en 5.1.0** (el paquete solo trae `FcmChannel`, `FcmMessage`, `Resources\FcmResource`, `Resources\Notification`). Cada invocación de `toFcm()` revienta con `Class not found` → 21k jobs fallidos. En 5.1.0 la config de plataforma va por `FcmMessage::custom()` (README del paquete).

**Files:**
- Create: `tests/Unit/FcmPushNotificationTest.php`
- Modify: `app/Notifications/FcmPushNotification.php`
- Modify: `.env.example`

**Interfaces:**
- Produces: `FcmPushNotification::toFcm($notifiable): FcmMessage` con `data = ['url','type','notification_id']` (string) y `custom = ['android' => ['priority' => 'high', 'notification' => ['sound' => 'default']], 'apns' => ['payload' => ['aps' => [...]]]]`. Tasks 2 y posteriores dependen de que este payload sea válido para `sendMulticast`.

- [x] **Step 1: Escribir el test fallido**

```php
<?php

use App\Notifications\FcmPushNotification;
use NotificationChannels\Fcm\FcmMessage;

test('toFcm builds notification, data and platform config for fcm v5', function () {
    $n = new FcmPushNotification('Nuevo mensaje de Ana', 'Hola, ¿llegas?', '/platform/chats/7', 'general', 42);
    $msg = $n->toFcm(null);

    expect($msg)->toBeInstanceOf(FcmMessage::class);
    $arr = $msg->toArray();
    expect($arr['notification']['title'])->toBe('Nuevo mensaje de Ana')
        ->and($arr['notification']['body'])->toBe('Hola, ¿llegas?')
        ->and($arr['data'])->toBe([
            'url' => '/platform/chats/7',
            'type' => 'general',
            'notification_id' => '42',
        ])
        ->and($arr['android']['priority'])->toBe('high')
        ->and($arr['android']['notification']['sound'])->toBe('default')
        ->and($arr['apns']['payload']['aps']['alert']['title'])->toBe('Nuevo mensaje de Ana')
        ->and($arr['apns']['payload']['aps']['alert']['body'])->toBe('Hola, ¿llegas?')
        ->and($arr['apns']['payload']['aps']['badge'])->toBe(1)
        ->and($arr['apns']['payload']['aps']['sound'])->toBe('default');
});
```

- [x] **Step 2: Correr y verificar que falla**

Run: `php artisan test --filter="toFcm builds notification"`
Expected: FAIL con `Class "NotificationChannels\Fcm\Resources\AndroidConfig" not found`.

- [x] **Step 3: Reescribir `toFcm()` a la API de 5.1.0**

En `app/Notifications/FcmPushNotification.php`: eliminar los imports `Resources\AndroidConfig`, `Resources\ApnsConfig`, `Resources\AndroidNotification` (mantener `Resources\Notification as FcmNotification` y `Notification as FcmNotification` — dejar solo un alias `FcmNotification` sin conflicto). Reemplazar los encadenamientos `->setAndroid(...)`/`->setApns(...)` por:

```php
->custom([
    'android' => [
        'priority' => 'high',
        'notification' => ['sound' => 'default'],
    ],
    'apns' => [
        'payload' => ['aps' => [
            'alert' => ['title' => $this->title, 'body' => $this->body],
            'badge' => 1,
            'sound' => 'default',
        ]],
    ],
])
```

El bloque `->data([...])` con `url/type/notification_id` **se mantiene igual**.

- [x] **Step 4: Correr y verificar que pasa**

Run: `php artisan test --filter="toFcm builds notification"`
Expected: PASS.

- [x] **Step 5: Completar `.env.example`**

Agregar (valores no secretos; el JSON de credenciales es gitignored):

```
FCM_PROJECT_ID=efe-app-d3d42
FCM_CREDENTIALS=storage/firebase-credentials.json
FIREBASE_CREDENTIALS=storage/firebase-credentials.json
```

- [x] **Step 6: Pint y commit**

```bash
vendor/bin/pint app/Notifications/FcmPushNotification.php tests/Unit/FcmPushNotificationTest.php
git add app/Notifications/FcmPushNotification.php tests/Unit/FcmPushNotificationTest.php .env.example
git commit -m "fix(notifications): adaptar FcmPushNotification a la API v5.1 de laravel-notification-channels/fcm"
```

---

### Task 2: Diagnóstico, purga de `failed_jobs` y verificación de envío real

Tarea operativa sin cambios de código: confirma la causa raíz en la cola real, purga **solo** jobs de notificaciones (decisión del plan: **purgar, no reintentar** — reintentar jobs de meses reenviaría avisos viejos a usuarios), verifica credenciales y ejercita el pipeline completo de FCM. Se corre en el entorno donde vive la cola (preprod/producción), no en la laptop.

**Files:** sin cambios en repo (si algún paso difiere del resultado esperado, detener y reportar).

**Interfaces:**
- Consumes: `FcmPushNotification::toFcm()` de Task 1; `FcmToken::registerForUser($user, $token, $platform, $deviceId)` (existente); `config('firebase.credentials')`.

- [x] **Step 1: Confirmar causa raíz en la cola**

Run (tinker; una línea):
```bash
php artisan tinker --execute='DB::table("failed_jobs")->selectRaw("substring(exception from 1 for 140) e, count(*) c")->where("payload","like","%FcmPushNotification%")->groupBy("e")->orderByDesc("c")->limit(10)->get()->each(fn($r) => print $r->e." | ".$r->c."\n");'
```
Expected: líneas con `AndroidConfig not found` (coincide con el diagnóstico de Task 1). Si el error es otro (p. ej. credenciales), detener y reportar antes de purgar.

- [x] **Step 2: Registrar conteos antes de la purga**

```bash
php artisan tinker --execute='print "notif=".DB::table("failed_jobs")->where("payload","like","%FcmPushNotification%")->orWhere("payload","like","%WebPushAlert%")->count()." other=".DB::table("failed_jobs")->where("payload","not like","%FcmPushNotification%")->where("payload","not like","%WebPushAlert%")->count()."\n";'
```
Anotar ambos números (`other` es el test de la Review Focus 5).

- [x] **Step 3: Purgar solo jobs de notificaciones**

```bash
php artisan tinker --execute='print DB::table("failed_jobs")->where("payload","like","%FcmPushNotification%")->orWhere("payload","like","%WebPushAlert%")->delete()[0]." purged\n";'
```

- [x] **Step 4: Verificar la purga**

Repite el Step 2. Expected: `notif=0` y `other` **idéntico** al anotado.

- [x] **Step 5: Verificar credenciales de Firebase**

```bash
php artisan tinker --execute='var_dump(file_exists(config("firebase.credentials")));'
```
Expected: `bool(true)`. Si `false` → **bloqueo**: pedir al usuario el JSON de cuenta de servicio de Firebase (consola → Cuentas de servicio del proyecto `efe-app-d3d42`) y ubicarlo en `storage/firebase-credentials.json`; no continuar hasta tenerlo.

- [x] **Step 6: Verificar el worker de la cola**

Run: `ps aux | grep -E "queue:work|queue:listen" | grep -v grep`
Expected: al menos un worker vivo (FCM va en cola `database`: sin worker no llega nada). Si no corre, levantarlo (supervisor/systemd del server) y anotarlo en el reporte.

- [ ] **Step 7: Envío real end-to-end sin dispositivo** _(pendiente de deploy del fix de Task 1; re-ejecutar tras deploy)_

Crear token de diagnóstico y enviar síncrono (un token inválido produce `NotificationFailed` — esperado, no debe lanzar excepción):

```bash
php artisan tinker --execute='
$u = App\Models\User::orderBy("id")->first();
App\Models\FcmToken::registerForUser($u, "diagnostico-token-".uniqid(), "android", "diag-".uniqid());
Illuminate\Support\Facades\Notification::sendNow($u, new App\Notifications\FcmPushNotification("Prueba EFE", "Diagnostico de canal FCM", "/platform/notifications", "general", 0));
print "envio sin excepcion\n";
App\Models\FcmToken::where("token", "like", "diagnostico-token-%")->delete();
'
```
Expected: `envio sin excepcion` (si tira excepción de credenciales/vía, revertir al Step 5). Esta ejecución prueba `toFcm()` + kreait + credenciales reales. Alternativa en entorno con dispositivo: `GET /test-push` (`routes/web.php`, ya existe).

- [x] **Step 8: Reportar resultados**

Sin commit. Si la causa raíz del Step 1 no coincidió, detener el plan y reportar.

---

### Task 3: Interfaz `ProvidesAppCopy` y `NotificationService::sendCopy()`

Centraliza "copy de cada notificación" para que los sitios de la Task 4A/4B sean de una línea, sin tocar la visibilidad de métodos en 10 subclases.

**Files:**
- Create: `app/Notifications/ProvidesAppCopy.php`
- Modify: `app/Notifications/BaseAppNotification.php`
- Modify: `app/Notifications/FeeOverdueReminder.php`
- Modify: `app/Services/NotificationService.php`
- Create: `tests/Feature/NotificationSendCopyTest.php`

**Interfaces:**
- Consumes: `NotificationService::send(User|Collection|array $recipients, string $title, string $body, string $url = '/', string $type = 'general', array $extra = [])` (existente).
- Produces:
  - `interface App\Notifications\ProvidesAppCopy { /** @return array{title: string, body: string, url: string} */ public function appNotificationCopy(): array; }`
  - `BaseAppNotification implements ProvidesAppCopy` (delega a sus `getTitle()/getBody()/getUrl()` protegidos).
  - `FeeOverdueReminder implements ProvidesAppCopy`.
  - `NotificationService::sendCopy(User|Collection|array $recipients, ProvidesAppCopy $notification, string $type): void`.
  Las Tasks 4A y 4B usan exactamente estas firmas.

- [x] **Step 1: Escribir los tests fallidos**

```php
<?php

use App\Events\UserNotificationSent;
use App\Models\JobNotification;
use App\Models\SystemCollectionsFees;
use App\Models\User;
use App\Notifications\FeeOverdueReminder;
use App\Notifications\NewRequest;
use App\Services\NotificationService;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Event;

uses(RefreshDatabase::class);

test('sendCopy crea una notificación con el copy de la clase y el tipo dado', function () {
    Event::fake([UserNotificationSent::class]);
    $user = User::factory()->create();

    app(NotificationService::class)->sendCopy($user, new NewRequest(null, 'approved', 'student'), 'general');

    $row = JobNotification::where('user_id', $user->id)->firstOrFail();
    expect($row->job_type)->toBe('general')
        ->and($row->title)->toBe('¡Solicitud Aprobada!')
        ->and($row->message)->toBe('Tu solicitud de ingreso ha sido aprobada. ¡Bienvenido/a!')
        ->and($row->metadata['url'])->toBe('/dashboard');
});

test('FeeOverdueReminder expone su copy para push', function () {
    $fee = new SystemCollectionsFees;
    $fee->month = 3;
    $fee->year = 2026;
    $fee->amount_owed = 15000;

    $copy = (new FeeOverdueReminder($fee))->appNotificationCopy();

    expect($copy['title'])->toBe('Cuota vencida - Marzo 2026')
        ->and($copy['body'])->toContain('$15.000')
        ->and($copy['url'])->toBe('/fees');
});
```

- [x] **Step 2: Correr y verificar que fallan**

Run: `php artisan test --filter=NotificationSendCopyTest`
Expected: FAIL (clase/método inexistente: `appNotificationCopy` / `sendCopy`).

- [x] **Step 3: Implementar la interfaz y el método en la base**

Crear `app/Notifications/ProvidesAppCopy.php` con la interfaz de **Interfaces → Produces**. En `BaseAppNotification`: `abstract class BaseAppNotification extends Notification implements ShouldQueue, ProvidesAppCopy` y agregar:

```php
public function appNotificationCopy(): array
{
    return ['title' => $this->getTitle(), 'body' => $this->getBody(), 'url' => $this->getUrl()];
}
```

- [x] **Step 4: Implementar el copy en `FeeOverdueReminder`**

`FeeOverdueReminder ... implements ProvidesAppCopy` con copy **exacto** (extraído del `toWebPush` actual, misma copy):

```php
public function appNotificationCopy(): array
{
    $monthName = \Carbon\Carbon::create()->month($this->fee->month)->locale('es')->monthName;
    return [
        'title' => 'Cuota vencida - '.ucfirst($monthName).' '.$this->fee->year,
        'body' => 'Tenés una cuota pendiente de $'.number_format($this->fee->amount_owed, 2, ',', '.').'. Ingresá para regularizarla.',
        'url' => '/fees',
    ];
}
```

Refactor DRY: `toWebPush()` usa `$copy = $this->appNotificationCopy()` para `title()`, `body()` y `data(['url' => $copy['url']])`. `toMail()` queda como está (YAGNI).

- [x] **Step 5: Implementar `NotificationService::sendCopy()`**

```php
public function sendCopy(User|Collection|array $recipients, ProvidesAppCopy $notification, string $type): void
{
    $copy = $notification->appNotificationCopy();
    $this->send($recipients, $copy['title'], $copy['body'], $copy['url'], $type);
}
```

(import `App\Notifications\ProvidesAppCopy` al head del archivo.)

- [x] **Step 6: Correr y verificar que pasan**

Run: `php artisan test --filter=NotificationSendCopyTest`
Expected: PASS (ambos).

- [x] **Step 7: Pint y commit**

```bash
vendor/bin/pint app/Notifications app/Services/NotificationService.php tests/Feature/NotificationSendCopyTest.php
git add app/Notifications/ProvidesAppCopy.php app/Notifications/BaseAppNotification.php app/Notifications/FeeOverdueReminder.php app/Services/NotificationService.php tests/Feature/NotificationSendCopyTest.php
git commit -m "feat(notifications): ProvidesAppCopy y NotificationService::sendCopy para emisión única"
```

---

### Task 4A: `sendCopy()` en avisos, tickets y solicitudes

**Files:**
- Modify: `app/Jobs/SendBroadcastNotificationJob.php`, `app/Http/Controllers/TicketsController.php`, `app/Http/Controllers/StudentDataController.php`, `app/Http/Controllers/ParentDataController.php`
- Create: `tests/Feature/SendCopyFlowsTest.php`

**Interfaces:**
- Consumes: `NotificationService::sendCopy(ProvidesAppCopy, string $type)` de Task 3.
- Produces: los 4 flujos emiten `job_notifications` con `job_type = 'general'`; nada de esta tarea cambia firmas para otros tasks.

- [x] **Step 1: Escribir los tests fallidos**

`tests/Feature/SendCopyFlowsTest.php` (imports: factories/modelos/jobs usados, `Event::fake([UserNotificationSent::class])` en cada test; helper local `makeAdmin()` con el cuerpo de `createAdminForNotifications()` de `tests/Feature/Api/NotificationsTest.php`):

```php
test('broadcast escolar crea aviso push para estudiante y padre', function () {
    Event::fake([UserNotificationSent::class]);
    $classroom = ClassroomsFactory::create();
    $studentUser = User::factory()->create();
    $parentUser = User::factory()->create();
    $student = StudentDataFactory::create(['user_id' => $studentUser->id, 'status' => 'approved']);
    $parent = ParentDataFactory::create(['user_id' => $parentUser->id]);
    $student->parents()->attach($parent->id);
    $classroom->students()->attach($student->id);
    $broadcast = NotificationsFactory::create();

    (new SendBroadcastNotificationJob([$classroom->id], $broadcast))->handle();

    expect(JobNotification::where('user_id', $studentUser->id)->where('job_type', 'general')->count())->toBe(1)
        ->and(JobNotification::where('user_id', $parentUser->id)->where('job_type', 'general')->count())->toBe(1)
        ->and(JobNotification::where('user_id', $studentUser->id)->value('title'))->toBe($broadcast->title);
});

test('crear ticket dispara aviso push a los admins', function () {
    Event::fake([UserNotificationSent::class]);
    $admin = makeAdmin();
    $studentUser = User::factory()->create();
    StudentDataFactory::create(['user_id' => $studentUser->id, 'status' => 'approved']);

    $this->actingAs($studentUser)->post('/platform/tickets', ['type' => 'soporte', 'message' => 'No puedo ingresar'])
        ->assertRedirect(route('tickets.index'));

    expect(JobNotification::where('user_id', $admin->id)->where('job_type', 'general')->count())->toBe(1)
        ->and(JobNotification::where('user_id', $admin->id)->value('title'))->toBe('Nueva consulta recibida');
});

test('aprobar solicitud de estudiante avisa al estudiante', function () {
    Event::fake([UserNotificationSent::class]);
    $admin = makeAdmin();
    $studentUser = User::factory()->create();
    $student = StudentDataFactory::create(['user_id' => $studentUser->id, 'status' => 'pending']);
    $classroom = ClassroomsFactory::create();

    $this->actingAs($admin)->post("/platform/requests/student/approve/{$student->id}", ['classroom_id' => $classroom->id]);

    expect(JobNotification::where('user_id', $studentUser->id)->where('job_type', 'general')->count())->toBe(1);
});

test('rechazar solicitud de estudiante avisa antes de borrar el usuario', function () {
    Event::fake([UserNotificationSent::class]);
    $admin = makeAdmin();
    $studentUser = User::factory()->create();
    $student = StudentDataFactory::create(['user_id' => $studentUser->id, 'status' => 'pending']);

    $this->actingAs($admin)->post("/platform/requests/student/reject/{$student->id}");

    expect($studentUser->fresh()->trashed())->toBeTrue()
        ->and(JobNotification::where('user_id', $studentUser->id)->where('job_type', 'general')->count())->toBe(1);
});

test('aprobar solicitud de padre avisa al padre', function () {
    Event::fake([UserNotificationSent::class]);
    $admin = makeAdmin();
    $parentUser = User::factory()->create();
    $parent = ParentDataFactory::create(['user_id' => $parentUser->id, 'status' => 'pending']);
    $student = StudentDataFactory::create(['status' => 'approved']);
    $parent->students()->attach($student->id);

    $this->actingAs($admin)->post("/platform/requests/parent/approve/{$parent->id}");

    expect(JobNotification::where('user_id', $parentUser->id)->where('job_type', 'general')->count())->toBe(1);
});

test('rechazar solicitud de padre avisa al padre antes de borrarlo', function () {
    Event::fake([UserNotificationSent::class]);
    $admin = makeAdmin();
    $parentUser = User::factory()->create();
    $parent = ParentDataFactory::create(['user_id' => $parentUser->id, 'status' => 'pending']);

    $this->actingAs($admin)->post("/platform/requests/parent/reject/{$parent->id}");

    expect($parentUser->fresh()->trashed())->toBeTrue()
        ->and(JobNotification::where('user_id', $parentUser->id)->where('job_type', 'general')->count())->toBe(1);
});

test('flujos ya pareados no duplican avisos', function () {
    Event::fake([UserNotificationSent::class]);
    $user = User::factory()->create();
    EventsFactory::create(['start_date' => now()->addDay(), 'visibility' => 'all', 'branch_name' => null]);

    $this->artisan('events:notify-upcoming');

    expect(JobNotification::where('user_id', $user->id)->count())->toBe(1);
});
```

Notas para el implementador: `makeAdmin()` es la copia del helper ya citado; si `StoreTicketsRequest` o las rutas exigen campos extra, leer el FormRequest y usar esos campos (los tests de rutas web usan `actingAs` sin CSRF).

- [x] **Step 2: Correr y verificar que fallan**

Run: `php artisan test --filter=SendCopyFlowsTest`
Expected: 7 tests FAIL (no existen filas `job_notifications`; el de duplicados pasa desde ya — debe seguir pasando tras el cambio, es la Review Focus 2).

- [x] **Step 3: Insertar `sendCopy` en los 4 flujos**

Patrón en todos: **misma instancia** para `notify()` y `sendCopy()`, dentro de los `try` existentes, `app(\App\Services\NotificationService::class)` (o import) y tipo `'general'`:

1. `SendBroadcastNotificationJob::handle()` — en cada rama (estudiante y padre), reemplazar `$student->user->notify(new NewNotificationBroadcast($this->notification));` por:
```php
$notif = new NewNotificationBroadcast($this->notification);
$student->user->notify($notif);
app(\App\Services\NotificationService::class)->sendCopy($student->user, $notif, 'general');
```
(mismo patrón en la rama `$parent->user`).
2. `TicketsController::store()` — después del `foreach ($admins ...)`, dentro del `try`:
```php
app(\App\Services\NotificationService::class)->sendCopy($admins, new NewTicketMessage($ticket, 'student'), 'general');
```
3. `StudentDataController::requestsApprove()` — tras cada `notify(new NewRequest(... 'approved' ...))`, con la misma instancia:
```php
$req = new NewRequest(null, 'approved', 'student');
$student->user->notify($req);
app(\App\Services\NotificationService::class)->sendCopy($student->user, $req, 'general');
```
(idem bloque padre con `('approved', 'parent')`.)
4. `StudentDataController::requestsReject()` — mismo patrón con `('rejected', 'student')` y `sendCopy` **antes** de `$student->user->delete();`.
5. `ParentDataController::requestsApprove()` — bloque `$parent->user` con `('approved', 'parent')`.
6. `ParentDataController::requestsReject()` — rama estudiante (`('rejected','student')`, sendCopy antes del delete) y bloque padre (`('rejected','parent')`, sendCopy antes del delete).

- [x] **Step 4: Correr y verificar que pasan**

Run: `php artisan test --filter=SendCopyFlowsTest`
Expected: 7 PASS (incluido el de no-duplicados).

- [x] **Step 5: Suite del dominio de notificaciones + pint + commit**

Run: `php artisan test --filter="Notification|JobNotification|Chat|Tickets"`
Expected: PASS (sin regresiones en flujos pareados existentes).

```bash
vendor/bin/pint app/Jobs/SendBroadcastNotificationJob.php app/Http/Controllers/TicketsController.php app/Http/Controllers/StudentDataController.php app/Http/Controllers/ParentDataController.php tests/Feature/SendCopyFlowsTest.php
git add -A app/Jobs/SendBroadcastNotificationJob.php app/Http/Controllers/TicketsController.php app/Http/Controllers/StudentDataController.php app/Http/Controllers/ParentDataController.php tests/Feature/SendCopyFlowsTest.php
git commit -m "feat(notifications): emitir avisos, tickets y solicitudes por el emisor único"
```

---

### Task 4B: `sendCopy()` en cuotas vencidas, feedback (Notion) y pagos

**Files:**
- Modify: `app/Console/Commands/SendFeeOverdueReminders.php`, `app/Jobs/SyncNotionJob.php`, `app/Jobs/SyncNotionCommentsJob.php`, `app/Http/Controllers/System/SystemCollectionsFeesPaymentController.php`
- Create: `tests/Feature/SendCopyFlowsPartBTest.php`

**Interfaces:**
- Consumes: `NotificationService::sendCopy(ProvidesAppCopy, string $type)` de Task 3.
- Produces: emisiones con `job_type = 'pago'` (cuota, pago) y `'general'` (feedback).

- [x] **Step 1: Escribir los tests fallidos**

`tests/Feature/SendCopyFlowsPartBTest.php` (Pest; `RefreshDatabase` + `Event::fake([UserNotificationSent::class])`):

```php
test('recordatorio de cuota vencida crea aviso con tipo pago', function () {
    $user = User::factory()->create();
    $studentApp = StudentDataFactory::create(['user_id' => $user->id, 'status' => 'approved']);
    $sysStudent = SystemStudentsFactory::create(['student_app_id' => $studentApp->id]);
    SystemCollectionsFeesFactory::create([
        'student_id' => $sysStudent->id,
        'status' => 'pending',
        'total' => 100,
        'paid' => 0,
        'year' => now()->subYear()->year,
        'month' => 3,
        'last_reminder_sent_at' => null,
    ]);

    $this->artisan('fees:send-overdue-reminders');

    $row = JobNotification::where('user_id', $user->id)->where('job_type', 'pago')->firstOrFail();
    expect($row->title)->toContain('Cuota vencida')
        ->and(JobNotification::app()->whereKey($row->id)->exists())->toBeTrue();
});

test('cambio de estado en Notion crea aviso push', function () {
    config(['services.notion.token' => 't', 'services.notion.database_id' => 'd', 'services.notion.version' => '2022-06-28']);
    $user = User::factory()->create();
    $feedback = Feedback::factory()->withNotionPage()->create([
        'user_id' => $user->id,
        'content' => 'old',
        'status' => FeedbackStatus::Ingresado->value,
    ]);

    $notion = Mockery::mock(NotionService::class);
    $notion->shouldReceive('getPage')->andReturn([
        'id' => $feedback->notion_page_id,
        'properties' => ['Estado' => ['status' => ['name' => 'Done']]],
    ]);
    $notion->shouldReceive('getBlocks')->andReturn([
        ['type' => 'paragraph', 'paragraph' => ['rich_text' => [['type' => 'text', 'text' => ['content' => 'Nuevo', 'annotation' => [], 'href' => null], 'annotations' => [], 'plain_text' => 'Nuevo', 'href' => null]]], 'object' => 'block'],
    ]);

    (new SyncNotionJob($feedback->notion_page_id))->handle($notion);

    expect(JobNotification::where('user_id', $user->id)->where('job_type', 'general')->count())->toBe(1);
});

test('comentario en Notion crea aviso push', function () {
    $user = User::factory()->create();
    $feedback = Feedback::factory()->withNotionPage()->create(['user_id' => $user->id]);

    $notion = Mockery::mock(NotionService::class);
    $notion->shouldReceive('getComments')->with($feedback->notion_page_id)->andReturn([
        ['id' => 'c-1', 'text' => 'hola'],
    ]);

    (new SyncNotionCommentsJob($feedback->notion_page_id))->handle($notion);

    expect(JobNotification::where('user_id', $user->id)->where('job_type', 'general')->count())->toBe(1);
});

test('copy de PaymentRegistered es correcto para push', function () {
    $fee = new SystemCollectionsFees;
    $fee->month = 'marzo';
    $fee->year = 2026;

    $copy = (new PaymentRegistered($fee, 150.5))->appNotificationCopy();

    expect($copy['title'])->toBe('Pago registrado - $150.5')
        ->and($copy['url'])->toBe('/platform/fees');
});
```

Notas: el mock de `SyncNotionJob` sigue el patrón de `tests/Feature/SyncNotionJobTest.php` (si ese test ya declara el shape completo de `getBlocks`, copiar el array literal de ahí); `SystemStudentsFactory` acepta `student_app_id` (los factories corren unguarded); `CAST(month AS INTEGER)` del scope exige `month` numérico (`3`, no `'marzo'`).

- [x] **Step 2: Correr y verificar que fallan**

Run: `php artisan test --filter=SendCopyFlowsPartBTest`
Expected: 3 FAIL de flujo (el test de copy de `PaymentRegistered` pasa de entrada — valida el mecanismo de Task 3).

- [x] **Step 3: Insertar `sendCopy` en los 4 sitios**

1. `SendFeeOverdueReminders::handle()` — tras cada `->notify(new FeeOverdueReminder($fee))` (rama estudiante y rama padre), misma instancia:
```php
$rem = new FeeOverdueReminder($fee);
$studentUser->notify($rem);
app(\App\Services\NotificationService::class)->sendCopy($studentUser, $rem, 'pago');
```
2. `SyncNotionJob::handle()` — dentro del mismo `if ($newStatus && $newStatus !== $previousStatus && $feedback->user)`, tras el `notify`:
```php
$notif = new FeedbackStatusChanged($feedback, $newStatus);
$feedback->user->notify($notif);
app(\App\Services\NotificationService::class)->sendCopy($feedback->user, $notif, 'general');
```
3. `SyncNotionCommentsJob::handle()` — dentro de `if ($comment->wasRecentlyCreated && $feedback->user)`, mismo patrón con `FeedbackCommentReceived` y `'general'`.
4. `SystemCollectionsFeesPaymentController::paidFee()` — en los dos bloques dentro del `try` existente (estudiante y padres), misma instancia y `'pago'`:
```php
$payNotif = new PaymentRegistered($feeModel, (float) $fee['paid']);
$studentData->user->notify($payNotif);
app(\App\Services\NotificationService::class)->sendCopy($studentData->user, $payNotif, 'pago');
```
(loop de `$parentUsers`: una instancia por usuario dentro del `foreach`.)

- [x] **Step 4: Correr y verificar que pasan**

Run: `php artisan test --filter=SendCopyFlowsPartBTest`
Expected: 4 PASS.

- [x] **Step 5: Verificación manual de `paidFee` (único flujo sin test HTTP: su fixture exige el grafo completo de grupos familiares)**

En entorno de pruebas, con un teléfono registrado: registrar un pago desde el panel de cobros. Expected: exactamente **una** notificación `Pago registrado - $…` en el teléfono y una fila `job_type = pago` en `job_notifications`; y el pago no se rompe (el `sendCopy` queda dentro del `try` que ya captura excepciones).

- [x] **Step 6: Pint y commit**

```bash
vendor/bin/pint app/Console/Commands/SendFeeOverdueReminders.php app/Jobs/SyncNotionJob.php app/Jobs/SyncNotionCommentsJob.php app/Http/Controllers/System/SystemCollectionsFeesPaymentController.php tests/Feature/SendCopyFlowsPartBTest.php
git add -A app/Console/Commands/SendFeeOverdueReminders.php app/Jobs/SyncNotionJob.php app/Jobs/SyncNotionCommentsJob.php app/Http/Controllers/System/SystemCollectionsFeesPaymentController.php tests/Feature/SendCopyFlowsPartBTest.php
git commit -m "feat(notifications): cuotas vencidas, feedback y pagos por el emisor único"
```

---

### Task 5: Limpieza de tokens FCM inválidos (evento `NotificationFailed`)

`FcmChannel` (5.1.0) emite `Illuminate\Notifications\Events\NotificationFailed` con `data['report']` (`Kreait\Firebase\Messaging\SendReport`) por cada token fallido. El listener borra solo fallos **permanentes** de token; los transitorios (servicio caído) conservan el registro.

**Files:**
- Create: `app/Listeners/CleanupInvalidFcmToken.php`
- Modify: `app/Providers/AppServiceProvider.php`
- Create: `tests/Feature/CleanupInvalidFcmTokenTest.php`

**Interfaces:**
- Consumes: `NotificationFailed($notifiable, $notification, $channel, $data)` (framework), `SendReport::messageWasSentToUnknownToken()`, `SendReport::messageTargetWasInvalid()`, `SendReport::target()->value()`, modelo `FcmToken`.
- Produces: listener registrado con `Event::listen(NotificationFailed::class, CleanupInvalidFcmToken::class)` en `AppServiceProvider::boot()`.

- [x] **Step 1: Escribir los tests fallidos**

```php
<?php

use App\Models\FcmToken;
use App\Models\User;
use App\Notifications\FcmPushNotification;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Notifications\Events\NotificationFailed;
use Illuminate\Support\Facades\Event;
use Kreait\Firebase\Exception\Messaging\NotFound;
use Kreait\Firebase\Messaging\MessageTarget;
use Kreait\Firebase\Messaging\SendReport;
use NotificationChannels\Fcm\FcmChannel;

uses(RefreshDatabase::class);

function failedEventFor(User $user, \Throwable $error): NotificationFailed
{
    return new NotificationFailed(
        $user,
        new FcmPushNotification('t', 'b', '/', 'general', 0),
        FcmChannel::class,
        ['report' => SendReport::failure(MessageTarget::with('token', 'token-a-borrar'), $error)]
    );
}

test('borra el token cuando FCM lo reporta inexistente', function () {
    $user = User::factory()->create();
    FcmToken::registerForUser($user, 'token-a-borrar', 'android', 'dev-1');

    Event::dispatch(failedEventFor($user, new NotFound('Requested entity was not found.')));

    expect(FcmToken::where('token', 'token-a-borrar')->exists())->toBeFalse();
});

test('conserva el token ante errores no permanentes', function () {
    $user = User::factory()->create();
    FcmToken::registerForUser($user, 'token-a-borrar', 'android', 'dev-1');

    Event::dispatch(failedEventFor($user, new \RuntimeException('ISE: backend service is unavailable')));

    expect(FcmToken::where('token', 'token-a-borrar')->exists())->toBeTrue();
});

test('ignora fallos de otros canales', function () {
    $user = User::factory()->create();
    FcmToken::registerForUser($user, 'token-a-borrar', 'android', 'dev-1');

    $event = new NotificationFailed($user, new FcmPushNotification('t', 'b', '/', 'general', 0), 'mail', []);
    Event::dispatch($event);

    expect(FcmToken::where('token', 'token-a-borrar')->exists())->toBeTrue();
});
```

- [x] **Step 2: Correr y verificar que fallan**

Run: `php artisan test --filter=CleanupInvalidFcmTokenTest`
Expected: FAIL (ningún listener hace nada; el primero debería encontrar la fila todavía presente).

- [x] **Step 3: Implementar el listener y registrarlo**

`app/Listeners/CleanupInvalidFcmToken.php`:

```php
public function handle(NotificationFailed $event): void
{
    if ($event->channel !== FcmChannel::class) {
        return;
    }
    $report = $event->data['report'] ?? null;
    if (!$report instanceof SendReport) {
        return;
    }
    if ($report->messageWasSentToUnknownToken() || $report->messageTargetWasInvalid()) {
        FcmToken::where('token', $report->target()->value())->delete();
    }
}
```

En `AppServiceProvider::boot()`: `Event::listen(NotificationFailed::class, CleanupInvalidFcmToken::class);` (imports `Illuminate\Support\Facades\Event` y el listener).

- [x] **Step 4: Correr y verificar que pasan**

Run: `php artisan test --filter=CleanupInvalidFcmTokenTest`
Expected: 3 PASS.

- [x] **Step 5: Pint y commit**

```bash
vendor/bin/pint app/Listeners/CleanupInvalidFcmToken.php app/Providers/AppServiceProvider.php tests/Feature/CleanupInvalidFcmTokenTest.php
git add app/Listeners/CleanupInvalidFcmToken.php app/Providers/AppServiceProvider.php tests/Feature/CleanupInvalidFcmTokenTest.php
git commit -m "feat(notifications): limpiar tokens FCM inválidos al fallar el envío"
```

---

### Task 6: Alineación de listas (spec §7.4) + verificación integral

La lista in-app de la API (`GET /api/v1/notifications`) lee `app_notifications`, pero `NotificationService::send()` solo crea `job_notifications`. Si nada más puebla `app_notifications`, al tocar un push la pantalla no muestra el elemento. Tarea: verificar el mecanismo real y, si no existe otro, crear el espejo.

**Files:**
- Create: `tests/Feature/AppNotificationMirrorTest.php`
- Modify (condicional): `app/Services/NotificationService.php`

**Interfaces:**
- Consumes: `NotificationService::send()/sendPending()` de Task 3; modelo `AppNotification` (`type`, `title`, `body`, `data`, `notifiable_id`, `notifiable_type`, `is_read`).

- [x] **Step 1: Verificar quién puebla `app_notifications` (entorno con la cola)**

```bash
php artisan tinker --execute='print "total=".App\Models\AppNotification::count()." latest=".App\Models\AppNotification::max("created_at")."\n"; print_r(App\Models\AppNotification::selectRaw("type, count(*) c")->groupBy("type")->orderByDesc("c")->limit(10)->get()->toArray());'
php artisan tinker --execute='print_r(DB::select("SELECT tgname FROM pg_trigger WHERE NOT tgisinternal"));'
```
Regla de decisión (cerrada): **existe** otro mecanismo (trigger o código no encontrado) → NO implementar espejo, documentar el hallazgo en el reporte final. **No existe** (solo `AppNotificationsService::notifyUser` / manuales, o vacío) → seguir al Step 2. Código de creación conocido hoy: `AppNotificationsService::notifyUser()` y `NotificationController::store` (grep verificado: `AppNotification::create` solo aparece en el servicio).

- [x] **Step 2 (solo si la regla lo indica): Escribir el test del espejo**

```php
<?php

use App\Events\UserNotificationSent;
use App\Models\AppNotification;
use App\Models\User;
use App\Services\NotificationService;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Event;

uses(RefreshDatabase::class);

test('send crea también la fila de la lista in-app', function () {
    Event::fake([UserNotificationSent::class]);
    $user = User::factory()->create();

    app(NotificationService::class)->send($user, 'Aviso', 'Cuerpo', '/platform/events', 'general');

    $row = AppNotification::where('notifiable_id', $user->id)->firstOrFail();
    expect($row->title)->toBe('Aviso')
        ->and($row->body)->toBe('Cuerpo')
        ->and($row->is_read)->toBeFalse()
        ->and($row->data['url'])->toBe('/platform/events');
});

test('sendPending crea también la fila de la lista in-app', function () {
    Event::fake([UserNotificationSent::class]);
    $user = User::factory()->create();

    app(NotificationService::class)->sendPending($user, 'Aviso', 'Cuerpo', '/platform/fees', 'pago');

    expect(AppNotification::where('notifiable_id', $user->id)->exists())->toBeTrue();
});
```

- [x] **Step 3 (solo si la regla lo indica): Verificar que falla**

Run: `php artisan test --filter=AppNotificationMirrorTest`
Expected: FAIL (no hay filas en `app_notifications`).

- [x] **Step 4 (solo si la regla lo indica): Implementar el espejo**

En `NotificationService`: método privado `persistAppNotification(User $user, string $type, string $title, string $body, string $url, array $extra): void` que crea la fila `AppNotification` (campos del Step 2, `notifiable_type => User::class`, `is_read => false`, `data => array_merge(['url' => $url], $extra)`), llamado **desde `send()` y `sendPending()`** justo después del `JobNotification::create` (DRY: un solo bloque para ambos).

- [x] **Step 5 (solo si la regla lo indica): Verificar que pasan**

Run: `php artisan test --filter=AppNotificationMirrorTest`
Expected: 2 PASS.

- [x] **Step 6: Verificación integral**

Run: `php artisan test`
Expected: suite completa PASS (32 fallos preexistentes/flaky documentados en `STATE.md` no deben crecer: comparar el listado de FAIL con el de `master` antes del branch).

Run: `vendor/bin/pint --test`
Expected: sin cambios pendientes.

Commit (si hubo espejo):
```bash
git add app/Services/NotificationService.php tests/Feature/AppNotificationMirrorTest.php
git commit -m "fix(notifications): espejo de avisos a la lista in-app de la API"
```

---

## Handoff a los siguientes planes

Este es el **Plan 1 de 3** (spec §8). Tras su implementación y verificación:

- **Plan 2 — Teléfono (APK)**: `firebase_messaging` + registro de token + primer de permiso (spec §4–§5).
- **Plan 3 — PC (escritorio)**: residencia en bandeja + toasts nativos (spec §6).

Los escribe writing-plans a partir de este plan ya ejecutado (el fix de Task 1 y la limpieza de Task 2 fijan el contrato que consumirá el teléfono).
