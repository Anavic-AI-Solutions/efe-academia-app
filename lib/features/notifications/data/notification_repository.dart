import '../../../core/api/cursor_pagination.dart';
import '../domain/notification_model.dart';
import 'notification_api.dart';

class NotificationRepository {
  final NotificationApi _api;
  NotificationRepository(this._api);

  Future<CursorPagination<NotificationModel>> getNotifications({
    String? cursor,
  }) async {
    final response = await _api.getNotifications(cursor: cursor);
    final data = response.data;
    final items = data is Map<String, dynamic>
        ? (data['data'] as List<dynamic>? ?? [])
        : data as List<dynamic>? ?? [];
    final meta = data is Map<String, dynamic>
        ? (data['meta'] as Map<String, dynamic>? ?? {})
        : <String, dynamic>{};
    return CursorPagination(
      data: items
          .map((e) => NotificationModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      nextCursor: meta['cursor'],
      hasMore: meta['has_more'] ?? false,
      total: meta['total'],
    );
  }

  Future<int> getUnreadCount() async {
    final response = await _api.getUnreadCount();
    final data = response.data;
    if (data is! Map) return 0;
    // El backend responde `{data: {count}}`; se acepta también `{count}` por
    // compatibilidad con respuestas antiguas.
    final payload = data['data'];
    final source = payload is Map ? payload : data;
    final count = source['count'];
    if (count is int) return count;
    if (count is num) return count.toInt();
    if (count is String) return int.tryParse(count) ?? 0;
    return 0;
  }

  Future<void> markAllRead() async {
    await _api.markAllRead();
  }

  Future<void> markRead(String id) async {
    await _api.markRead(id);
  }
}
