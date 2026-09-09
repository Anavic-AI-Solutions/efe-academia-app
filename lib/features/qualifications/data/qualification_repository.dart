import 'package:dio/dio.dart';

import '../../../core/api/api_exception.dart';
import '../../../core/api/cursor_pagination.dart';
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
        nextCursor: meta['next_cursor'],
        hasMore: meta['has_more'] ?? false,
        total: meta['total'],
      );
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  ApiException _handleDioError(DioException e) {
    if (e.error is ApiException) return e.error as ApiException;
    return ApiException(
      message: e.message ?? 'An unexpected error occurred',
      statusCode: e.response?.statusCode,
    );
  }
}
