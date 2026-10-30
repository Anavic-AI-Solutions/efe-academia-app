import '../../../core/api/cursor_pagination.dart';
import '../domain/event_model.dart';
import 'event_api.dart';

class EventRepository {
  final EventApi _api;
  EventRepository(this._api);

  Future<CursorPagination<EventModel>> getEvents({String? cursor}) async {
    final response = await _api.getEvents(cursor: cursor);
    final data = response.data;
    final items = data is Map<String, dynamic>
        ? (data['data'] as List<dynamic>? ?? [])
        : data as List<dynamic>? ?? [];
    final meta = data is Map<String, dynamic>
        ? (data['meta'] as Map<String, dynamic>? ?? {})
        : <String, dynamic>{};
    return CursorPagination(
      data: items
          .map((e) => EventModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      nextCursor: meta['cursor']?.toString(),
      hasMore: meta['has_more'] == true,
      total: int.tryParse('${meta['total']}'),
    );
  }

  Future<List<EventModel>> getCalendarEvents({
    required String startDate,
    required String endDate,
  }) async {
    final response = await _api.getCalendar(
      startDate: startDate,
      endDate: endDate,
    );
    final data = response.data;
    final items = data is Map<String, dynamic>
        ? (data['data'] as List<dynamic>? ?? [])
        : data as List<dynamic>? ?? [];
    return items
        .map((e) => EventModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
