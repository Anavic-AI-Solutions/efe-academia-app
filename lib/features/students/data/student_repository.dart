import 'package:dio/dio.dart';

import '../../../core/api/api_exception.dart';
import '../../../core/api/cursor_pagination.dart';
import '../domain/student_model.dart';
import 'student_api.dart';

class StudentRepository {
  final StudentApi _api;

  StudentRepository(this._api);

  Future<CursorPagination<StudentModel>> getStudents({
    String? search,
    String? status,
    String? year,
    String? branch,
    String? cursor,
  }) async {
    try {
      final response = await _api.getStudents(
        search: search,
        status: status,
        year: year,
        branch: branch,
        cursor: cursor,
      );
      final data = response.data;
      final items = (data['data'] as List)
          .map((e) => StudentModel.fromJson(e))
          .toList();
      final meta = data['meta'] ?? {};
      return CursorPagination(
        data: items,
        nextCursor: meta['cursor'],
        hasMore: meta['has_more'] ?? false,
        total: meta['total'],
      );
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<StudentModel> getStudent(String id) async {
    try {
      final response = await _api.getStudent(id);
      return StudentModel.fromJson(response.data);
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
