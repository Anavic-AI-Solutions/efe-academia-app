# Notificaciones Push — Plan 3: PC Escritorio (bandeja) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** La app de escritorio (Windows/Linux) vive en la bandeja con autostart, muestra cada notificación como toast nativo, y el clic abre la ventana en el destino.

**Architecture:** Enfoque A del spec (residencia integrada, sin servicio de SO): `DesktopSession.init()` en `main()` configura ventana (X→ocultar), bandeja y autostart; `desktopCoordinatorProvider` (espejo del realtime) suscribe `watchNotifications` con payload y muestra toasts vía `LocalNotificationsService.showDesktopToast()`; el tap muestra la ventana y navega con `routeForPush()` (Plan 2). Sin FCM en desktop: todo viaja por el socket Reverb ya existente.

**Tech Stack:** Flutter 3.44 / Dart 3.5 (`efe_mobile`); nuevos vía `flutter pub add`: `window_manager`, `system_tray`, `launch_at_startup` (versiones las resuelve pub, se registran en el commit); `flutter_local_notifications` 19.5.0 ya instalado (detalles Linux/Windows de sus paquetes plataforma).

**Spec:** `docs/superpowers/specs/2026-10-23-notificaciones-push-telefono-pc-design.md` (§6 PC; menú §5) — el plan argumenta desde él.

**Workdir:** `/opt/dev/efe_mobile`, rama `feat/desktop-tray` (worktree según `using-git-worktrees` al ejecutar).

## Global Constraints

- **Solo Windows/Linux** (`Platform.isWindows || Platform.isLinux`, helper `isDesktopApp`). Android/web/iOS intactos: el coordinator hace early-return fuera de desktop y ningún código desktop corre en móvil.
- Sin FCM en desktop; sin servicio de SO separado (spec D2). Sin pantalla de preferencias (spec D6).
- `routeForPush()` del Plan 2 se reutiliza sin cambios para el destino del tap.
- `SecureStorage` NO se extiende (lección Planes 2–3: rompería ~13 fakes): el flag de autostart vive en `DesktopSettings` nuevo con fake propio.
- `watchNotifications` SÍ cambia de firma (un solo punto de suscripción, sin duplicar listeners): se actualizan su único caller productivo + los 5 fakes + su test.
- Copy nuevo solo vía l10n es/en. `flutter analyze` limpio antes de cada commit.
- Windows se compila en máquina Windows (CI solo Linux); GUID de toasts nunca cambia.

## Review Focus

1. **Payload sin `url`/`message` (el backend cambia el shape)** → toast vacío o crash en vez de fallback → test `fromPayload` con claves faltantes (Task 2).
2. **Doble login/logout duplica la suscripción** → toasts duplicados → test de coordinator con fakes: segundo login mismo usuario mantiene 1 suscripción (Task 3).
3. **Logout no cancela** → toasts post-logout → test de stop en coordinator (Task 3).
4. **Toggle de autostart no refleja estado / no llama enable-disable** → test del builder de menú con callbacks grabados (Task 2).
5. **Flag de autostart no persiste entre arranques** → se re-pregunta/re-activa cada vez → test de roundtrip en `DesktopSettings` (Task 2).

## File Structure

| Acción | Archivo | Responsabilidad |
|---|---|---|
| Modify | `pubspec.yaml` | `window_manager`, `system_tray`, `launch_at_startup` |
| Modify | `lib/core/realtime/realtime_service.dart` | `onNotification` recibe `Map<String,dynamic>` |
| Modify | `lib/core/realtime/realtime_providers.dart` | Adapta el único caller (`(_) => resync()`) |
| Modify | `lib/core/notifications/local_notifications_service.dart` | `showDesktopToast` + init Linux/Windows |
| Create | `lib/features/desktop/desktop_toast.dart` | `DesktopToast.fromPayload` puro |
| Create | `lib/features/desktop/desktop_tray.dart` | `TrayManager` + `buildTrayMenu` + icono |
| Create | `lib/features/desktop/desktop_session.dart` | `isDesktopApp`, `launchMinimized`, `DesktopSession.init`, listener X→ocultar |
| Create | `lib/features/desktop/data/desktop_settings.dart` | Flag `tray_autostart_configured` |
| Create | `lib/features/desktop/providers/desktop_providers.dart` | `desktopSettingsProvider`, `desktopCoordinatorProvider` |
| Modify | `lib/main.dart` | `main(List<String> args)` + init desktop |
| Modify | `lib/app/app.dart` | `ref.watch(desktopCoordinatorProvider)` |
| Modify | `lib/l10n/app_es.arb`, `lib/l10n/app_en.arb` | `trayOpen/trayAutostart/trayQuit` |
| Tests | `test/features/desktop/desktop_toast_test.dart`, `desktop_tray_menu_test.dart`, `desktop_args_test.dart`, `desktop_settings_test.dart`, `desktop_coordinator_test.dart` | Unidades + coordinator con fakes |
| Update | 5 fakes con `watchNotifications` + `test/core/realtime/realtime_service_test.dart` | Firma nueva |

---

### Task 1: `watchNotifications` entrega el payload

**Files:**
- Modify: `lib/core/realtime/realtime_service.dart`, `lib/core/realtime/realtime_providers.dart`
- Update (firma en fakes): `test/app/app_lifecycle_refresh_test.dart`, `test/core/realtime/realtime_providers_test.dart`, `test/features/chat/chat_list_live_test.dart`, `test/features/chat/chat_detail_widgets_test.dart`, `test/features/chat/connection_banner_test.dart`
- Update: `test/core/realtime/realtime_service_test.dart` (test `watchNotifications fires on notification.sent`)

**Interfaces:**
- Produce: `Subscription watchNotifications({required String userId, required void Function(Map<String, dynamic> data) onNotification})` con `listen('.notification.sent', (data) => onNotification(Map<String, dynamic>.from(data as Map)))`. Lo consumen Task 3 y el caller móvil adaptado.

- [ ] **Step 1: Cambiar la firma y adaptar** — servicio (cast del payload), coordinator móvil (`onNotification: (_) => resync()`), los 5 fakes (`void Function() onNotification` → `void Function(Map<String, dynamic> data) onNotification`, cuerpos intactos), y el test del servicio (emite mapa con campos y afirma recepción + contenido):

```dart
test('watchNotifications entrega el payload de notification.sent', () async {
  await service.connect();
  Map<String, dynamic>? received;
  final subscription = service.watchNotifications(
    userId: '7',
    onNotification: (data) => received = data,
  );
  await pumpEventQueue();

  fake.emit('private-notifications.7', 'notification.sent',
      {'id': '9', 'title': 'Hola', 'message': 'Cuerpo'});
  await pumpEventQueue();

  expect(received, {'id': '9', 'title': 'Hola', 'message': 'Cuerpo'});
  subscription.cancel();
});
```

(reemplaza el test anterior que solo contaba; adaptar nombres de helpers del archivo real).

- [ ] **Step 2: Correr y verificar**

Run: `flutter test test/core/realtime/ test/app/app_lifecycle_refresh_test.dart test/features/chat/chat_list_live_test.dart test/features/chat/chat_detail_widgets_test.dart test/features/chat/connection_banner_test.dart`
Expected: ALL PASSED.

- [ ] **Step 3: Analyze + commit**

Run: `flutter analyze` → sin errores/warnings.
```bash
git add lib/core/realtime/ test/core/realtime/realtime_service_test.dart test/app/app_lifecycle_refresh_test.dart test/core/realtime/realtime_providers_test.dart test/features/chat/chat_list_live_test.dart test/features/chat/chat_detail_widgets_test.dart test/features/chat/connection_banner_test.dart
git commit -m "feat(desktop): watchNotifications entrega el payload del evento"
```

---

### Task 2: Unidades desktop puras (toast, menú, args, settings)

**Files:**
- Create: `lib/features/desktop/desktop_toast.dart`, `lib/features/desktop/desktop_tray.dart` (solo `buildTrayMenu` + callbacks; el resto del tray va en Task 3), `lib/features/desktop/desktop_session.dart` (solo `isDesktopApp` + `launchMinimized`; `DesktopSession.init` va en Task 3), `lib/features/desktop/data/desktop_settings.dart`
- Create: `test/features/desktop/desktop_toast_test.dart`, `desktop_tray_menu_test.dart`, `desktop_args_test.dart`, `desktop_settings_test.dart`

**Interfaces — firmar EXACTO:**
- `class DesktopToast { final String title, body, route; factory DesktopToast.fromPayload(Map<String, dynamic> payload) }` con `title ← payload['title'] ?? ''`, `body ← payload['message'] ?? ''` (el backend manda `message`, no `body`), `route ← routeForPush(payload['url'] as String?)`.
- `List<MenuItemBase> buildTrayMenu({required String openLabel, required String autostartLabel, required String quitLabel, required bool autostartEnabled, required void Function() onOpen, required void Function() onToggleAutostart, required void Function() onQuit})` — orden: abrir, separador, autostart con sufijo `' ✓'` si activo, separador, salir. (Sufijo en vez de checkbox: a prueba de versiones de `system_tray`; solo exige label/onClicked/separador.)
- `bool launchMinimized(List<String> args) => args.contains('--minimized');` + `bool get isDesktopApp => Platform.isWindows || Platform.isLinux;`
- `class DesktopSettings { DesktopSettings({FlutterSecureStorage? storage}); Future<bool> isAutostartConfigured(); Future<void> markAutostartConfigured(); }` (clave propia `tray_autostart_configured='1'`; NUNCA en `SecureStorage`).

- [ ] **Step 1: Escribir los tests fallidos**:

```dart
// desktop_toast_test.dart — payload con el shape exacto del backend:
test('fromPayload mapea shape del backend y fallback', () {
  final t = DesktopToast.fromPayload({
    'id': 9, 'title': 'Aviso', 'message': 'Cuerpo', 'type': 'general',
    'url': '/platform/chat/7', 'created_at': '2026-01-01T00:00:00Z',
  });
  expect(t.title, 'Aviso'); expect(t.body, 'Cuerpo'); expect(t.route, '/chat/7');
  final unknown = DesktopToast.fromPayload({'title': 'X', 'url': '/platform/nada'});
  expect(unknown.route, '/notifications'); expect(unknown.body, '');
  expect(DesktopToast.fromPayload({}).route, '/notifications');
});

// desktop_tray_menu_test.dart:
test('menú en orden con toggle marcado y callbacks', () {
  final calls = <String>[];
  final menu = buildTrayMenu(openLabel: 'Abrir EFE', autostartLabel: 'Iniciar con el sistema',
      quitLabel: 'Salir', autostartEnabled: true,
      onOpen: () => calls.add('open'), onToggleAutostart: () => calls.add('toggle'), onQuit: () => calls.add('quit'));
  expect((menu[0] as MenuItemLabel).label, 'Abrir EFE');
  expect((menu[2] as MenuItemLabel).label, 'Iniciar con el sistema ✓');
  expect((menu[4] as MenuItemLabel).label, 'Salir');
});

// desktop_args_test.dart:
test('launchMinimized detecta el flag', () {
  expect(launchMinimized(['--minimized']), isTrue);
  expect(launchMinimized([]), isFalse);
});

// desktop_settings_test.dart (fake storage en memoria):
test('flag de autostart persiste', () async {
  final s = DesktopSettings(storage: _MemorySecureStorage());
  expect(await s.isAutostartConfigured(), isFalse);
  await s.markAutostartConfigured();
  expect(await s.isAutostartConfigured(), isTrue);
});
```

- [ ] **Step 2: Correr y verificar que fallan**

Run: `flutter test test/features/desktop/`
Expected: FAIL (archivos inexistentes).

- [ ] **Step 3: Implementar** los 4 archivos Dart según Firmas.

- [ ] **Step 4: Correr y verificar que pasan** — mismo comando, ALL PASSED.

- [ ] **Step 5: Analyze + commit**

Run: `flutter analyze` → sin errores/warnings.
```bash
git add lib/features/desktop/ test/features/desktop/
git commit -m "feat(desktop): unidades puras (toast, menú, args, settings)"
```

---

### Task 3: Sesión desktop (ventana, bandeja, autostart, coordinator)

**Files:**
- Modify: `pubspec.yaml` (`flutter pub add window_manager system_tray launch_at_startup`; registrar versiones resueltas en el reporte)
- Modify: `lib/core/notifications/local_notifications_service.dart` (+ `showDesktopToast`, init Linux/Windows)
- Completar: `lib/features/desktop/desktop_tray.dart` (`TrayManager`, `resolveTrayIconPath`, wiring del menú), `lib/features/desktop/desktop_session.dart` (`DesktopSession.init`, listener X→ocultar)
- Create: `lib/features/desktop/providers/desktop_providers.dart` (`desktopSettingsProvider`, `desktopCoordinatorProvider`)
- Modify: `lib/main.dart` (`main(List<String> args)` + init), `lib/app/app.dart` (watch), `lib/l10n/app_es.arb` + `app_en.arb` (`trayOpen/trayAutostart/trayQuit`)
- Create: `test/features/desktop/desktop_coordinator_test.dart`

**Interfaces — firmar EXACTO:**
- l10n: `trayOpen` "Abrir EFE"/"Open EFE", `trayAutostart` "Iniciar con el sistema"/"Launch at startup", `trayQuit` "Salir"/"Quit".
- `static Future<void> DesktopSession.init({required List<String> args})` (solo invocado con `isDesktopApp`): `windowManager.ensureInitialized()` → `WindowOptions(size: Size(1280, 800), center: true, title: 'EFE')` → `waitUntilReadyToShow` → `launchMinimized(args) ? hide() : show()` → `setPreventClose(true)` + listener ocultar-al-cerrar → tray init (icono de `resolveTrayIconPath()`, menú con estado actual, clic→mostrar, resto→menú) → `launchAtStartup.setup(appName: 'EFE', appPath: Platform.resolvedExecutable, args: ['--minimized'])` → si `!isAutostartConfigured()` → `enable()` best-effort + marcar. Todo envuelto para jamás romper el arranque.
- `Future<String> resolveTrayIconPath()`: bytes de `assets/images/efe_logo_white.png` vía rootBundle a `getTemporaryDirectory()/efe_tray_icon.png` (reutiliza si existe).
- `LocalNotificationsService`: init acepta `linux: LinuxInitializationSettings(defaultActionName: 'Open')` y `windows: WindowsInitializationSettings(appName: 'EFE', appUserModelId: 'com.efe.efe_mobile', guid: 'f86b19c8-435c-4222-b8cd-21112e9f3bbf')` (**GUID fijo, no cambiar jamás**); nuevo `showDesktopToast(DesktopToast toast)` con `LinuxNotificationDetails()` / `WindowsNotificationDetails()` y `payload: toast.route`, id autoincremental.
- `desktopCoordinatorProvider`: espejo del push (guard no-desktop early-return, `ref.listen(authProvider)` + arranque en frío, un solo juego de suscripciones): login → `local.init(onTap: (route) async { await windowManager.show(); await windowManager.focus(); router.go(route); })` + `service.watchNotifications(userId:, onNotification: (data) async { final toast = DesktopToast.fromPayload(data); await local.showDesktopToast(toast); ref.invalidate(unreadCountProvider); ref.invalidate(notificationListProvider); })`; logout → cancela suscripción (la bandeja persiste, sin eventos). Sin listener de reconexión propio: el resync de badge ante reconexión lo aporta el `realtimeCoordinatorProvider` existente sobre el mismo servicio compartido (los toasts caídos en el corte se pierden por diseño del spec).
- Tray toggle: `onToggleAutostart` → `isEnabled() ? disable() : enable()` + reconstruye el menú con el estado nuevo. Salir real: `onQuit` → `await windowManager.destroy()` (no `close()`, que con `preventClose` ocultaría).

- [ ] **Step 1: Deps**

Run: `flutter pub add window_manager system_tray launch_at_startup` (anotar versiones resueltas en el reporte). Verificar APIs contra las versiones instaladas (`MenuItemBase/MenuItemLabel/MenuSeparator`, `launchAtStartup.setup/enable/disable/isEnabled`, `windowManager.ensureInitialized/waitUntilReadyToShow/setPreventClose/show/hide/focus/destroy/addListener`, `WindowListener.onWindowClose`, `WindowOptions`); si alguna difiere, adaptar lo mínimo y reportar el desvío (no bajar versiones).

- [ ] **Step 2: Escribir el test del coordinator fallido** (con fakes, espejo de `test/core/realtime/realtime_providers_test.dart`):

```dart
test('login suscribe una vez, payload muestra toast, logout cancela', () async {
  // fakes: RealtimeService (graba watchNotifications), LocalNotificationsService subclase que graba showDesktopToast,
  // container con overrides; login → watch == 1; emitir payload chat → toast.route == '/chat/7' y show == 1;
  // segundo login mismo usuario → watch sigue == 1; logout → suscripción cancelada; nuevo login → watch == 2.
});
```

- [ ] **Step 3: Correr y verificar que falla** — el test no compila / coordinator no existe.

- [ ] **Step 4: Implementar** tray + sesión + providers + coordinator + wiring main/app + claves arb (3+3).

- [ ] **Step 5: Correr** — coordinator test PASS + `flutter test test/features/desktop/ test/core/realtime/` PASS.

- [ ] **Step 6: Analyze + commit**

Run: `flutter analyze` → sin errores/warnings.
```bash
git add pubspec.yaml pubspec.lock lib/core/notifications/local_notifications_service.dart lib/features/desktop/ lib/main.dart lib/app/app.dart lib/l10n/app_es.arb lib/l10n/app_en.arb test/features/desktop/desktop_coordinator_test.dart
git commit -m "feat(desktop): residencia en bandeja, autostart y toasts"
```

---

### Task 4: Verificación integral + aceptación en máquinas reales

- [ ] **Step 1: Suite y análisis**

Run: `flutter analyze` → sin errores/warnings. Run: `flutter test` → toda PASS (comparar contra baseline de `master`).

- [ ] **Step 2: Build Linux**

Run: `flutter build linux --release` → BUILD SUCCESSFUL (requiere toolchain: clang/cmake/ninja, ya presentes). Si faltan headers de ayatana en la máquina, el build igual pasa (solo afecta la bandeja en runtime).

- [ ] **Step 3: Aceptación manual Linux** (binario `build/linux/*/release/bundle/efe_mobile` + `.env` de preprod junto al ejecutable o embebido):
  1. Bandeja visible (si no: `libayatana-appindicator3-dev` + relogin).
  2. X oculta sin salir (`ps` sigue vivo); clic en bandeja → ventana.
  3. Menú: Abrir / toggle autostart (persiste tras reinicio, `~/.config/autostart/`) / Salir (proceso termina).
  4. `test-push-user` → toast visible; clic → ventana al destino.
  5. Arranque con `--minimized` → sin ventana, con bandeja.
  6. Logout → sin toasts; login → vuelven.

- [ ] **Step 4: Aceptación manual Windows** (build en máquina Windows con VS Build Tools; misma checklist; toasts en Action Center).

- [ ] **Step 5: Commit final si hubo ajustes** (solo archivos tocados; si no hubo, sin commit).
