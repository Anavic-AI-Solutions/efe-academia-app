import 'dart:async';

import 'package:efe_mobile/core/api/cursor_pagination.dart';
import 'package:efe_mobile/core/notifications/local_notifications_service.dart';
import 'package:efe_mobile/core/realtime/realtime_providers.dart';
import 'package:efe_mobile/core/realtime/realtime_service.dart';
import 'package:efe_mobile/features/auth/data/auth_repository.dart';
import 'package:efe_mobile/features/auth/domain/user_model.dart';
import 'package:efe_mobile/features/auth/providers/auth_provider.dart';
import 'package:efe_mobile/features/desktop/desktop_toast.dart';
import 'package:efe_mobile/features/desktop/providers/desktop_providers.dart';
import 'package:efe_mobile/features/notifications/data/notification_repository.dart';
import 'package:efe_mobile/features/notifications/domain/notification_model.dart';
import 'package:efe_mobile/features/notifications/providers/notification_provider.dart';
import 'package:efe_mobile/features/push/providers/push_coordinator.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:laravel_reverb/laravel_reverb.dart';

const _user = UserModel(id: '7', name: 'Ada', email: 'ada@example.com');

// ---------------------------------------------------------------------------
// Fakes (mismo patrón que test/core/realtime/realtime_providers_test.dart)
// ---------------------------------------------------------------------------

/// Repository que nunca resuelve: el [AuthNotifier] real no transiciona solo.
class _NeverAuthRepository implements AuthRepository {
  @override
  Future<bool> hasToken() => Completer<bool>().future;

  @override
  Future<UserModel> getCurrentUser() => Future.error(UnimplementedError());

  @override
  Future<UserModel> login({
    required String email,
    required String password,
  }) =>
      Future.error(UnimplementedError());

  @override
  Future<UserModel> register({
    required String name,
    required String email,
    required String password,
    required String passwordConfirmation,
  }) =>
      Future.error(UnimplementedError());

  @override
  Future<void> logout() async {}

  @override
  Future<void> forgotPassword(String email) =>
      Future.error(UnimplementedError());

  @override
  Future<void> loadTokenIntoClient() async {}
}

class _TestAuthNotifier extends AuthNotifier {
  _TestAuthNotifier() : super(_NeverAuthRepository());

  void signIn(UserModel user) {
    state = AuthState(status: AuthStatus.authenticated, user: user);
  }

  void signOut() {
    state = const AuthState(status: AuthStatus.unauthenticated);
  }
}

class _FakeSubscription implements Subscription {
  bool cancelled = false;

  @override
  void cancel() => cancelled = true;

  @override
  Subscription listen(String event, ReverbEventCallback callback) => this;

  @override
  Subscription listenForWhisper(String event, ReverbEventCallback callback) =>
      this;

  @override
  Subscription listenAll(ReverbWildcardCallback callback) => this;
}

/// Registra cada `watchNotifications`; expone el último callback para emitir.
class _FakeRealtimeService implements RealtimeService {
  final List<String> notificationUserIds = <String>[];
  final List<_FakeSubscription> notificationSubscriptions =
      <_FakeSubscription>[];
  void Function(Map<String, dynamic> data)? lastCallback;

  @override
  bool get isConnected => false;

  @override
  Stream<ReverbState> get states => const Stream.empty();

  @override
  Stream<ReverbState> statesWithCurrent() =>
      Stream<ReverbState>.value(ReverbState.disconnected);

  @override
  Future<void> connect() async {}

  @override
  Future<void> disconnect({bool forget = false}) async {}

  @override
  Subscription watchChat({
    required String chatId,
    required void Function(Map<String, dynamic> data) onMessage,
    required void Function(Map<String, dynamic> data) onRead,
    required void Function(Map<String, dynamic> data) onTyping,
  }) {
    return _FakeSubscription();
  }

  @override
  Subscription watchNotifications({
    required String userId,
    required void Function(Map<String, dynamic> data) onNotification,
  }) {
    notificationUserIds.add(userId);
    lastCallback = onNotification;
    final subscription = _FakeSubscription();
    notificationSubscriptions.add(subscription);
    return subscription;
  }

  @override
  VoidCallback addReconnectListener(void Function() listener) => () {};

  @override
  void sendTyping({
    required String chatId,
    required bool typing,
    required String userId,
  }) {}

  void emit(Map<String, dynamic> data) => lastCallback?.call(data);
}

/// Subclase que registra `init`/`showDesktopToast` sin tocar platform
/// channels (el coordinador nunca debe llamar a windowManager/tray en tests).
class _FakeLocalNotifications extends LocalNotificationsService {
  int initCalls = 0;
  final List<DesktopToast> toasts = <DesktopToast>[];

  @override
  Future<void> init({required void Function(String route) onTap}) async {
    initCalls++;
  }

  @override
  Future<void> showDesktopToast(DesktopToast toast) async {
    toasts.add(toast);
  }
}

/// Repositorio inerte: los `invalidate` del coordinador sobre
/// `unreadCountProvider`/`notificationListProvider` no deben disparar fetches
/// reales (el notifier de la lista carga en su constructor).
class _InertNotificationRepository implements NotificationRepository {
  @override
  Future<CursorPagination<NotificationModel>> getNotifications({
    String? cursor,
  }) async =>
      CursorPagination<NotificationModel>.empty();

  @override
  Future<int> getUnreadCount() async => 0;

  @override
  Future<void> markAllRead() async {}

  @override
  Future<void> markRead(String id) async {}
}

class _Harness {
  _Harness() {
    auth = _TestAuthNotifier();
    service = _FakeRealtimeService();
    local = _FakeLocalNotifications();
    container = ProviderContainer(
      overrides: [
        realtimeServiceProvider.overrideWithValue(service),
        localNotificationsProvider.overrideWithValue(local),
        authProvider.overrideWith((ref) => auth),
        notificationRepositoryProvider
            .overrideWithValue(_InertNotificationRepository()),
      ],
    );
    // Pre-monta la lista con un listener activo: `ref.invalidate` sobre un
    // provider sin montar lo monta y lo reconstruye en el mismo paso
    // sincrónico, y el `load()` del constructor pondría `state` sobre un
    // notifier ya dispuesto. Con el listener, el `load()` inicial ya
    // terminó cuando llega el invalidate del coordinador.
    container.listen<NotificationListState>(
      notificationListProvider,
      (previous, next) {},
    );
    addTearDown(container.dispose);
  }

  late final _TestAuthNotifier auth;
  late final _FakeRealtimeService service;
  late final _FakeLocalNotifications local;
  late final ProviderContainer container;

  void mountCoordinator() {
    container.read(desktopCoordinatorProvider);
  }
}

void main() {
  test('login suscribe una vez, payload muestra toast, logout cancela',
      () async {
    final harness = _Harness();
    harness.mountCoordinator();
    await pumpEventQueue();

    expect(harness.service.notificationUserIds, isEmpty);

    // Login → una sola suscripción al canal del usuario.
    harness.auth.signIn(_user);
    await pumpEventQueue();
    await pumpEventQueue();

    expect(harness.service.notificationUserIds, ['7']);
    expect(harness.local.initCalls, 1);

    // Payload de chat → toast con ruta resuelta y un solo show.
    harness.service.emit(<String, dynamic>{
      'title': 'Nuevo mensaje',
      'message': 'Hola',
      'url': '/platform/chat/7',
    });
    await pumpEventQueue();
    await pumpEventQueue();

    expect(harness.local.toasts, hasLength(1));
    expect(harness.local.toasts.single.route, '/chat/7');

    // Segundo login del mismo usuario (sin logout) → sin re-suscripción.
    harness.auth.signIn(_user);
    await pumpEventQueue();
    await pumpEventQueue();

    expect(harness.service.notificationUserIds, ['7']);

    // Logout → suscripción cancelada, sin nuevas suscripciones.
    harness.auth.signOut();
    await pumpEventQueue();

    expect(harness.service.notificationSubscriptions.single.cancelled, isTrue);
    expect(harness.service.notificationUserIds, ['7']);

    // Nuevo login → re-suscribe exactamente una vez más (total 2).
    harness.auth.signIn(_user);
    await pumpEventQueue();
    await pumpEventQueue();

    expect(harness.service.notificationUserIds, ['7', '7']);
  });
}
