import 'package:dio/dio.dart';

import '../../../core/api/api_exception.dart';
import '../domain/attendance_day.dart';
import 'attendance_api.dart';

class AttendanceRepository {
  final AttendanceApi _api;

  AttendanceRepository(this._api);

  Future<AttendanceDay> getAttendance(String classroomId) async {
    try {
      final response = await _api.getAttendance(classroomId);
      return AttendanceDay.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<void> saveAttendance(
    String classroomId, {
    required String date,
    required List<String> absentStudentIds,
  }) async {
    try {
      await _api.saveAttendance(
        classroomId,
        date: date,
        absentStudentIds: absentStudentIds,
      );
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  ApiException _handleDioError(DioException e) {
    if (e.error is ApiException) return e.error as ApiException;
    return ApiException(
      message: e.message ?? 'Ocurrió un error inesperado',
      statusCode: e.response?.statusCode,
    );
  }
}
