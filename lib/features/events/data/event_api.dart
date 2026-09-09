import 'package:dio/dio.dart';
import '../../../core/api/api_client.dart';

class EventApi {
  final ApiClient _client;
  EventApi(this._client);

  Future<Response> getEvents({String? cursor, int limit = 20}) =>
      _client.get('/events', queryParameters: {
        if (cursor != null) 'cursor': cursor,
        'limit': limit,
      });
}
