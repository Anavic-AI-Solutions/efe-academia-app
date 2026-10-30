import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:laravel_reverb/laravel_reverb.dart';
import 'package:window_manager/window_manager.dart';

import '../../../app/router.dart';
import '../../../core/realtime/realtime_providers.dart';
import '../../auth/providers/auth_provider.dart';
import '../../notifications/providers/notification_provider.dart';
import '../../push/providers/push_coordinator.dart';
import '../desktop_session.dart';
import '../desktop_toast.dart';

/// Coordinador único del ciclo de vida desktop ligado a `authProvider`.
///
/// Espeja [realtimeCoordinatorProvider] / [pushCoordinatorProvider]: sesión
/// `authenticated` → inicializa los avisos locales (el toque muestra y
/// enfoca la ventana y navega) y suscribe `notifications.{userId}` mostrando
/// un toast por evento; sesión no autenticada con sesión activa → cancela
/// la suscripción (la bandeja persiste, no hay eventos). El arranque en frío
/// (sesión ya restaurada) se atiende una vez al montar.
///
/// Solo escritorio: en cualquier otra plataforma es un no-op.
///
/// Sin listener de reconexión: el resync del badge lo aporta el coordinador
/// realtime existente sobre la instancia compartida de
/// [realtimeServiceProvider].
///
/// El router se lee de forma perezosa dentro del `onTap` para no construir
/// el `GoRouter` al montar (los tests unitarios nunca tocan un aviso).
final desktopCoordinatorProvider = Provider<void>((ref) {
  if (!isDesktopApp) return;

  final service = ref.watch(realtimeServiceProvider);
  final local = ref.watch(localNotificationsProvider);

  Subscription? notifications;
  String? activeUserId;

  Future<void> startSession(String userId) async {
    await local.init(
      onTap: (route) async {
        await windowManager.show();
        await windowManager.focus();
        ref.read(routerProvider).go(route);
      },
    );
    notifications ??= service.watchNotifications(
      userId: userId,
      onNotification: (data) async {
        final toast = DesktopToast.fromPayload(data);
        await local.showDesktopToast(toast);
        ref.invalidate(unreadCountProvider);
        ref.invalidate(notificationListProvider);
      },
    );
    activeUserId = userId;
  }

  Future<void> stopSession() async {
    notifications?.cancel();
    notifications = null;
    activeUserId = null;
  }

  Future<void> activate(String userId) async {
    if (activeUserId != null && activeUserId != userId) {
      await stopSession();
    }
    if (activeUserId == userId) return;
    await startSession(userId);
  }

  ref.listen<AuthState>(authProvider, (previous, next) {
    final user = next.user;
    if (next.status == AuthStatus.authenticated && user != null) {
      if (activeUserId == user.id) return;
      unawaited(activate(user.id));
    } else if (activeUserId != null) {
      unawaited(stopSession());
    }
  });

  // `ref.listen` solo ve cambios posteriores al montaje: el arranque en frío
  // (sesión restaurada por `AuthNotifier._init`) se atiende una vez aquí.
  final initial = ref.read(authProvider);
  final initialUser = initial.user;
  if (initial.status == AuthStatus.authenticated && initialUser != null) {
    unawaited(startSession(initialUser.id));
  }

  ref.onDispose(() {
    notifications?.cancel();
    notifications = null;
  });
});
