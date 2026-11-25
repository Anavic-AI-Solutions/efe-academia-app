import 'package:dio/dio.dart';

import '../../../core/api/api_client.dart';

class ProfessorApi {
  final ApiClient _client;
  ProfessorApi(this._client);

  Future<Response> getProfessors({
    String? search,
    String? cursor,
    int limit = 20,
  }) =>
      _client.get('/professors', queryParameters: {
        if (search != null && search.isNotEmpty) 'search': search,
        if (cursor != null && cursor.isNotEmpty) 'cursor': cursor,
        'per_page': limit,
      });

  Future<Response> getProfessor(String id) => _client.get('/professors/$id');

  Future<Response> createProfessor(Map<String, dynamic> data) =>
      _client.post('/professors', data: data);

  Future<Response> updateProfessor(String id, Map<String, dynamic> data) =>
      _client.patch('/professors/$id', data: data);

  Future<Response> deleteProfessor(String id) =>
      _client.delete('/professors/$id');
}
