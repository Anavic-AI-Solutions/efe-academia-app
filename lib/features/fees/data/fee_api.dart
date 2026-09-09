import 'package:dio/dio.dart';
import '../../../core/api/api_client.dart';

class FeeApi {
  final ApiClient _client;
  FeeApi(this._client);

  Future<Response> getFees({
    String? studentId,
    String? search,
    String? cursor,
    int limit = 20,
  }) =>
      _client.get('/fees', queryParameters: {
        if (studentId != null) 'student_id': studentId,
        if (search != null && search.isNotEmpty) 'search': search,
        if (cursor != null) 'cursor': cursor,
        'limit': limit,
      });

  Future<Response> getFee(String id) =>
      _client.get('/fees/$id');
}
