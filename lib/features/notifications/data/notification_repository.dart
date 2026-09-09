import '../domain/notification_model.dart';
import 'notification_api.dart';

class NotificationRepository {
  final NotificationApi _api;
  NotificationRepository(this._api);

  Future<List<NotificationModel>> getNotifications({String? cursor}) async {
    final response = await _api.getNotifications(cursor: cursor);
    final data = response.data;
    final items = data is Map<String, dynamic>
        ? (data['data'] as List<dynamic>? ?? [])
        : data as List<dynamic>? ?? [];
    return items
        .map((e) => NotificationModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<int> getUnreadCount() async {
    final response = await _api.getUnreadCount();
    final data = response.data;
    return data is Map<String, dynamic> ? (data['count'] ?? 0) as int : 0;
  }

  Future<void> markAllRead() async {
    await _api.markAllRead();
  }

  Future<void> markRead(String id) async {
    await _api.markRead(id);
  }
}
