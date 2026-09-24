import 'package:dio/dio.dart';

import '../../../core/api/api_client.dart';

class AttendanceApi {
  final ApiClient _client;

  AttendanceApi(this._client);

  Future<Response> getAttendance(String classroomId) =>
      _client.get('/classrooms/$classroomId/attendance');

  Future<Response> saveAttendance(
    String classroomId, {
    required String date,
    required List<String> absentStudentIds,
  }) =>
      _client.post('/classrooms/$classroomId/attendance', data: {
        'date': date,
        'absent_student_ids': absentStudentIds,
      });
}
