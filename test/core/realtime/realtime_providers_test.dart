import 'dart:async';

import 'package:efe_mobile/core/realtime/realtime_providers.dart';
import 'package:efe_mobile/core/realtime/realtime_service.dart';
import 'package:efe_mobile/features/auth/data/auth_repository.dart';
import 'package:efe_mobile/features/auth/domain/user_model.dart';
import 'package:efe_mobile/features/auth/providers/auth_provider.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:laravel_reverb/laravel_reverb.dart';

const _user = UserModel(id: '7', name: 'Ada', email: 'ada@example.com');

// ---------------------------------------------------------------------------
// Fakes
// ---------------------------------------------------------------------------

/// Repository that never resolves: keeps the real [AuthNotifier] constructor
/// from transitioning away from the state the test sets by hand.
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

/// Records every call the coordinator makes; `disconnect(forget: true)`
/// mirrors [RealtimeService.disconnect]: it drops listeners and channels.
class _FakeRealtimeService implements RealtimeService {
  int connectCalls = 0;
  final List<bool> disconnectCalls = <bool>[];
  final List<String> notificationUserIds = <String>[];
  final List<_FakeSubscription> notificationSubscriptions =
      <_FakeSubscription>[];
  final Set<void Function()> reconnectListeners = <void Function()>{};

  final StreamController<ReverbState> _states =
      StreamController<ReverbState>.broadcast();
  bool connected = false;
  void Function()? _lastNotificationCallback;

  @override
  bool get isConnected => connected;

  @override
  Stream<ReverbState> get states => _states.stream;

  @override
  Future<void> connect() async {
    connectCalls++;
    connected = true;
  }

  @override
  Future<void> disconnect({bool forget = false}) async {
    disconnectCalls.add(forget);
    connected = false;
    if (forget) {
      reconnectListeners.clear();
      for (final subscription in notificationSubscriptions) {
        subscription.cancelled = true;
      }
      notificationSubscriptions.clear();
    }
  }

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
    required void Function() onNotification,
  }) {
    notificationUserIds.add(userId);
    _lastNotificationCallback = onNotification;
    final subscription = _FakeSubscription();
    notificationSubscriptions.add(subscription);
    return subscription;
  }

  @override
  VoidCallback addReconnectListener(void Function() listener) {
    reconnectListeners.add(listener);
    return () => reconnectListeners.remove(listener);
  }

  @override
  void sendTyping({
    required String chatId,
    required bool typing,
    required String userId,
  }) {}

  void fireReconnect() {
    for (final listener in List<void Function()>.of(reconnectListeners)) {
      listener();
    }
  }

  void emitNotification() => _lastNotificationCallback?.call();

  void emitState(ReverbState state) => _states.add(state);
}

// ---------------------------------------------------------------------------
// Harness
// ---------------------------------------------------------------------------

class _Harness {
  _Harness({
    AuthStatus initialStatus = AuthStatus.unauthenticated,
    UserModel? initialUser,
    void Function()? resync,
  }) {
    auth = _TestAuthNotifier();
    if (initialStatus == AuthStatus.authenticated && initialUser != null) {
      auth.signIn(initialUser);
    }
    service = _FakeRealtimeService();
    container = ProviderContainer(
      overrides: [
        realtimeServiceProvider.overrideWithValue(service),
        authProvider.overrideWith((ref) => auth),
        if (resync != null) realtimeResyncProvider.overrideWithValue(resync),
      ],
    );
    addTearDown(container.dispose);
  }

  late final _TestAuthNotifier auth;
  late final _FakeRealtimeService service;
  late final ProviderContainer container;

  /// Mounts the coordinator the same way the app does when it first reads it.
  void mountCoordinator() {
    container.read(realtimeCoordinatorProvider);
  }
}

void main() {
  test('connecting is requested when the session becomes authenticated',
      () async {
    final harness = _Harness();
    harness.mountCoordinator();
    await pumpEventQueue();

    expect(harness.service.connectCalls, 0);

    harness.auth.signIn(_user);
    await pumpEventQueue();

    expect(harness.service.connectCalls, 1);
  });

  test('notifications channel is watched for the logged in user id', () async {
    final harness = _Harness(
      initialStatus: AuthStatus.authenticated,
      initialUser: _user,
    );
    harness.mountCoordinator();
    await pumpEventQueue();

    expect(harness.service.notificationUserIds, ['7']);
    expect(harness.service.connectCalls, 1);
  });

  test('disconnect with forget clears every channel and listener', () async {
    var resyncCalls = 0;
    final harness = _Harness(
      initialStatus: AuthStatus.authenticated,
      initialUser: _user,
      resync: () {
        resyncCalls++;
      },
    );
    harness.mountCoordinator();
    await pumpEventQueue();

    expect(harness.service.notificationSubscriptions.single.cancelled, isFalse);
    expect(harness.service.reconnectListeners, isNotEmpty);

    harness.auth.signOut();
    await pumpEventQueue();

    expect(harness.service.disconnectCalls, [true]);
    expect(harness.service.notificationSubscriptions, isEmpty);
    expect(harness.service.reconnectListeners, isEmpty);

    // The removed listener can no longer reach the resync hook.
    harness.service.fireReconnect();
    expect(resyncCalls, 0);
  });

  test('no connection attempt happens while unauthenticated', () async {
    final harness = _Harness();
    harness.mountCoordinator();
    await pumpEventQueue();

    expect(harness.service.connectCalls, 0);
    expect(harness.service.disconnectCalls, isEmpty);
  });

  test('reconnect fires the injected resync hook', () async {
    var resyncCalls = 0;
    final harness = _Harness(
      initialStatus: AuthStatus.authenticated,
      initialUser: _user,
      resync: () {
        resyncCalls++;
      },
    );
    harness.mountCoordinator();
    await pumpEventQueue();

    harness.service.fireReconnect();
    expect(resyncCalls, 1);
  });

  test('an incoming notification fires the injected resync hook', () async {
    var resyncCalls = 0;
    final harness = _Harness(
      initialStatus: AuthStatus.authenticated,
      initialUser: _user,
      resync: () {
        resyncCalls++;
      },
    );
    harness.mountCoordinator();
    await pumpEventQueue();

    harness.service.emitNotification();
    expect(resyncCalls, 1);
  });

  test('realtimeReadyProvider requires both session and connection', () async {
    final harness = _Harness();
    harness.mountCoordinator();
    await pumpEventQueue();

    expect(harness.container.read(realtimeReadyProvider), isFalse);

    harness.auth.signIn(_user);
    await pumpEventQueue();
    expect(harness.container.read(realtimeReadyProvider), isFalse);

    harness.service.emitState(ReverbState.connected);
    await pumpEventQueue();
    expect(harness.container.read(realtimeReadyProvider), isTrue);

    harness.auth.signOut();
    await pumpEventQueue();
    expect(harness.container.read(realtimeReadyProvider), isFalse);
  });
}
