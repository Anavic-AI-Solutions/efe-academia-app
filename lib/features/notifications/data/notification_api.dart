import 'package:dio/dio.dart';
import '../../../core/api/api_client.dart';

class NotificationApi {
  final ApiClient _client;
  NotificationApi(this._client);

  Future<Response> getNotifications({String? cursor, int limit = 20}) =>
      _client.get('/notifications', queryParameters: {
        if (cursor != null) 'cursor': cursor,
        'limit': limit,
      });

  Future<Response> getUnreadCount() =>
      _client.get('/notifications/unread-count');

  Future<Response> markAllRead() =>
      _client.post('/notifications/mark-read');

  Future<Response> markRead(String id) =>
      _client.post('/notifications/$id/read');
}
