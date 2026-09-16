import 'package:dio/dio.dart';

import '../../../core/api/api_exception.dart';
import '../../../core/api/cursor_pagination.dart';
import '../domain/fee_model.dart';
import 'fee_api.dart';

class FeeRepository {
  final FeeApi _api;

  FeeRepository(this._api);

  Future<CursorPagination<FeeModel>> getFees({
    String? studentId,
    String? search,
    String? cursor,
  }) async {
    try {
      final response = await _api.getFees(
        studentId: studentId,
        search: search,
        cursor: cursor,
      );
      final data = response.data;
      final items = (data['data'] as List)
          .map((e) => FeeModel.fromJson(e))
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

  Future<FeeModel> getFee(String id) async {
    try {
      final response = await _api.getFee(id);
      return FeeModel.fromJson(response.data);
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
