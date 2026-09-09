import 'package:dio/dio.dart';
import '../../../core/api/api_client.dart';

class QualificationApi {
  final ApiClient _client;
  QualificationApi(this._client);

  Future<Response> getQualifications({
    String? studentId,
    String? classroomId,
    String? search,
    String? cursor,
    int limit = 20,
  }) =>
      _client.get('/qualifications', queryParameters: {
        if (studentId != null) 'student_id': studentId,
        if (classroomId != null) 'classroom_id': classroomId,
        if (search != null && search.isNotEmpty) 'search': search,
        if (cursor != null) 'cursor': cursor,
        'limit': limit,
      });

  Future<Response> getQualification(String id) =>
      _client.get('/qualifications/$id');
}
