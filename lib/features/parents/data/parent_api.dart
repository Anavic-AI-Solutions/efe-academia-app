import 'package:dio/dio.dart';

import '../../../core/api/api_client.dart';

class ParentApi {
  final ApiClient _client;

  ParentApi(this._client);

  Future<Response> getParents({
    String? search,
    String? cursor,
    int limit = 20,
  }) =>
      _client.get('/parents', queryParameters: {
        if (search != null && search.isNotEmpty) 'search': search,
        if (cursor != null && cursor.isNotEmpty) 'cursor': cursor,
        'per_page': limit,
      });

  Future<Response> getParent(String id) => _client.get('/parents/$id');

  Future<Response> createParent(Map<String, dynamic> data) =>
      _client.post('/parents', data: data);

  Future<Response> updateParent(String id, Map<String, dynamic> data) =>
      _client.patch('/parents/$id', data: data);

  Future<Response> deleteParent(String id) => _client.delete('/parents/$id');

  Future<Response> getParentStudents(
    String parentId, {
    String? cursor,
    int limit = 20,
  }) =>
      _client.get('/parents/$parentId/students', queryParameters: {
        if (cursor != null && cursor.isNotEmpty) 'cursor': cursor,
        'per_page': limit,
      });

  Future<Response> linkStudent(String parentId, String studentId) =>
      _client.post(
        '/parents/$parentId/link-student',
        data: {'student_id': studentId},
      );

  Future<Response> unlinkStudent(String parentId, String studentId) =>
      _client.delete('/parents/$parentId/unlink-student/$studentId');
}
