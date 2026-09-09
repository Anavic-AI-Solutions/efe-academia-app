import 'package:dio/dio.dart';
import '../../../core/api/api_client.dart';

class StudentApi {
  final ApiClient _client;
  StudentApi(this._client);

  Future<Response> getStudents({
    String? search,
    String? cursor,
    int limit = 20,
  }) =>
      _client.get('/students', queryParameters: {
        if (search != null && search.isNotEmpty) 'search': search,
        if (cursor != null) 'cursor': cursor,
        'limit': limit,
      });

  Future<Response> getStudent(String id) =>
      _client.get('/students/$id');
}
