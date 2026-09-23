import 'package:dio/dio.dart';
import '../../../core/api/api_client.dart';

class FeeApi {
  final ApiClient _client;
  FeeApi(this._client);

  Future<Response> getFees({
    String? studentId,
    String? studentAppId,
    String? search,
    String? cursor,
    int? page,
    int limit = 20,
  }) =>
      _client.get('/fees', queryParameters: {
        if (studentId != null) 'student_id': studentId,
        if (studentAppId != null) 'student_app_id': studentAppId,
        if (search != null && search.isNotEmpty) 'search': search,
        if (cursor != null) 'cursor': cursor,
        if (page != null) 'page': page,
        'per_page': limit,
      });

  Future<Response> getFee(String id) =>
      _client.get('/fees/$id');
}
