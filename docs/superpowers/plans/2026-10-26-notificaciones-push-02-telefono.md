# Notificaciones Push — Plan 2: Teléfono (APK Android) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** La APK Android recibe todas las notificaciones como push nativo (cerrada, fondo y primer plano), con tap que navega al destino y un primer de permiso una sola vez tras el primer login.

**Architecture:** `firebase_messaging` para token y recepción (el sistema muestra el push en fondo/cerrada; en primer plano se muestra vía `flutter_local_notifications`); `PushRepository` centraliza el ciclo de vida del token (registro idempotente, refresh, unregister); `pushCoordinatorProvider` (espejo del `realtimeCoordinatorProvider`) ata el ciclo de vida a `authProvider`; `routeForPush()` mapea `url` del payload a rutas go_router; el backend (Task 1) marca `channel_id` (`efe_mensajes` para chat, `efe_general` resto).

**Tech Stack:** Flutter 3.44 / Dart 3.5 (`efe_mobile`), `firebase_core` + `firebase_messaging` + `flutter_local_notifications` (vía `flutter pub add`), `uuid` (device_id), Riverpod + go_router + dio existentes. Backend: `efe-app` (`FcmPushNotification::toFcm`, ya corregido en Plan 1).

**Spec:** `docs/superpowers/specs/2026-10-23-notificaciones-push-telefono-pc-design.md` (§4 teléfono, §5 UI primer) — el plan argumenta desde él.

**Workdir tareas 2–6:** `/opt/dev/efe_mobile`, rama `feat/push-telefono` (worktree según `using-git-worktrees` al ejecutar). **Workdir Task 1:** `/opt/dev/efe-app`, rama corta `feat/fcm-channel-id` desde `preprod`.

## Global Constraints

- **Solo Android** (`Platform.isAndroid` en coordinator, token provider y main). Web/desktop no se tocan (Plan 3 es dueño del desktop).
- `applicationId = "com.efe.efe_mobile"`; `android/app/google-services.json` existe (prerrequisito del usuario, Task 0) y está en `.gitignore`.
- Sin `firebase_options.dart`: en Android `Firebase.initializeApp()` sin opciones lee el `google-services.json` procesado por el plugin de Gradle.
- Contrato FCM del backend (Plan 1): `data = {url, type, notification_id}` + `notification = {title, body}`; canales `efe_general` / `efe_mensajes` (Task 1 los marca).
- Endpoints push (existentes, `auth:sanctum`): `POST /api/v1/push/register` `{token, platform: 'android', device_id}`, `DELETE /api/v1/push/unregister?token=…`. No cambiar el backend salvo Task 1.
- **El registro nunca bloquea el login**: todo fallo de red/permisos se traga y devuelve `false`.
- **El logout siempre desregistra antes de borrar el token local** (si no, el teléfono sigue recibiendo pushes).
- Copy nuevo solo vía l10n es/en (claves exactas de cada tarea). `flutter analyze` limpio antes de cada commit.
- Tipos `job_type` del backend intactos (dueño: Plan 1).

## Review Focus

1. **Canal por defecto del manifest ≠ canal creado en código** → Android 8+ descarta el FCM en silencio → test de consistencia manifest↔`PushChannels` (Task 2).
2. **`url` desconocida o malformada al tocar un push** → crash o ruta rota → test de fallback a `/notifications` (Task 4).
3. **Logout sin unregister previo** → el teléfono sigue recibiendo pushes del usuario anterior → test de orden logout (Task 5).
4. **Token rotado (`onTokenRefresh`) nunca re-registrado** → el teléfono deja de recibir en silencio → test de refresh (Task 3).
5. **Primer que reaparece en cada login, o login trabado por fallo de red al registrar** → test de flag en dismiss + test de registro que nunca lanza (Tasks 5 y 3).

## File Structure

| Acción | Archivo | Responsabilidad |
|---|---|---|
| Verify (usuario) | `android/app/google-services.json` | Config Firebase (gitignored) |
| Modify (backend) | `/opt/dev/efe-app/app/Notifications/FcmPushNotification.php` | `channel_id` por prefijo de url |
| Modify (backend) | `/opt/dev/efe-app/tests/Unit/FcmPushNotificationTest.php` | Aserciones de canal |
| Modify | `pubspec.yaml` | `firebase_core`, `firebase_messaging`, `flutter_local_notifications`, `uuid` |
| Modify | `android/settings.gradle` | Plugin `google-services` |
| Modify | `android/app/build.gradle` | Aplica `google-services` |
| Modify | `android/app/src/main/AndroidManifest.xml` | Permiso + canal/icono por defecto |
| Create | `android/app/src/main/res/drawable/ic_stat_efe.xml` | Icono silhouette |
| Modify | `.gitignore` | Ignora `google-services.json` |
| Modify | `lib/core/api/api_client.dart` | `delete` acepta `queryParameters` |
| Modify | `lib/core/storage/secure_storage.dart` | Claves `fcm_token`, `device_id`, `push_primer_seen` |
| Create | `lib/core/notifications/notification_router.dart` | `routeForPush(url)` pura |
| Create | `lib/core/notifications/local_notifications_service.dart` | Canales + show + taps (`PushChannels`) |
| Create | `lib/features/push/data/push_api.dart` | `register` / `unregister` |
| Create | `lib/features/push/data/push_repository.dart` | `PushTokenProvider` + impl Firebase + `PushRepository` |
| Create | `lib/features/push/providers/push_providers.dart` | Providers api/repo/tokens/local |
| Create | `lib/features/push/providers/push_coordinator.dart` | Ciclo de vida + primer + navegación por tap |
| Create | `lib/features/push/widgets/push_primer_sheet.dart` | Bottom sheet del primer |
| Modify | `lib/main.dart` | `Firebase.initializeApp()` |
| Modify | `lib/app/app.dart` | `ref.watch(pushCoordinatorProvider)` |
| Modify | `lib/features/auth/providers/auth_provider.dart` | Unregister antes de limpiar en `logout()` |
| Modify | `lib/l10n/app_es.arb`, `lib/l10n/app_en.arb` | 4 claves del primer |
| Tests | `test/features/push/push_channels_test.dart`, `push_api_test.dart`, `push_repository_test.dart`, `push_primer_sheet_test.dart`, `test/core/notification_router_test.dart`, `test/auth/auth_logout_push_test.dart` | Uno por tarea |

---

### Task 0: Prerrequisito `google-services.json` (acción del usuario, sin código)

Sin este archivo `flutter build apk` falla (el plugin de Gradle lo exige). Lo provee el usuario desde la consola Firebase; la tarea solo verifica y documenta el bloqueo.

- [ ] **Step 1: Pedir el archivo al usuario**

Pasos exactos para el usuario (consola Firebase → proyecto `efe-app-d3d42` → Configuración → agregar app Android → package `com.efe.efe_mobile` → descargar `google-services.json` → colocarlo en `efe_mobile/android/app/google-services.json`). No se necesita SHA-1 para FCM.

- [ ] **Step 2: Verificar presencia**

Run: `test -f android/app/google-services.json && echo PRESENTE`
Expected: `PRESENTE`. Si falta → **STOP total del plan**: ninguna tarea 1–6 puede continuar (el build Android no compila sin el archivo). Reportar y esperar al usuario.

---

### Task 1 (backend): `channel_id` en el payload FCM

El teléfono crea dos canales (`efe_general`, `efe_mensajes`); sin `channel_id` todo caería al canal por defecto y el spec (§4) exige canal de Mensajes con sonido alto. El backend distingue por prefijo de url: el chat usa `/platform/chat/{id}` (`NewChatMessage`) y `/platform/chats/{id}` (`ChatService::notifyParticipants`, type `'general'`).

**Files (workdir `/opt/dev/efe-app`, rama `feat/fcm-channel-id` desde `preprod`):**
- Modify: `app/Notifications/FcmPushNotification.php`
- Modify: `tests/Unit/FcmPushNotificationTest.php`

**Interfaces:**
- Produces: `toFcm()` incluye `custom['android']['notification']['channel_id']` = `'efe_mensajes'` si la url empieza con `/platform/chat`, si no `'efe_general'`. Lo consumen las Tasks 2–4 (los canales deben existir en el teléfono).

- [ ] **Step 1: Escribir el test fallido** (anexar al archivo existente):

```php
test('toFcm asigna el canal de mensajes al chat y general al resto', function () {
    $chat = (new FcmPushNotification('t', 'b', '/platform/chats/7', 'general', 1))->toFcm(null)->toArray();
    $general = (new FcmPushNotification('t', 'b', '/platform/notifications', 'general', 2))->toFcm(null)->toArray();
    $fees = (new FcmPushNotification('t', 'b', '/fees', 'pago', 3))->toFcm(null)->toArray();

    expect($chat['android']['notification']['channel_id'])->toBe('efe_mensajes')
        ->and($general['android']['notification']['channel_id'])->toBe('efe_general')
        ->and($fees['android']['notification']['channel_id'])->toBe('efe_general');
});
```

- [ ] **Step 2: Correr y verificar que falla**

Run: `php artisan test --filter="asigna el canal"`
Expected: FAIL (clave `channel_id` ausente).

- [ ] **Step 3: Implementar** — en el array `android.notification` del `->custom([...])` existente agregar:

```php
'channel_id' => str_starts_with($this->url, '/platform/chat') ? 'efe_mensajes' : 'efe_general',
```

- [ ] **Step 4: Correr y verificar que pasa** — el test nuevo PASS + el test de Task 1 del Plan 1 sigue PASS.

- [ ] **Step 5: Pint, commit, merge, push y deploy** (el canal lo consume la app del Plan 2; el deploy usa el pipeline ya probado):

```bash
vendor/bin/pint app/Notifications/FcmPushNotification.php tests/Unit/FcmPushNotificationTest.php
git add -A && git commit -m "feat(notificaciones): channel_id FCM por tipo (mensajes/general)"
git checkout preprod && git merge feat/fcm-channel-id && git push origin preprod
ssh -o BatchMode=yes root@191.101.18.45 'cd /home/preprod.efeacademia.com && ./deploy.sh' # ver "/health" → commit nuevo
git branch -d feat/fcm-channel-id
```

---

### Task 2: Dependencias + shell Android + icono

**Files:**
- Modify: `pubspec.yaml`, `android/settings.gradle`, `android/app/build.gradle`, `android/app/src/main/AndroidManifest.xml`, `.gitignore`
- Create: `android/app/src/main/res/drawable/ic_stat_efe.xml`
- Create: `test/features/push/push_channels_test.dart`

**Interfaces:**
- Produces: `PushChannels.generalId = 'efe_general'`, `PushChannels.messagesId = 'efe_mensajes'` (en `lib/core/notifications/local_notifications_service.dart` — se crea en Task 4, pero **los IDs quedan fijados aquí** y este test los referencia; si Task 4 cambia un ID, este test debe seguir verde). Bloquea a Tasks 3–5 (importan paquetes Firebase).

- [ ] **Step 1: Agregar dependencias**

Run: `flutter pub add firebase_core firebase_messaging flutter_local_notifications uuid`
Expected: `pubspec.yaml` las lista y `flutter pub get` resuelve sin conflicto. Anotar las versiones resueltas en el mensaje del commit si difieren de `^`.

- [ ] **Step 2: Editar Gradle**

`android/settings.gradle`, bloque `plugins`, agregar: `id "com.google.gms.google-services" version "4.4.2" apply false`.
`android/app/build.gradle`, bloque `plugins`, agregar al final: `id "com.google.gms.google-services"`.

- [ ] **Step 3: Editar el manifest** — agregar el permiso (nivel `manifest`, junto a `INTERNET`):

```xml
<uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>
```

y dentro de `application`:

```xml
<meta-data android:name="com.google.firebase.messaging.default_notification_channel" android:value="efe_general" />
<meta-data android:name="com.google.firebase.messaging.default_notification_icon" android:value="@drawable/ic_stat_efe" />
```

- [ ] **Step 4: Crear el icono silhouette** `android/app/src/main/res/drawable/ic_stat_efe.xml` (campana blanca, estilo Material):

```xml
<vector xmlns:android="http://schemas.android.com/apk/res/android"
    android:width="24dp"
    android:height="24dp"
    android:viewportWidth="24"
    android:viewportHeight="24">
    <path
        android:fillColor="#FFFFFF"
        android:pathData="M12,22c1.1,0 2,-0.9 2,-2h-4c0,1.1 0.9,2 2,2zM18,16v-5c0,-3.07 -1.63,-5.64 -4.5,-6.32L13.5,4c0,-0.83 -0.67,-1.5 -1.5,-1.5S10.5,3.17 10.5,4l-0.04,0.68C7.05,5.36 5.5,7.92 5.5,11v5l-2,2v1h19v-1l-2,-2z" />
</vector>
```

- [ ] **Step 5: Gitignore** — anexar `android/app/google-services.json` a `.gitignore`.

> NOTA (ruling del coordinador): el test de consistencia canal↔manifest se escribe en Task 4 junto a `PushChannels` — un test que no compila no debe commitearse (rompería los gates `flutter analyze` de las Tasks 3–5). Ver Task 4 Step 1.

- [ ] **Step 6: Verificar compilación**

Run: `flutter analyze` → sin issues. Run: `flutter build apk --debug` → BUILD SUCCESSFUL (compila recursos, manifest y plugin; requiere el archivo de Task 0).

- [ ] **Step 7: Commit**

```bash
git add pubspec.yaml pubspec.lock android/settings.gradle android/app/build.gradle android/app/src/main/AndroidManifest.xml android/app/src/main/res/drawable/ic_stat_efe.xml .gitignore
git commit -m "feat(push): dependencias Firebase y shell Android (canales, icono, permiso)"
```

---

### Task 3: API push + repositorio de token (ciclo de vida testeable)

**Files:**
- Modify: `lib/core/api/api_client.dart`, `lib/core/storage/secure_storage.dart`
- Create: `lib/features/push/data/push_api.dart`, `lib/features/push/data/push_repository.dart`, `lib/features/push/providers/push_providers.dart`
- Create: `test/features/push/push_api_test.dart`, `test/features/push/push_repository_test.dart`

**Interfaces:**
- Consumes: `ApiClient.post/delete` (extendido aquí), `SecureStorage`, `POST /api/v1/push/register`, `DELETE /api/v1/push/unregister`.
- Produces (para Tasks 4–5):
  - `PushApi.register({required String token, required String deviceId})`, `PushApi.unregister(String token)`
  - `enum PushPermission { granted, denied }`
  - `abstract PushTokenProvider { Future<PushPermission> permissionStatus(); Future<PushPermission> requestPermission(); Future<String?> getToken(); Stream<String> get onTokenRefresh; }` + `FirebasePushTokenProvider` (todo con guard `!Platform.isAndroid` → `denied`/`null`/`Stream.empty()`)
  - `PushRepository({required PushApi api, required SecureStorage storage, required PushTokenProvider tokens})` con `Future<bool> ensureRegistered()`, `Future<void> unregisterCurrentDevice()`, `Stream<String> get tokenRefreshes`
  - Providers: `pushApiProvider`, `pushTokenProviderProvider`, `pushRepositoryProvider`

Reglas fijadas (el cuerpo las implementa, los tests las pinned):
- `ensureRegistered()`: no-Android → `false`; permiso no-granted → `false`; token nulo → `false`; token igual al guardado → `true` sin POST (idempotente); si no → POST `{token, platform: 'android', device_id}` + guarda token. **Jamás lanza** (todo `catch` → `false`).
- `unregisterCurrentDevice()`: sin token guardado → nada; si no → DELETE + borra local en `finally`. **Jamás lanza**.
- `SecureStorage` suma: `_fcmTokenKey/_deviceIdKey/_pushPrimerSeenKey` + `saveFcmToken/getFcmToken/deleteFcmToken`, `getOrCreateDeviceId()` (uuid v4 persistido), `hasSeenPushPrimer/savePushPrimerSeen`.
- `ApiClient.delete` pasa a `Future<Response> delete(String path, {Map<String, dynamic>? queryParameters}) => dio.delete(path, queryParameters: queryParameters);`

- [ ] **Step 1: Escribir los tests fallidos** — `push_api_test.dart` (estilo `notification_contract_test.dart`: `ApiClient` stub que graba llamadas):

```dart
test('register postea token, plataforma y device al endpoint', () async {
  final client = _RecordingApiClient();
  await PushApi(client).register(token: 'tok-1', deviceId: 'dev-1');
  expect(client.posts.single['path'], '/push/register');
  expect(client.posts.single['data'],
      {'token': 'tok-1', 'platform': 'android', 'device_id': 'dev-1'});
});

test('unregister borra con el token como query', () async {
  final client = _RecordingApiClient();
  await PushApi(client).unregister('tok-1');
  expect(client.deletes.single['path'], '/push/unregister');
  expect(client.deletes.single['queryParameters'], {'token': 'tok-1'});
});
```

`push_repository_test.dart` (fakes locales: `_FakeTokens` con `status/token/controller`, storage fake con claves push):

```dart
test('ensureRegistered postea una vez y la segunda es no-op', () async {
  ... tokens.status = granted, token 'tok-1' ...
  expect(await repo.ensureRegistered(), isTrue);
  expect(await repo.ensureRegistered(), isTrue);
  expect(api.posts.length, 1);
  expect(await storage.getFcmToken(), 'tok-1');
  expect(await storage.getOrCreateDeviceId(), await storage.getOrCreateDeviceId());
});

test('denegado o fallo de red no lanza y devuelve false', () async {
  ... status = denied ... expect(await repo.ensureRegistered(), isFalse);
  ... status = granted pero api.post lanza ... expect(await repo.ensureRegistered(), isFalse);
});

test('refresh con token distinto re-registra', () async {
  ... registrado 'tok-1' ... tokens.emit('tok-2') vía tokenRefreshes como hace el coordinator ...
  expect(api.posts.last['data']['token'], 'tok-2');
});

test('unregister borra en backend y local; sin token no llama', () async {
  ... storage con 'tok-1' ... await repo.unregisterCurrentDevice();
  expect(api.deletes.single ... token 'tok-1'); expect(await storage.getFcmToken(), isNull);
});
```

- [ ] **Step 2: Correr y verificar que fallan**

Run: `flutter test test/features/push/push_api_test.dart test/features/push/push_repository_test.dart`
Expected: FAIL (clases inexistentes).

- [ ] **Step 3: Implementar** en el orden: `ApiClient.delete` → `SecureStorage` (+ import `uuid`) → `push_api.dart` → `push_repository.dart` (interfaz + impl Firebase + repositorio) → `push_providers.dart`.

- [ ] **Step 4: Correr y verificar que pasan**

Run: mismo comando. Expected: ALL TESTS PASSED.

- [ ] **Step 5: Analyze + commit**

Run: `flutter analyze` → sin issues.
```bash
git add lib/core/api/api_client.dart lib/core/storage/secure_storage.dart lib/features/push/data/ lib/features/push/providers/push_providers.dart test/features/push/push_api_test.dart test/features/push/push_repository_test.dart
git commit -m "feat(push): API y repositorio del ciclo de vida del token FCM"
```

---

### Task 4: Router + notificaciones locales + coordinator

**Files:**
- Create: `lib/core/notifications/notification_router.dart`, `lib/core/notifications/local_notifications_service.dart` (con `PushChannels`), `lib/features/push/providers/push_coordinator.dart`
- Modify: `lib/main.dart`, `lib/app/app.dart`
- Create: `test/core/notification_router_test.dart`

**Interfaces:**
- Consumes: `PushRepository.ensureRegistered/tokenRefreshes` (Task 3), `unreadCountProvider` + `notificationListProvider` (existentes), `routerProvider.go(route)` (navegación sin contexto).
- Produces (para Task 5): coordinator con sesión iniciada/detenida por `authProvider` (Task 5 agrega ahí la llamada al primer). Hace pasar el test de Task 2.

Firmas fijadas:
- `String routeForPush(String? url)` — tabla: `/platform/chat/{id}` y `/platform/chats/{id}` → `/chat/{id}`; `/platform/notifications` → `/notifications`; `/platform/fees` y `/fees` → `/fees`; `/dashboard` → `/dashboard`; resto/`null`/vacío → `/notifications`.
- `class PushChannels { static const generalId = 'efe_general'; static const messagesId = 'efe_mensajes'; }`
- `LocalNotificationsService.init({required void Function(String route) onTap})`, `showPush({required String? title, required String? body, required String route, required bool isChat})`, canal `messagesId` (Importance.max) si `isChat`, si no `generalId` (Importance.high), icono `'ic_stat_efe'`, `payload: route`.
- `pushCoordinatorProvider`: espejo del `realtimeCoordinatorProvider` (guarda `Platform.isAndroid`, `ref.listen(authProvider)` + arranque en frío, `startSession/stopSession` con un solo juego de suscripciones): `onMessage` → invalida badge+lista y `showPush`; `onMessageOpenedApp` + `getInitialMessage` → `router.go(route)`; `tokenRefreshes` → `ensureRegistered()`.

- [ ] **Step 1: Escribir el test del router fallido**:

```dart
import 'package:efe_mobile/core/notifications/notification_router.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('mapea urls del backend a rutas de la app con fallback', () {
    expect(routeForPush('/platform/chat/7'), '/chat/7');
    expect(routeForPush('/platform/chats/7'), '/chat/7');
    expect(routeForPush('/platform/notifications'), '/notifications');
    expect(routeForPush('/platform/fees'), '/fees');
    expect(routeForPush('/fees'), '/fees');
    expect(routeForPush('/dashboard'), '/dashboard');
    expect(routeForPush('/platform/requests'), '/notifications');
    expect(routeForPush('/platform/absences'), '/notifications');
    expect(routeForPush('/platform/tickets/3'), '/notifications');
    expect(routeForPush(null), '/notifications');
    expect(routeForPush(''), '/notifications');
  });
}
```

Y en `test/features/push/push_channels_test.dart` (movido de Task 2: aquí sí compila, porque `PushChannels` nace en esta tarea):

```dart
import 'dart:io';

import 'package:efe_mobile/core/notifications/local_notifications_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('el canal por defecto del manifest es el creado en código', () {
    final manifest =
        File('android/app/src/main/AndroidManifest.xml').readAsStringSync();
    expect(
      manifest,
      contains(
          'com.google.firebase.messaging.default_notification_channel" android:value="${PushChannels.generalId}"'),
    );
    expect(
      File('android/app/src/main/res/drawable/ic_stat_efe.xml').existsSync(),
      isTrue,
    );
  });
}
```

- [ ] **Step 2: Correr y verificar que falla**

Run: `flutter test test/core/notification_router_test.dart test/features/push/push_channels_test.dart`
Expected: FAIL (import inexistente; el de canales, por `PushChannels`).

- [ ] **Step 3: Implementar router + servicio** (`notification_router.dart` como función pura + `local_notifications_service.dart` con `PushChannels` y servicio)

- [ ] **Step 4: Correr y verificar que pasan**

Run: `flutter test test/core/notification_router_test.dart test/features/push/push_channels_test.dart`
Expected: ambos PASS (el de canales valida el manifest de Task 2).

- [ ] **Step 5: Implementar coordinator + wiring** (`push_coordinator.dart` según Firmas + `Firebase.initializeApp()` en `main.dart` con guard Android y try/catch que nunca rompe el arranque + `ref.watch(pushCoordinatorProvider);` en `app.dart` junto al realtime). Tipos: `m.data['url'] as String?` al llamar `routeForPush` y al calcular `isChat` (`((m.data['url'] as String?) ?? '').startsWith('/platform/chat')`).

- [ ] **Step 6: Analyze + commit**

Run: `flutter analyze` → sin issues.
```bash
git add lib/core/notifications/ lib/features/push/providers/push_coordinator.dart lib/main.dart lib/app/app.dart test/core/notification_router_test.dart test/features/push/push_channels_test.dart
git commit -m "feat(push): router de destinos, avisos locales y coordinator FCM"
```

---

### Task 5: Primer de permiso + orden de logout

Copy exacto del spec (§5, es/en):
- `pushPrimerTitle`: "Activá las notificaciones" / "Turn on notifications"
- `pushPrimerBody`: "Los mensajes de chat y los avisos de la escuela te llegan aunque la app esté cerrada" / "Chat messages and school notices reach you even when the app is closed"
- `pushPrimerActivate`: "Activar" / "Turn on"
- `pushPrimerLater`: "Ahora no" / "Not now"

**Files:**
- Modify: `lib/l10n/app_es.arb`, `lib/l10n/app_en.arb`, `lib/features/auth/providers/auth_provider.dart`
- Create: `lib/features/push/widgets/push_primer_sheet.dart`
- Modify: `lib/features/push/providers/push_coordinator.dart`, `lib/core/api/api_client.dart` (lectura lazy de dotenv — ver Step 6)
- Create: `test/features/push/push_primer_sheet_test.dart`, `test/auth/auth_logout_push_test.dart`

**Interfaces:**
- Consumes: `PushRepository.ensureRegistered/unregisterCurrentDevice`, `PushTokenProvider.requestPermission`, `SecureStorage.hasSeenPushPrimer/savePushPrimerSeen`, `PillButton(label, onPressed)`, `context.l10n` (vía `l10n.dart`).
- Reglas: sheet una sola vez tras el primer login (flag en storage, se marca **siempre** al cerrar por cualquier vía); "Activar" → `requestPermission()` → si granted, `ensureRegistered()`; denegado/cancelado → nada (el badge in-app sigue). `AuthNotifier(this._repository, [this._pushRepository])` (opcional: tests existentes intactos); `logout()` desregistra (best-effort con try/catch) **antes** de `repository.logout()`.

- [ ] **Step 1: Escribir los tests fallidos**

`push_primer_sheet_test.dart` (con `test/helpers/localized_app.dart`, locale es):

```dart
testWidgets('muestra copy, Activar devuelve true y Ahora no false', (tester) async {
  bool? result;
  await tester.pumpWidget(localizedApp(
    home: Scaffold(body: PushPrimerSheet(onResult: (v) => result = v)),
  ));
  expect(find.text('Activá las notificaciones'), findsOneWidget);
  expect(find.textContaining('aunque la app esté cerrada'), findsOneWidget);
  await tester.tap(find.text('Ahora no'));
  expect(result, isFalse);
});
```

(más un caso `Activar` → `isTrue`; el flag de storage lo prueba el coordinator… no testeable sin device: el coordinator marca `savePushPrimerSeen` en **todas** las salidas del sheet — revisión por código en el review de la tarea.)

`auth_logout_push_test.dart` (fakes con lista de llamadas compartida para el orden):

```dart
test('logout desregistra el push antes de limpiar la sesión', () async {
  ... storage fake con fcm token 'tok-1'; api stub que graba DELETEs; pushRepo real con tokens fake (denied);
  ... fakeAuthRepo que graba 'auth.logout';
  final notifier = AuthNotifier(fakeAuthRepo, pushRepo);
  await notifier.logout();
  expect(calls, ['push.unregister', 'auth.logout']);
  expect(await storage.getFcmToken(), isNull);
});
```

- [ ] **Step 2: Correr y verificar que fallan**

Run: `flutter test test/features/push/push_primer_sheet_test.dart test/auth/auth_logout_push_test.dart`
Expected: FAIL (archivos inexistentes).

- [ ] **Step 3: Implementar copy + sheet** (claves arb 4+4 + `push_primer_sheet.dart`: el widget usa `PillButton` primario + `TextButton` secundario, icono bell phosphor, `AppColors.primary`; `showModalBottomSheet` lo invoca el coordinator)

- [ ] **Step 4: Correr y verificar que pasa el widget test**

Run: `flutter test test/features/push/push_primer_sheet_test.dart`
Expected: PASS.

- [ ] **Step 5: Implementar orden de logout + trigger del primer** (`AuthNotifier` con param opcional + orden en `logout()` + wiring en `authProvider`; en el coordinator agregar tras `ensureRegistered()` la llamada a `showPushPrimerIfNeeded(ref, router)` + su implementación: guard Android + flag + contexto de `router.routerDelegate.navigatorKey.currentContext` en `addPostFrameCallback`; sin contexto → no marca y reintenta en el próximo login)

- [ ] **Step 6: Fix raíz en `ApiClient` + revert de overrides provisorios**

Causa raíz (verificada): el constructor `ApiClient(this._storage)` lee `dotenv.env['API_BASE_URL']`, que lanza `NotInitializedError` si dotenv no se inicializó. El wiring de esta tarea (`authProvider` → `pushRepositoryProvider` → `apiClientProvider`) mete esa construcción en ~17 archivos de test que aíslan con overrides y nunca inician dotenv (114 fallos, todos `NotInitializedError`). La cura no es tocar 17 tests sino no leer dotenv en el constructor: en producción el comportamiento es idéntico (dotenv siempre cargado antes de `runApp`).

Cambio exacto en `lib/core/api/api_client.dart` (único cambio de producción permitido fuera de la lista original):

```dart
ApiClient(this._storage) {
  String baseUrl;
  try {
    baseUrl = dotenv.env['API_BASE_URL'] ?? 'http://localhost:8000/api/v1';
  } catch (_) {
    // dotenv sin inicializar (tests/widget sin EnvHelper): mismo default.
    baseUrl = 'http://localhost:8000/api/v1';
  }
```

(resto del constructor intacto). Luego revertir los overrides provisorios — verificar primero que sus diffs sean solo adiciones y descartarlos:

```bash
git diff --stat test/auth/login_screen_test.dart test/auth/forgot_password_screen_test.dart
git checkout -- test/auth/login_screen_test.dart test/auth/forgot_password_screen_test.dart
```

(si algún diff contiene algo más que las adiciones del override, STOP y reportar).

- [ ] **Step 7: Correr logout test + suite completa**

Run: `flutter test test/auth/auth_logout_push_test.dart` → PASS. Run: `flutter test` → toda la suite PASS (cero fallos, como el baseline +575 más los tests nuevos de la rama).

- [ ] **Step 8: Analyze + commit**

Run: `flutter analyze` → sin issues.
```bash
git add lib/l10n/app_es.arb lib/l10n/app_en.arb lib/features/push/widgets/ lib/features/auth/providers/auth_provider.dart lib/features/push/providers/push_coordinator.dart test/features/push/push_primer_sheet_test.dart test/auth/auth_logout_push_test.dart
git commit -m "feat(push): primer de permiso y desregistro en logout"
```

---

### Task 6: Verificación integral + aceptación en dispositivo

- [ ] **Step 1: Suite y análisis**

Run: `flutter analyze` → sin issues. Run: `flutter test` → toda la suite PASS (los fallos preexistentes, si los hay, se listan y comparan contra el baseline de `master`).

- [ ] **Step 2: Build debug**

Run: `flutter build apk --debug` → BUILD SUCCESSFUL.

- [ ] **Step 3: Aceptación manual en dispositivo real** (requiere APK de esta rama instalada + backend preprod ya desplegado con Plan 1):

1. Instalación limpia → login → el primer aparece **una sola vez** → "Activar" → diálogo del sistema → permitir → en backend `fcm_tokens` hay fila `platform=android` (tinker: `FcmToken::where('platform','android')->count()`).
2. App cerrada → mensaje de chat de otro usuario → notificación nativa visible → tap → chat abierto en destino.
3. Primer plano → notificación local visible; badge y lista se refrescan.
4. Logout → sin pushes; la fila del token desapareció.
5. Reinstalar → primer → "Ahora no" → no vuelve a preguntar; badge in-app funciona.
6. Cada tipo de la matriz Plan 1 (pago, ausencia, broadcast, evento, ticket) → un push, sin duplicados.

- [ ] **Step 4: Commit final si hubo ajustes** (solo archivos tocados por ajustes; si no hubo, sin commit).

---

## Handoff a Plan 3

Este es el **Plan 2 de 3**. Tras su implementación y verificación: **Plan 3 — PC (escritorio)**: residencia en bandeja + toasts nativos reutilizando `routeForPush()` (spec §6). Lo escribe writing-plans a partir de este plan ejecutado.
