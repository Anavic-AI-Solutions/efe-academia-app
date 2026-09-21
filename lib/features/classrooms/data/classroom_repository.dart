import 'package:dio/dio.dart';

import '../../../core/api/api_exception.dart';
import '../../../core/api/cursor_pagination.dart';
import '../domain/classroom_filters.dart';
import '../domain/classroom_model.dart';
import 'classroom_api.dart';

class ClassroomRepository {
  final ClassroomApi _api;

  ClassroomRepository(this._api);

  Future<CursorPagination<ClassroomModel>> getClassrooms({
    String? search,
    String? cursor,
    String? branch,
    String? level,
    String? year,
    String? status,
  }) async {
    try {
      final response = await _api.getClassrooms(
        search: search,
        cursor: cursor,
        branch: branch,
        level: level,
        year: year,
        status: status,
      );
      final data = response.data;
      final items = (data['data'] as List)
          .map((e) => ClassroomModel.fromJson(e))
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

  Future<ClassroomModel> getClassroom(String id) async {
    try {
      final response = await _api.getClassroom(id);
      return ClassroomModel.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<ClassroomFilters> getFilters() async {
    try {
      final response = await _api.getClassroomFilters();
      return ClassroomFilters.fromJson(response.data);
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
