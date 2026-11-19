import 'package:dio/dio.dart';

import '../../../core/api/api_exception.dart';
import '../../../core/api/page_pagination.dart';
import 'faq_api.dart';
import '../domain/faq_model.dart';

class FaqRepository {
  final FaqApi _api;
  FaqRepository(this._api);

  Future<PageResult<FaqModel>> getFaqs({
    String? search,
    int page = 1,
    int perPage = 10,
  }) async {
    final response = await _api.getFaqs(
      search: search,
      page: page,
      perPage: perPage,
    );

    final body = response.data is Map<String, dynamic>
        ? response.data as Map<String, dynamic>
        : <String, dynamic>{};
    final rawData = body['data'];
    final data = rawData is List
        ? rawData
            .whereType<Map<String, dynamic>>()
            .map(FaqModel.fromJson)
            .toList()
        : <FaqModel>[];
    final meta = body['meta'] is Map<String, dynamic>
        ? body['meta'] as Map<String, dynamic>
        : <String, dynamic>{};

    return PageResult(
      data: data,
      page: (meta['current_page'] as num?)?.toInt() ?? page,
      perPage: (meta['per_page'] as num?)?.toInt() ?? perPage,
      total: (meta['total'] as num?)?.toInt() ?? data.length,
    );
  }

  Future<FaqModel> createFaq({
    required String question,
    required String answer,
  }) async {
    try {
      final response = await _api.createFaq(
        _payload(question: question, answer: answer),
      );
      return FaqModel.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<FaqModel> updateFaq(
    String id, {
    required String question,
    required String answer,
  }) async {
    try {
      final response = await _api.updateFaq(
        id,
        _payload(question: question, answer: answer),
      );
      return FaqModel.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<void> deleteFaq(String id) async {
    try {
      await _api.deleteFaq(id);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Map<String, dynamic> _payload({
    required String question,
    required String answer,
  }) {
    return {
      'question': question,
      'answer': answer,
    };
  }

  /// Propaga tal cual la excepción que armó el interceptor (incluida
  /// [ValidationException] con sus errores por campo).
  ApiException _handleDioError(DioException e) {
    if (e.error is ApiException) return e.error as ApiException;
    return ApiException(
      message: e.message ?? 'Ocurrió un error inesperado',
      statusCode: e.response?.statusCode,
    );
  }
}
