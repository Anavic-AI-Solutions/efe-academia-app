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

  Future<Response> getMessages(String chatId, {String? cursor, int limit = 50}) =>
      _client.get('/chats/$chatId/messages', queryParameters: {
        if (cursor != null) 'cursor': cursor,
        'per_page': limit,
      });

  Future<Response> sendMessage(String chatId, String body) =>
      _client.post('/chats/$chatId/messages', data: {'message': body});
}
