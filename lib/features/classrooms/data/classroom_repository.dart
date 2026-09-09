import 'package:dio/dio.dart';

import '../../../core/api/api_exception.dart';
import '../../../core/api/cursor_pagination.dart';
import '../domain/classroom_model.dart';
import 'classroom_api.dart';

class ClassroomRepository {
  final ClassroomApi _api;

  ClassroomRepository(this._api);

  Future<CursorPagination<ClassroomModel>> getClassrooms({
    String? search,
    String? cursor,
  }) async {
    try {
      final response = await _api.getClassrooms(
        search: search,
        cursor: cursor,
      );
      final data = response.data;
      final items = (data['data'] as List)
          .map((e) => ClassroomModel.fromJson(e))
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

  Future<ClassroomModel> getClassroom(String id) async {
    try {
      final response = await _api.getClassroom(id);
      return ClassroomModel.fromJson(response.data);
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
