import 'dart:async';
import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../core/api/api_provider.dart';
import '../../../core/notifications/local_notifications_service.dart';
import '../../../core/notifications/notification_router.dart';
import '../../auth/providers/auth_provider.dart';
import '../../notifications/providers/notification_provider.dart';
import '../data/push_repository.dart';
import '../widgets/push_primer_sheet.dart';
import 'push_providers.dart';

/// Servicio de avisos locales, sobreescribible en tests.
final localNotificationsProvider = Provider<LocalNotificationsService>((ref) {
  return LocalNotificationsService();
});

/// Muestra el primer de permiso push una sola vez por dispositivo.
///
/// No-op fuera de Android o si ya se mostró. Si no hay un contexto de
/// navegación disponible, vuelve sin marcar (reintenta en el próximo login).
/// Marca la bandera en TODA vía de cierre (true/false/dismiss) para no
/// volver a preguntar. Si el usuario acepta, pide el permiso del SO y
/// re-registra el token cuando se otorga.
Future<void> showPushPrimerIfNeeded(Ref ref, GoRouter router) async {
  if (!Platform.isAndroid) return;
  final storage = ref.read(secureStorageProvider);
  if (await storage.hasSeenPushPrimer()) return;
  final context = router.routerDelegate.navigatorKey.currentContext;
  if (context == null) return;
  final result = await showModalBottomSheet<bool>(
    context: context,
    builder: (_) => PushPrimerSheet(
      onResult: (v) => Navigator.pop(context, v),
    ),
  );
  await storage.savePushPrimerSeen();
  if (result == true) {
    final tokens = ref.read(pushTokenProviderProvider);
    final repo = ref.read(pushRepositoryProvider);
    final permission = await tokens.requestPermission();
    if (permission == PushPermission.granted) {
      await repo.ensureRegistered();
    }
  }
}

/// Coordinador único del ciclo de vida push (FCM) ligado a `authProvider`.
///
/// Espeja [realtimeCoordinatorProvider]: sesión `authenticated` → registra
/// el token, muestra avisos en primer plano y navega al tocar; sesión no
/// autenticada con sesión activa → cancela las suscripciones. El arranque
/// en frío (sesión ya restaurada) se atiende una vez al montar.
///
/// Solo Android: en cualquier otra plataforma es un no-op.
final pushCoordinatorProvider = Provider<void>((ref) {
  if (!Platform.isAndroid) return;

  final repo = ref.watch(pushRepositoryProvider);
  final local = ref.watch(localNotificationsProvider);
  final router = ref.watch(routerProvider);

  StreamSubscription<RemoteMessage>? foreground;
  StreamSubscription<RemoteMessage>? opened;
  StreamSubscription<String>? refreshes;
  String? activeUserId;

  Future<void> startSession() async {
    await local.init(onTap: router.go);
    foreground ??= FirebaseMessaging.onMessage.listen((m) {
      ref.invalidate(unreadCountProvider);
      ref.invalidate(notificationListProvider);
      final url = m.data['url'] as String?;
      unawaited(
        local.showPush(
          title: m.notification?.title,
          body: m.notification?.body,
          route: routeForPush(url),
          isChat: (url ?? '').startsWith('/platform/chat'),
        ),
      );
    });
    opened ??= FirebaseMessaging.onMessageOpenedApp.listen((m) {
      router.go(routeForPush(m.data['url'] as String?));
    });
    refreshes ??= repo.tokenRefreshes.listen((_) {
      unawaited(repo.ensureRegistered());
    });
    await repo.ensureRegistered();
    await showPushPrimerIfNeeded(ref, router);
    final initial = await FirebaseMessaging.instance.getInitialMessage();
    if (initial != null) {
      router.go(routeForPush(initial.data['url'] as String?));
    }
  }

  Future<void> stopSession() async {
    await foreground?.cancel();
    await opened?.cancel();
    await refreshes?.cancel();
    foreground = null;
    opened = null;
    refreshes = null;
    activeUserId = null;
  }

  Future<void> activate(String userId) async {
    if (activeUserId != null && activeUserId != userId) {
      await stopSession();
    }
    if (activeUserId == userId) return;
    activeUserId = userId;
    await startSession();
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
    unawaited(activate(initialUser.id));
  }

  ref.onDispose(() {
    unawaited(stopSession());
  });
});
