import 'package:dio/dio.dart';
import '../../../core/api/api_client.dart';

class ClassroomApi {
  final ApiClient _client;
  ClassroomApi(this._client);

  Future<Response> getClassrooms({
    String? search,
    int page = 1,
    int limit = 20,
    String? branch,
    String? level,
    String? year,
    String? status,
    String? studentId,
  }) =>
      _client.get('/classrooms', queryParameters: {
        if (search != null && search.isNotEmpty) 'search': search,
        'page': page,
        if (branch != null && branch.isNotEmpty) 'branch': branch,
        if (level != null && level.isNotEmpty) 'level': level,
        if (year != null && year.isNotEmpty) 'year': year,
        if (status != null && status.isNotEmpty) 'status': status,
        if (studentId != null && studentId.isNotEmpty) 'student_id': studentId,
        'per_page': limit,
      });

  Future<Response> getClassroom(String id) => _client.get('/classrooms/$id');

  Future<Response> getClassroomFilters() => _client.get('/classrooms/filters');

  Future<Response> getClassroomStudents(
    String id, {
    int page = 1,
    int limit = 20,
  }) =>
      _client.get('/classrooms/$id/students', queryParameters: {
        'page': page,
        'per_page': limit,
      });

  Future<Response> getClassroomProfessors(
    String id, {
    int page = 1,
    int limit = 20,
  }) =>
      _client.get('/classrooms/$id/professors', queryParameters: {
        'page': page,
        'per_page': limit,
      });

  Future<Response> getClassroomMaterials(
    String id, {
    int page = 1,
    int limit = 20,
  }) =>
      _client.get('/classrooms/$id/materials', queryParameters: {
        'page': page,
        'per_page': limit,
      });
}
