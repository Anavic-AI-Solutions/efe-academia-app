import 'dart:async';

import 'package:efe_mobile/core/api/cursor_pagination.dart';
import 'package:efe_mobile/core/realtime/realtime_providers.dart';
import 'package:efe_mobile/core/realtime/realtime_service.dart';
import 'package:efe_mobile/features/auth/data/auth_repository.dart';
import 'package:efe_mobile/features/auth/domain/user_model.dart';
import 'package:efe_mobile/features/auth/providers/auth_provider.dart';
import 'package:efe_mobile/features/chat/data/chat_repository.dart';
import 'package:efe_mobile/features/chat/domain/chat_model.dart';
import 'package:efe_mobile/features/chat/domain/message_model.dart';
import 'package:efe_mobile/features/chat/providers/chat_provider.dart';
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
}

class _FakeSubscription implements Subscription {
  @override
  void cancel() {}

  @override
  Subscription listen(String event, ReverbEventCallback callback) => this;

  @override
  Subscription listenForWhisper(String event, ReverbEventCallback callback) =>
      this;

  @override
  Subscription listenAll(ReverbWildcardCallback callback) => this;
}

/// Minimal realtime service: records the notification callback the coordinator
/// registers and can fire it on demand.
class _FakeRealtimeService implements RealtimeService {
  void Function()? onNotification;
  int connectCalls = 0;
  final Set<void Function()> reconnectListeners = <void Function()>{};

  @override
  bool get isConnected => true;

  @override
  Stream<ReverbState> get states => const Stream<ReverbState>.empty();

  @override
  Future<void> connect() async {
    connectCalls++;
  }

  @override
  Future<void> disconnect({bool forget = false}) async {
    if (forget) reconnectListeners.clear();
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
    this.onNotification = onNotification;
    return _FakeSubscription();
  }

  @override
  VoidCallback addReconnectListener(void Function() listener) {
    reconnectListeners.add(listener);
    return () => reconnectListeners.remove(listener);
  }

  void emitNotification() => onNotification?.call();
}

CursorPagination<ChatModel> _page(List<ChatModel> data) =>
    CursorPagination<ChatModel>(data: data, hasMore: false);

/// Serves queued pages and records the cursor of every first-page request.
class _FakeChatRepository implements ChatRepository {
  final List<Future<CursorPagination<ChatModel>> Function()> _responses = [];
  final List<String?> cursors = <String?>[];

  void enqueue(CursorPagination<ChatModel> page) {
    _responses.add(() => Future.value(page));
  }

  @override
  Future<CursorPagination<ChatModel>> getChats({String? cursor}) {
    cursors.add(cursor);
    if (_responses.isEmpty) {
      return Future.value(
          CursorPagination<ChatModel>(data: const [], hasMore: false));
    }
    return _responses.removeAt(0)();
  }

  @override
  Future<CursorPagination<MessageModel>> getMessages(
    String chatId, {
    String? cursor,
  }) =>
      Future.error(UnimplementedError());

  @override
  Future<MessageModel> sendMessage(String chatId, String body) =>
      Future.error(UnimplementedError());
}

class _Harness {
  _Harness(ChatRepository repository) {
    auth = _TestAuthNotifier()..signIn(_user);
    service = _FakeRealtimeService();
    container = ProviderContainer(
      overrides: [
        realtimeServiceProvider.overrideWithValue(service),
        authProvider.overrideWith((ref) => auth),
        chatRepositoryProvider.overrideWithValue(repository),
        // Zero debounce keeps the notification test deterministic.
        realtimeResyncDebounceProvider.overrideWithValue(Duration.zero),
      ],
    );
    addTearDown(container.dispose);
  }

  late final _TestAuthNotifier auth;
  late final _FakeRealtimeService service;
  late final ProviderContainer container;

  void mountCoordinator() => container.read(realtimeCoordinatorProvider);
}

void main() {
  test('a notification refreshes the first page of the chat list', () async {
    final repository = _FakeChatRepository()
      ..enqueue(_page([
        const ChatModel(id: 'c1', name: 'Ada', lastMessage: 'hola'),
      ]))
      ..enqueue(_page([
        const ChatModel(
          id: 'c1',
          name: 'Ada',
          lastMessage: 'nuevo mensaje',
          unreadCount: 2,
        ),
      ]));
    final harness = _Harness(repository);
    harness.mountCoordinator();
    await pumpEventQueue();

    // Seed the list so the refresh only performs the notification request.
    harness.container.read(chatListProvider);
    await pumpEventQueue();
    expect(
      harness.container.read(chatListProvider).chats.single.lastMessage,
      'hola',
    );

    harness.service.emitNotification();
    await pumpEventQueue();

    // A first-page refresh (no cursor), not a pagination call.
    expect(repository.cursors, [null, null]);
    final state = harness.container.read(chatListProvider);
    expect(state.chats.single.lastMessage, 'nuevo mensaje');
    expect(state.chats.single.unreadCount, 2);
    expect(state.isLoading, isFalse);
    expect(state.error, isNull);
  });

  test('refreshFirstPage updates unread counts and last message preview',
      () async {
    final repository = _FakeChatRepository()
      ..enqueue(_page([
        const ChatModel(id: 'c1', name: 'Ada', lastMessage: 'hola'),
      ]));
    final notifier = ChatListNotifier(repository);
    await pumpEventQueue();
    expect(notifier.state.chats.single.unreadCount, 0);

    repository.enqueue(_page([
      const ChatModel(
        id: 'c1',
        name: 'Ada',
        lastMessage: 'nuevo mensaje',
        unreadCount: 3,
      ),
    ]));
    await notifier.refreshFirstPage();

    final state = notifier.state;
    expect(repository.cursors, [null, null]);
    expect(state.chats.single.unreadCount, 3);
    expect(state.chats.single.lastMessage, 'nuevo mensaje');
    // A realtime refresh must not flash the loading shimmer.
    expect(state.isLoading, isFalse);
  });
}
