import 'package:dio/dio.dart';

import '../../../core/api/api_exception.dart';
import '../../../core/api/page_pagination.dart';
import '../domain/absence_model.dart';
import 'absence_api.dart';

class AbsenceRepository {
  final AbsenceApi _api;

  AbsenceRepository(this._api);

  Future<PageResult<AbsenceModel>> getAbsences({
    String? studentId,
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final response = await _api.getAbsences(
        studentId: studentId,
        page: page,
        limit: limit,
      );
      return PageResult.fromJson(
        response.data,
        page: page,
        perPage: limit,
        parse: AbsenceModel.fromJson,
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
