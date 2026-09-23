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
  }) =>
      _client.get('/classrooms', queryParameters: {
        if (search != null && search.isNotEmpty) 'search': search,
        'page': page,
        if (branch != null && branch.isNotEmpty) 'branch': branch,
        if (level != null && level.isNotEmpty) 'level': level,
        if (year != null && year.isNotEmpty) 'year': year,
        if (status != null && status.isNotEmpty) 'status': status,
        'per_page': limit,
      });

  Future<Response> getClassroom(String id) =>
      _client.get('/classrooms/$id');

  Future<Response> getClassroomFilters() =>
      _client.get('/classrooms/filters');
}
