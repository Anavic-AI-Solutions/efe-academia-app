import '../domain/event_model.dart';
import 'event_api.dart';

class EventRepository {
  final EventApi _api;
  EventRepository(this._api);

  Future<List<EventModel>> getEvents({String? cursor}) async {
    final response = await _api.getEvents(cursor: cursor);
    final data = response.data;
    final items = data is Map<String, dynamic>
        ? (data['data'] as List<dynamic>? ?? [])
        : data as List<dynamic>? ?? [];
    return items
        .map((e) => EventModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
