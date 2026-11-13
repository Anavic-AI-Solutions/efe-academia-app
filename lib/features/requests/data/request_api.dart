import 'package:dio/dio.dart';

import '../../../core/api/api_client.dart';

class RequestApi {
  final ApiClient _client;

  RequestApi(this._client);

  Future<Response> getRequests({
    String? search,
    String status = 'pending',
    String type = 'all',
    int page = 1,
    int perPage = 20,
  }) =>
      _client.get('/requests', queryParameters: {
        if (search != null && search.isNotEmpty) 'search': search,
        'status': status,
        'type': type,
        'page': page,
        'per_page': perPage,
      });

  Future<Response> getStudentRequest(String id) =>
      _client.get('/requests/students/$id');

  Future<Response> getParentRequest(String id) =>
      _client.get('/requests/parents/$id');

  Future<Response> approveStudent(String id, String classroomId) =>
      _client.post(
        '/requests/students/$id/approve',
        data: {'classroom_id': classroomId},
      );

  Future<Response> rejectStudent(String id) =>
      _client.post('/requests/students/$id/reject');

  Future<Response> approveParent(String id) =>
      _client.post('/requests/parents/$id/approve');

  Future<Response> rejectParent(String id) =>
      _client.post('/requests/parents/$id/reject');
}
