import 'package:dio/dio.dart';
import '../../../core/api/api_client.dart';

class ClassroomApi {
  final ApiClient _client;
  ClassroomApi(this._client);

  Future<Response> getClassrooms({
    String? search,
    String? cursor,
    int limit = 20,
  }) =>
      _client.get('/classrooms', queryParameters: {
        if (search != null && search.isNotEmpty) 'search': search,
        if (cursor != null) 'cursor': cursor,
        'per_page': limit,
      });

  Future<Response> getClassroom(String id) =>
      _client.get('/classrooms/$id');
}
