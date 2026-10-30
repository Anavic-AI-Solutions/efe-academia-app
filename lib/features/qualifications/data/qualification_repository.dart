import 'package:dio/dio.dart';

import '../../../core/api/api_exception.dart';
import '../../../core/api/cursor_pagination.dart';
import '../../../core/api/page_pagination.dart';
import '../domain/boletin_data.dart';
import '../domain/classroom_grades_summary.dart';
import '../domain/qualification_model.dart';
import 'qualification_api.dart';

class QualificationRepository {
  final QualificationApi _api;

  QualificationRepository(this._api);

  Future<CursorPagination<QualificationModel>> getQualifications({
    String? studentId,
    String? classroomId,
    String? search,
    String? cursor,
  }) async {
    try {
      final response = await _api.getQualifications(
        studentId: studentId,
        classroomId: classroomId,
        search: search,
        cursor: cursor,
      );
      final data = response.data;
      final items = (data['data'] as List)
          .map((e) => QualificationModel.fromJson(e))
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

  Future<PageResult<QualificationModel>> getStudentQualifications(
    String studentId, {
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final response = await _api.getQualifications(
        studentId: studentId,
        page: page,
        limit: limit,
      );
      return PageResult.fromJson(
        response.data,
        page: page,
        perPage: limit,
        parse: QualificationModel.fromJson,
      );
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<ClassroomGradesSummary> getClassroomGradesSummary(
    String classroomId,
  ) async {
    try {
      final response = await _api.getClassroomGradesSummary(classroomId);
      return ClassroomGradesSummary.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<void> createQualification({
    required String studentId,
    required String classroomId,
    required String score,
    required String type,
    required String period,
    String? description,
  }) async {
    try {
      await _api.createQualification(
        studentId: studentId,
        classroomId: classroomId,
        score: score,
        type: type,
        period: period,
        description: description,
      );
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<BoletinData> getBoletin(String studentId, String classroomId) async {
    try {
      final response = await _api.getBoletin(studentId, classroomId);
      return BoletinData.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<String> getBoletinUrl(String studentId, String classroomId) async {
    try {
      final response = await _api.getBoletinLink(studentId, classroomId);
      return response.data['data']['url']?.toString() ?? '';
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
