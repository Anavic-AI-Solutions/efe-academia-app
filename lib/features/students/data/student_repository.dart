import 'package:dio/dio.dart';

import '../../../core/api/api_exception.dart';
import '../../../core/api/page_pagination.dart';
import '../../classrooms/domain/classroom_model.dart';
import '../domain/student_model.dart';
import 'student_api.dart';

class StudentRepository {
  final StudentApi _api;

  StudentRepository(this._api);

  Future<PageResult<StudentModel>> getStudents({
    String? search,
    String? status,
    String? year,
    String? branch,
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final response = await _api.getStudents(
        search: search,
        status: status,
        year: year,
        branch: branch,
        page: page,
        limit: limit,
      );
      return PageResult.fromJson(
        response.data,
        page: page,
        perPage: limit,
        parse: StudentModel.fromJson,
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

  Future<List<ClassroomModel>> getClassrooms(String studentId) async {
    try {
      final response = await _api.getClassrooms(studentId);
      final data = response.data['data'];
      if (data is! List) return const [];
      return data
          .whereType<Map<String, dynamic>>()
          .map(ClassroomModel.fromJson)
          .toList();
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
