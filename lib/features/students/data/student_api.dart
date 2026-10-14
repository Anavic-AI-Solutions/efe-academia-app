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
    int page = 1,
    int limit = 20,
  }) =>
      _client.get('/students', queryParameters: {
        if (search != null && search.isNotEmpty) 'search': search,
        if (status != null && status.isNotEmpty) 'status': status,
        if (year != null && year.isNotEmpty) 'year': year,
        if (branch != null && branch.isNotEmpty) 'branch': branch,
        'page': page,
        'per_page': limit,
      });

  Future<Response> getStudent(String id) =>
      _client.get('/students/$id');

  Future<Response> getClassrooms(String studentId) =>
      _client.get('/students/$studentId/classrooms');
}
