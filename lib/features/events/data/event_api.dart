import 'package:dio/dio.dart';
import '../../../core/api/api_client.dart';

class EventApi {
  final ApiClient _client;
  EventApi(this._client);

  Future<Response> getEvents({String? cursor, int limit = 20}) =>
      _client.get('/events', queryParameters: {
        if (cursor != null) 'cursor': cursor,
        'per_page': limit,
      });

  Future<Response> getCalendar({
    required String startDate,
    required String endDate,
  }) =>
      _client.get('/events/calendar', queryParameters: {
        'start_date': startDate,
        'end_date': endDate,
      });
}
