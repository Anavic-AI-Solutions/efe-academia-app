import 'dart:async';

import 'package:dio/dio.dart';
import 'package:efe_mobile/core/api/cursor_pagination.dart';
import 'package:efe_mobile/core/realtime/realtime_providers.dart';
import 'package:efe_mobile/core/realtime/realtime_service.dart';
import 'package:efe_mobile/features/auth/data/auth_repository.dart';
import 'package:efe_mobile/features/auth/domain/user_model.dart';
import 'package:efe_mobile/features/auth/providers/auth_provider.dart';
import 'package:efe_mobile/features/chat/data/chat_api.dart';
import 'package:efe_mobile/features/chat/data/chat_repository.dart';
import 'package:efe_mobile/features/chat/domain/chat_model.dart';
import 'package:efe_mobile/features/chat/domain/message_model.dart';
import 'package:efe_mobile/features/chat/providers/chat_provider.dart';
import 'package:efe_mobile/features/chat/screens/chat_detail_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:laravel_reverb/laravel_reverb.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../helpers/localized_app.dart';

const _me = UserModel(
  id: '7',
  name: 'Ada',
  email: 'ada@example.com',
  role: 'professor',
);

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

/// Records the chat channel wiring and lets the test emit realtime events.
class _FakeRealtimeService implements RealtimeService {
  final List<String> watchedChats = <String>[];
  final List<({String chatId, bool typing, String userId})> typingWhispers =
      <({String chatId, bool typing, String userId})>[];
  final Set<void Function()> reconnectListeners = <void Function()>{};

  late _FakeSubscription chatSubscription;
  void Function(Map<String, dynamic> data)? onMessage;
  void Function(Map<String, dynamic> data)? onRead;
  void Function(Map<String, dynamic> data)? onTyping;

  @override
  bool get isConnected => true;

  @override
  Stream<ReverbState> get states => const Stream<ReverbState>.empty();

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
    watchedChats.add(chatId);
    this.onMessage = onMessage;
    this.onRead = onRead;
    this.onTyping = onTyping;
    return chatSubscription = _FakeSubscription();
  }

  @override
  Subscription watchNotifications({
    required String userId,
    required void Function() onNotification,
  }) =>
      _FakeSubscription();

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
  }) {
    typingWhispers.add((chatId: chatId, typing: typing, userId: userId));
  }

  void fireReconnect() {
    for (final listener in List<void Function()>.of(reconnectListeners)) {
      listener();
    }
  }
}

class _FakeChatApi implements ChatApi {
  final List<String> markedRead = <String>[];

  @override
  Future<void> markRead(String chatId) async => markedRead.add(chatId);

  @override
  Future<int> getUnreadCount() async => 0;

  @override
  Future<Response> getChats({String? cursor, int limit = 20}) =>
      Future.error(UnimplementedError());

  @override
  Future<Response> getMessages(String chatId,
          {String? cursor, int limit = 50}) =>
      Future.error(UnimplementedError());

  @override
  Future<Response> sendMessage(String chatId, String body) =>
      Future.error(UnimplementedError());

  @override
  Future<Response> createPrivateChat({required int withUserId}) =>
      Future.error(UnimplementedError());
}

class _FakeChatRepository implements ChatRepository {
  _FakeChatRepository(this.messages, {this.backfillMessages = const []});

  final List<MessageModel> messages;
  final List<MessageModel> backfillMessages;
  final List<String?> messageCursors = <String?>[];
  Future<MessageModel> Function(String body)? onSendMessage;
  int sendCalls = 0;

  @override
  Future<CursorPagination<ChatModel>> getChats({String? cursor}) =>
      Future.error(UnimplementedError());

  @override
  Future<CursorPagination<MessageModel>> getMessages(
    String chatId, {
    String? cursor,
  }) async {
    messageCursors.add(cursor);
    return CursorPagination<MessageModel>(
      data: cursor == null ? messages : backfillMessages,
      hasMore: false,
    );
  }

  @override
  Future<MessageModel> sendMessage(String chatId, String body) {
    sendCalls++;
    final handler = onSendMessage;
    if (handler == null) return Future.error(UnimplementedError());
    return handler(body);
  }
}

// ---------------------------------------------------------------------------
// Harness
// ---------------------------------------------------------------------------

MessageModel _message(String id,
        {String body = 'hola', String senderId = '2'}) =>
    MessageModel(
      id: id,
      body: body,
      senderId: senderId,
      senderName: 'Otra',
      createdAt: DateTime(2026, 10, 5, 12),
    );

Map<String, dynamic> _incoming(String id, {String body = 'nuevo'}) => {
      'id': id,
      'body': body,
      'sender_id': '2',
      'sender_name': 'Otra',
      'created_at': '2026-10-05T12:00:00Z',
    };

class _Harness {
  _Harness({
    required this.service,
    required this.api,
    required this.repository,
    required this.container,
  });

  final _FakeRealtimeService service;
  final _FakeChatApi api;
  final _FakeChatRepository repository;
  final ProviderContainer container;
}

Future<_Harness> _pumpDetail(
  WidgetTester tester, {
  List<MessageModel> messages = const [],
  List<MessageModel> backfillMessages = const [],
  Future<MessageModel> Function(String body)? onSendMessage,
}) async {
  final service = _FakeRealtimeService();
  final api = _FakeChatApi();
  final repository = _FakeChatRepository(
    messages,
    backfillMessages: backfillMessages,
  )..onSendMessage = onSendMessage;
  final auth = _TestAuthNotifier()..signIn(_me);
  final container = ProviderContainer(
    overrides: [
      realtimeServiceProvider.overrideWithValue(service),
      chatRepositoryProvider.overrideWithValue(repository),
      chatApiProvider.overrideWithValue(api),
      authProvider.overrideWith((ref) => auth),
    ],
  );
  addTearDown(container.dispose);

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: localizedApp(
        home: const ChatDetailScreen(chatId: 'c1', chatName: 'Ada'),
      ),
    ),
  );
  await tester.pumpAndSettle();

  return _Harness(
    service: service,
    api: api,
    repository: repository,
    container: container,
  );
}

void main() {
  testWidgets('shows the typing row when the other user is typing',
      (tester) async {
    final harness = await _pumpDetail(tester);

    harness.service.onTyping?.call({'user_id': '2', 'typing': true});
    await tester.pump();

    expect(find.byKey(const Key('chatTyping')), findsOneWidget);
    expect(find.text('escribiendo…'), findsOneWidget);

    harness.service.onTyping?.call({'user_id': '2', 'typing': false});
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('chatTyping')), findsNothing);
  });

  testWidgets('shows a double check on messages read by the other user',
      (tester) async {
    final harness = await _pumpDetail(
      tester,
      messages: [
        _message('1', senderId: '2', body: 'ajeno'),
        _message('2', senderId: '7', body: 'mío'),
      ],
    );

    expect(find.byIcon(PhosphorIconsFill.checks), findsNothing);

    harness.service.onRead?.call({'last_read_message_id': '2'});
    await tester.pump();

    expect(find.byIcon(PhosphorIconsFill.checks), findsOneWidget);
  });

  testWidgets('shows the failed state with retry on an unsent message',
      (tester) async {
    final harness = await _pumpDetail(
      tester,
      onSendMessage: (body) => Future.error(Exception('sin red')),
    );

    await tester.enterText(find.byType(TextField), 'hola');
    await tester.pump();
    await tester.tap(find.byIcon(PhosphorIconsFill.paperPlaneRight));
    await tester.pump();
    await tester.pump();

    expect(find.text('No se pudo enviar'), findsOneWidget);
    expect(find.text('Reintentar'), findsOneWidget);

    harness.repository.onSendMessage =
        (body) async => _message('42', body: body, senderId: '7');
    await tester.tap(find.text('Reintentar'));
    await tester.pump();
    await tester.pump();

    expect(find.text('No se pudo enviar'), findsNothing);
    expect(find.text('Reintentar'), findsNothing);
    expect(harness.repository.sendCalls, 2);
  });

  testWidgets('subscribes on mount and cancels on dispose', (tester) async {
    final harness = await _pumpDetail(tester);

    expect(harness.service.watchedChats, ['c1']);
    expect(harness.service.reconnectListeners, hasLength(1));
    expect(harness.api.markedRead, ['c1']);

    // A broadcast delivered to the registered callback reaches the bubbles.
    harness.service.onMessage?.call(_incoming('5'));
    await tester.pump();
    expect(find.text('nuevo'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();

    expect(harness.service.chatSubscription.cancelled, isTrue);
    expect(harness.service.reconnectListeners, isEmpty);
  });

  testWidgets('sends a throttled typing whisper while composing and clears it',
      (tester) async {
    final harness = await _pumpDetail(
      tester,
      onSendMessage: (body) async => _message('42', body: body, senderId: '7'),
    );

    await tester.enterText(find.byType(TextField), 'ho');
    await tester.pump();
    expect(harness.service.typingWhispers,
        [(chatId: 'c1', typing: true, userId: '7')]);

    await tester.enterText(find.byType(TextField), 'hola');
    await tester.pump();
    // Still inside the 2s throttle window: no second announcement.
    expect(harness.service.typingWhispers, hasLength(1));

    await tester.tap(find.byIcon(PhosphorIconsFill.paperPlaneRight));
    await tester.pump();
    await tester.pump();

    expect(harness.service.typingWhispers, [
      (chatId: 'c1', typing: true, userId: '7'),
      (chatId: 'c1', typing: false, userId: '7'),
    ]);
  });

  testWidgets('cancels the typing throttle timer on dispose', (tester) async {
    final harness = await _pumpDetail(tester);

    await tester.enterText(find.byType(TextField), 'hola');
    await tester.pump();
    expect(harness.service.typingWhispers, hasLength(1));

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(seconds: 3));

    // Dispose cancelled the pending 2s throttle: no whisper was sent after
    // the screen went away and the binding reports no leaked timer.
    expect(harness.service.typingWhispers, hasLength(1));
  });

  testWidgets('reconnect triggers the backfill of missed messages',
      (tester) async {
    final harness = await _pumpDetail(
      tester,
      messages: [
        _message('1', senderId: '2', body: 'viejo'),
        _message('2', senderId: '7', body: 'mío'),
      ],
      backfillMessages: [_message('3', senderId: '2', body: 'perdido')],
    );

    harness.service.fireReconnect();
    await tester.pump();
    await tester.pump();

    expect(harness.repository.messageCursors, [null, '2']);
    expect(find.text('perdido'), findsOneWidget);
  });
}
