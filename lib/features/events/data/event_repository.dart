import 'package:dio/dio.dart';

import '../../../core/api/api_exception.dart';
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

  Future<EventModel> createEvent({
    required String title,
    String description = '',
    required DateTime start,
    required DateTime end,
    int color = 0xFF3B82F6,
  }) async {
    try {
      final response = await _api.createEvent(
        _payload(
          title: title,
          description: description,
          start: start,
          end: end,
          color: color,
        ),
      );
      return EventModel.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<EventModel> updateEvent(
    String id, {
    required String title,
    String description = '',
    required DateTime start,
    required DateTime end,
    int color = 0xFF3B82F6,
  }) async {
    try {
      final response = await _api.updateEvent(
        id,
        _payload(
          title: title,
          description: description,
          start: start,
          end: end,
          color: color,
        ),
      );
      return EventModel.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<void> deleteEvent(String id) async {
    try {
      await _api.deleteEvent(id);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Map<String, dynamic> _payload({
    required String title,
    required String description,
    required DateTime start,
    required DateTime end,
    required int color,
  }) {
    return {
      'title': title,
      'description': description,
      'start_date': start.toIso8601String(),
      'end_date': end.toIso8601String(),
      'color': _hexColor(color),
    };
  }

  /// La API guarda el color como `#RRGGBB`; descarta el alfa del ARGB de Flutter.
  static String _hexColor(int color) =>
      '#${(color & 0xFFFFFF).toRadixString(16).padLeft(6, '0').toUpperCase()}';

  /// Propaga tal cual la excepción que armó el interceptor (incluida
  /// [ValidationException] con sus errores por campo).
  ApiException _handleDioError(DioException e) {
    if (e.error is ApiException) return e.error as ApiException;
    return ApiException(
      message: e.message ?? 'Ocurrió un error inesperado',
      statusCode: e.response?.statusCode,
    );
  }
}
