import '../../../core/api/cursor_pagination.dart';
import '../domain/chat_model.dart';
import '../domain/message_model.dart';
import 'chat_api.dart';

class ChatRepository {
  final ChatApi _api;
  ChatRepository(this._api);

  Future<CursorPagination<ChatModel>> getChats({String? cursor}) async {
    final response = await _api.getChats(cursor: cursor);
    final data = response.data;
    final items = data is Map<String, dynamic>
        ? (data['data'] as List<dynamic>? ?? [])
        : data as List<dynamic>? ?? [];
    final meta = data is Map<String, dynamic>
        ? (data['meta'] as Map<String, dynamic>? ?? {})
        : <String, dynamic>{};
    return CursorPagination(
      data: items
          .map((e) => ChatModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      nextCursor: meta['cursor'],
      hasMore: meta['has_more'] ?? false,
      total: meta['total'],
    );
  }

  Future<CursorPagination<MessageModel>> getMessages(
    String chatId, {
    String? cursor,
  }) async {
    final response = await _api.getMessages(chatId, cursor: cursor);
    final data = response.data;
    final items = data is Map<String, dynamic>
        ? (data['data'] as List<dynamic>? ?? [])
        : data as List<dynamic>? ?? [];
    final meta = data is Map<String, dynamic>
        ? (data['meta'] as Map<String, dynamic>? ?? {})
        : <String, dynamic>{};
    return CursorPagination(
      data: items
          .map((e) => MessageModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      nextCursor: meta['cursor'],
      hasMore: meta['has_more'] ?? false,
      total: meta['total'],
    );
  }

  Future<MessageModel> sendMessage(String chatId, String body) async {
    final response = await _api.sendMessage(chatId, body);
    final data = response.data;
    return MessageModel.fromJson(data as Map<String, dynamic>);
  }
}
