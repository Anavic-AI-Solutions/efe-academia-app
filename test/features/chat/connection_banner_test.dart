import 'package:efe_mobile/core/api/cursor_pagination.dart';
import 'package:efe_mobile/core/realtime/realtime_providers.dart';
import 'package:efe_mobile/core/realtime/realtime_service.dart';
import 'package:efe_mobile/features/chat/data/chat_repository.dart';
import 'package:efe_mobile/features/chat/domain/chat_model.dart';
import 'package:efe_mobile/features/chat/domain/message_model.dart';
import 'package:efe_mobile/features/chat/providers/chat_provider.dart';
import 'package:efe_mobile/features/chat/screens/chat_list_screen.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:laravel_reverb/laravel_reverb.dart';

import '../../helpers/localized_app.dart';

const _bannerKey = Key('chatConnectionBanner');
const _bannerText = 'Sin conexión — tocá para reintentar';

// ---------------------------------------------------------------------------
// Fakes
// ---------------------------------------------------------------------------

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

/// Only needs to record retry attempts: the banner must call `connect()`.
class _FakeRealtimeService implements RealtimeService {
  int connectCalls = 0;

  @override
  Future<void> connect() async => connectCalls++;

  @override
  Future<void> disconnect({bool forget = false}) async {}

  @override
  bool get isConnected => false;

  @override
  Stream<ReverbState> get states => const Stream<ReverbState>.empty();

  @override
  Subscription watchChat({
    required String chatId,
    required void Function(Map<String, dynamic> data) onMessage,
    required void Function(Map<String, dynamic> data) onRead,
    required void Function(Map<String, dynamic> data) onTyping,
  }) =>
      _FakeSubscription();

  @override
  Subscription watchNotifications({
    required String userId,
    required void Function() onNotification,
  }) =>
      _FakeSubscription();

  @override
  VoidCallback addReconnectListener(void Function() listener) => () {};

  @override
  void sendTyping({
    required String chatId,
    required bool typing,
    required String userId,
  }) {}
}

class _FakeChatRepository implements ChatRepository {
  @override
  Future<CursorPagination<ChatModel>> getChats({String? cursor}) async =>
      CursorPagination<ChatModel>(data: const [], hasMore: false);

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

// ---------------------------------------------------------------------------
// Harness
// ---------------------------------------------------------------------------

Future<_FakeRealtimeService> _pumpChatList(
  WidgetTester tester, {
  required bool realtimeReady,
}) async {
  final service = _FakeRealtimeService();
  final container = ProviderContainer(
    overrides: [
      chatRepositoryProvider.overrideWithValue(_FakeChatRepository()),
      realtimeServiceProvider.overrideWithValue(service),
      realtimeReadyProvider.overrideWithValue(realtimeReady),
    ],
  );
  addTearDown(container.dispose);

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: localizedApp(home: const ChatListScreen()),
    ),
  );
  await tester.pumpAndSettle();

  return service;
}

void main() {
  testWidgets('shows the offline banner when the socket is down',
      (tester) async {
    await _pumpChatList(tester, realtimeReady: false);

    expect(find.byKey(_bannerKey), findsOneWidget);
    expect(find.text(_bannerText), findsOneWidget);
  });

  testWidgets('hides the banner when the connection is restored',
      (tester) async {
    await _pumpChatList(tester, realtimeReady: true);

    expect(find.byKey(_bannerKey), findsNothing);
    expect(find.text(_bannerText), findsNothing);
  });

  testWidgets('tapping the banner retries the connection', (tester) async {
    final service = await _pumpChatList(tester, realtimeReady: false);

    expect(service.connectCalls, 0);

    await tester.tap(find.byKey(_bannerKey));
    await tester.pump();

    expect(service.connectCalls, 1);
  });
}
