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
    int? page,
    int limit = 20,
  }) =>
      _client.get('/qualifications', queryParameters: {
        if (studentId != null) 'student_id': studentId,
        if (classroomId != null) 'classroom_id': classroomId,
        if (search != null && search.isNotEmpty) 'search': search,
        if (cursor != null) 'cursor': cursor,
        if (page != null) 'page': page,
        'per_page': limit,
      });

  Future<Response> getQualification(String id) =>
      _client.get('/qualifications/$id');

  Future<Response> getClassroomGradesSummary(String classroomId) =>
      _client.get('/classrooms/$classroomId/grades-summary');

  Future<Response> createQualification({
    required String studentId,
    required String classroomId,
    required String score,
    required String type,
    required String period,
    String? description,
  }) =>
      _client.post('/qualifications', data: {
        'student_id': studentId,
        'classroom_id': classroomId,
        'score': score,
        'type': type,
        'period': period,
        if (description != null && description.isNotEmpty)
          'description': description,
      });
}
