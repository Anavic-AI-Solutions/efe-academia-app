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

  Future<Response> getStudent(String id) => _client.get('/students/$id');

  Future<Response> createStudent(Map<String, dynamic> data) =>
      _client.post('/students', data: data);

  Future<Response> updateStudent(String id, Map<String, dynamic> data) =>
      _client.patch('/students/$id', data: data);

  Future<Response> deactivateStudent(String id) =>
      _client.post('/students/$id/deactivate');

  Future<Response> reactivateStudent(String id) =>
      _client.post('/students/$id/reactivate');

  Future<Response> getClassrooms(String studentId) =>
      _client.get('/students/$studentId/classrooms');

  Future<Response> getParents(String studentId) =>
      _client.get('/students/$studentId/parents');
}
