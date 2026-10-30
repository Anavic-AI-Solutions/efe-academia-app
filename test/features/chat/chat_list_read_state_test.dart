import 'package:dio/dio.dart';
import 'package:efe_mobile/core/api/cursor_pagination.dart';
import 'package:efe_mobile/features/chat/data/chat_api.dart';
import 'package:efe_mobile/features/chat/data/chat_repository.dart';
import 'package:efe_mobile/features/chat/domain/chat_model.dart';
import 'package:efe_mobile/features/chat/domain/message_model.dart';
import 'package:efe_mobile/features/chat/providers/chat_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeChatApi implements ChatApi {
  int unreadCount;

  _FakeChatApi(this.unreadCount);

  @override
  Future<int> getUnreadCount() async => unreadCount;

  @override
  Future<void> markRead(String chatId) async => unreadCount = 0;

  @override
  Future<Response> getChats({String? cursor, int limit = 20}) =>
      Future.error(UnimplementedError());

  @override
  Future<Response> getMessages(String chatId,
          {String? cursor, int limit = 50, String? direction}) =>
      Future.error(UnimplementedError());

  @override
  Future<Response> sendMessage(String chatId, String body) =>
      Future.error(UnimplementedError());

  @override
  Future<Response> createPrivateChat({required int withUserId}) =>
      Future.error(UnimplementedError());
}

class _FakeChatRepository implements ChatRepository {
  @override
  Future<CursorPagination<ChatModel>> getChats({String? cursor}) async {
    return CursorPagination<ChatModel>(
      data: const [
        ChatModel(id: 'c1', name: 'Ada', unreadCount: 3),
      ],
      hasMore: false,
    );
  }

  @override
  Future<CursorPagination<MessageModel>> getMessages(
    String chatId, {
    String? cursor,
    String? direction,
  }) =>
      Future.error(UnimplementedError());

  @override
  Future<MessageModel> sendMessage(String chatId, String body) =>
      Future.error(UnimplementedError());
}

void main() {
  test('opening a chat clears its per-chat unread badge', () async {
    final api = _FakeChatApi(3);
    final repository = _FakeChatRepository();
    final container = ProviderContainer(
      overrides: [
        chatApiProvider.overrideWithValue(api),
        chatRepositoryProvider.overrideWithValue(repository),
      ],
    );
    addTearDown(container.dispose);

    await container.read(chatListProvider.notifier).load();
    expect(container.read(chatListProvider).chats.single.unreadCount, 3);

    await container.read(chatUnreadCountControllerProvider).markRead('c1');

    expect(container.read(chatListProvider).chats.single.unreadCount, 0);
  });
}
