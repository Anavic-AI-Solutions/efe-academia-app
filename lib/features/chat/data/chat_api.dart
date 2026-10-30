import 'package:dio/dio.dart';
import '../../../core/api/api_client.dart';

class ChatApi {
  final ApiClient _client;
  ChatApi(this._client);

  Future<Response> getChats({String? cursor, int limit = 20}) =>
      _client.get('/chats', queryParameters: {
        if (cursor != null) 'cursor': cursor,
        'per_page': limit,
      });

  Future<Response> getMessages(String chatId,
          {String? cursor, int limit = 50, String? direction}) =>
      _client.get('/chats/$chatId/messages', queryParameters: {
        if (cursor != null) 'cursor': cursor,
        if (direction != null) 'direction': direction,
        'per_page': limit,
      });

  Future<Response> sendMessage(String chatId, String body) =>
      _client.post('/chats/$chatId/messages', data: {'message': body});

  /// Total de mensajes sin leer, tal como lo expone el backend en
  /// `{data: {count}}`. Si falta el sobre, devuelve `0`.
  Future<int> getUnreadCount() async {
    final response = await _client.get('/chats/unread-count');
    final data = response.data;
    if (data is! Map) return 0;
    final envelope = data['data'];
    if (envelope is! Map) return 0;
    final count = envelope['count'];
    if (count is int) return count;
    if (count is num) return count.toInt();
    return 0;
  }

  /// Marca el chat como leído; el backend despacha `.MessagesRead`.
  Future<void> markRead(String chatId) async {
    await _client.post('/chats/$chatId/read');
  }

  Future<Response> createPrivateChat({required int withUserId}) =>
      _client.post('/chats', data: {
        'type': 'private',
        'with_user_id': withUserId,
      });
}
