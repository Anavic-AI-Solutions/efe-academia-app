import 'package:dio/dio.dart';
import '../../../core/api/api_client.dart';

class StudentApi {
  final ApiClient _client;
  StudentApi(this._client);

  Future<Response> getStudents({
    String? search,
    String? status,
    String? year,
    String? branch,
    String? cursor,
    int limit = 20,
  }) =>
      _client.get('/students', queryParameters: {
        if (search != null && search.isNotEmpty) 'search': search,
        if (status != null && status.isNotEmpty) 'status': status,
        if (year != null && year.isNotEmpty) 'year': year,
        if (branch != null && branch.isNotEmpty) 'branch': branch,
        if (cursor != null) 'cursor': cursor,
        'per_page': limit,
      });

  Future<Response> getStudent(String id) =>
      _client.get('/students/$id');
}
