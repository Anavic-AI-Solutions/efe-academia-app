# Spec — Notificaciones push al teléfono y PC

**Fecha:** 2026-10-23 · **Repos:** `efe_mobile` (Flutter) + `efe-app` (Laravel)

## 1. Problema y objetivo

Hoy las notificaciones solo viven *in-app* (lista + badge vía Reverb) y el navegador. **Objetivo:** todo mensaje/notificación de la app cae como **notificación nativa en el teléfono (APK Android)** — incluso con la app cerrada — y en el **PC (app de escritorio Windows/Linux)**, incluida con la ventana cerrada (residencia en bandeja).

## 2. Decisiones acordadas (con el usuario)

| # | Decisión |
|---|---|
| D1 | Teléfono = **FCM** sobre el proyecto Firebase existente `efe-app-d3d42` (mismo que ya usa el backend). |
| D2 | PC = **Enfoque A: residente en bandeja** integrado a la app de escritorio (autostart + tray + socket Reverb + toast nativo). Servicio de SO separado queda descartado. |
| D3 | Alcance = **todas** las notificaciones (Familia 1 + Familia 2 de la auditoría). |
| D4 | Desktop soporta **Windows y Linux**; foco móvil = **APK Android**. |
| D5 | Navegador web (web push) ya existe y **no se toca**. |
| D6 | No-alcance: iOS, pantalla de preferencias por categoría (YAGNI), resurrección de toasts viejos (solo badge resync). |

**Prerrequisito del usuario:** registrar app Android `com.efe.efe_mobile` en consola Firebase del proyecto `efe-app-d3d42` y bajar `google-services.json`.

## 3. Arquitectura — tres destinos, un emisor

```
Evento (chat, pago, ausencia, broadcast, …)
        │
        ▼
NotificationService::deliver()          ← EMISOR ÚNICO (D3)
        ├── Reverb  → PC en bandeja (toast) + badge in-app
        ├── FCM     → teléfono (cerrada/bg: sistema · abierta: local)
        └── (WebPush/email donde la clase ya lo tenga) → navegador
```

Cada notificación ⇒ **exactamente 1 push al teléfono y 1 evento al PC**.

## 4. Teléfono (APK Android)

- **Deps**: `firebase_core`, `firebase_messaging`, `flutter_local_notifications`.
- **Token**: login OK → `requestPermission()` (Android 13+) → token → `POST api/v1/push/register` (`token`, `platform: 'android'`, `device_id` = UUID en secure storage). `onTokenRefresh` re-registra. Logout → `push/unregister`. Fallo de red → reintento al reconectar, nunca bloquea login.
- **Recepción**: cerrada/bg → mensaje FCM *notification* lo muestra el sistema (backend ya manda `priority: high`). Primer plano → `onMessage` → `flutter_local_notifications`. Tap → `onMessageOpenedApp` / `getInitialMessage`.
- **Ruteo**: `notification_router.dart` (compartido con desktop) mapea `url` (`/platform/chats/123`) + `type` + `notification_id` → rutas de la app (`/chat/{id}`, `/notifications`, …); desconocido → `/notifications`.
- **Canales**: canal "Mensajes" (sonido alto) y "General"; **`default_notification_channel` en manifest** apuntando al que crea la app al inicio (si no, Android 8+ descarta FCM sin `channel`). Icono small silhouette propio + permiso `POST_NOTIFICATIONS`.

## 5. UI nueva (anti-ui-slop)

- **Primer de permiso (única pantalla nueva)**: bottom sheet *una sola vez* tras el primer login, **antes** del diálogo del sistema. Patrón ya usado en la app (`showModalBottomSheet`). Copy en valor, en es/en vía l10n: título "Activá las notificaciones", cuerpo ("Los mensajes de chat y los avisos de la escuela te llegan aunque la app esté cerrada"), acción primaria "Activar" (dispara diálogo del sistema), secundaria "Ahora no" (nunca más insiste; badge in-app sigue funcionando). Estados: concedido/denegado/cancelado → cierra en los tres. Estilos del sistema existente (`AppColors.primary`, botones actuales), icono bell de phosphor.
- **Menú de bandeja (desktop)**: menú nativo del SO, 3 items: **Abrir EFE** · **Iniciar con el sistema** (toggle) · **Salir**. Sin UI propia que diseñar más allá del orden y las etiquetas (l10n).

## 6. PC — escritorio (Enfoque A)

- **Deps**: `window_manager`, `system_tray`, `flutter_local_notifications` (Linux/Windows), `launch_at_startup` *(verificar versiones en el plan)*.
- **Residencia**: X → oculta (no sale), socket vivo. Autostart activo por default (Run/`.desktop`), arranque con `--minimized`; toggle en bandeja. "Salir" = salida real (sin notificaciones hasta reabrir).
- **Recepción**: `watchNotifications` hoy **descarta el payload** → ahora lo entrega (`id, title, message, type, url`) a `flutter_local_notifications` → toast nativo. Clic → `window_manager.show()` + `notification_router.dart`.
- **Aislamiento**: `Platform.isWindows || isLinux`; Android/web no lo ejecutan.
- **Edge cases**: reconexión → resync badge (mecanismo ya existe); logout → `disconnect(forget)` → bandeja sin eventos; dormida → se pierden toasts, no el badge.
- **Nota ops**: Windows se compila en máquina Windows (CI actual solo Linux).

## 7. Backend (`efe-app`)

1. **Matriz de auditoría Familia 2** (~10 clases / ~20 sitios): si el flujo ya dispara `NotificationService::send()` → no tocar (evita doble push); si es único → añadir `send()` reutilizando `getTitle()/getBody()/getUrl()` de la clase (hacerlos públicos).
2. **Fix crítico**: 21k jobs fallidos (`failed_jobs`) de `FcmPushNotification` → diagnosticar (credenciales vs versión de `laravel-notification-channels/fcm`), corregir, purgar/reintentar. *Sin esto, el teléfono no recibe nada.*
3. **Resiliencia**: FCM en cola database (verificar worker), backoff; `404 token invalid` → borrar el token de `fcm_tokens`.
4. **Alineación de listas**: verificar que al tocar un push, la lista in-app (`app_notifications`) muestra el mismo elemento; si diverge (`job_notifications`), corregir en este trabajo.
5. **Verificación**: suite existente (`JobNotificationTest`) + tests por sitio auditado + `GET /test-push`.

## 8. Orden de implementación

`efe-app` (emisor único + fix FCM) → `efe_mobile` (teléfono) → `efe_mobile` desktop (bandeja). Cada eslabón es verificable por separado.

## 9. Criterios de aceptación

1. APK cerrada + mensaje de chat → notificación nativa visible; tocar → chat abierto.
2. Cada tipo de la matriz (pago, ausencia, broadcast, evento, ticket…) → ídem, **sin duplicados**.
3. PC con residencia activa → toast al recibir; clic → ventana en el destino.
4. Logout → sin pushes al teléfono; bandeja sin eventos.
5. `failed_jobs` FCM diagnosticado y corregido; `/test-push` entrega en dispositivo real.
6. `pint` + `flutter analyze` + tests de ambas suites en verde.

## 10. Riesgos abiertos

- `google-services.json` depende del usuario (Firebase console).
- Catálogo UIZZE sin resultados → primer diseñado contra el sistema propio de EFE.
- Incompatibilidad de versión FCM backend puede obligar a subir de paquete (confirmar en fase de fix).
