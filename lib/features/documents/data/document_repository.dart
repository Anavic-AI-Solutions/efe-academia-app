import 'package:dio/dio.dart';

import '../../../core/api/api_exception.dart';
import '../../../core/api/cursor_pagination.dart';
import '../domain/document_model.dart';
import 'document_api.dart';

class DocumentRepository {
  final DocumentApi _api;
  DocumentRepository(this._api);

  Future<CursorPagination<DocumentModel>> getDocuments(
      {String? cursor}) async {
    try {
      final response = await _api.getDocuments(cursor: cursor);
      final data = response.data;
      final items = data is Map<String, dynamic>
          ? (data['data'] as List<dynamic>? ?? [])
          : data as List<dynamic>? ?? [];
      final meta = data is Map<String, dynamic>
          ? (data['meta'] as Map<String, dynamic>? ?? {})
          : <String, dynamic>{};
      return CursorPagination(
        data: items
            .map((e) => DocumentModel.fromJson(e as Map<String, dynamic>))
            .toList(),
        nextCursor: meta['cursor'],
        hasMore: meta['has_more'] ?? false,
        total: meta['total'],
      );
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<DocumentModel> getDocument(String id) async {
    try {
      final response = await _api.getDocument(id);
      final data = response.data;
      if (data is Map<String, dynamic> && data['data'] is Map) {
        return DocumentModel.fromJson(
            Map<String, dynamic>.from(data['data'] as Map));
      }
      return DocumentModel.fromJson(Map<String, dynamic>.from(data as Map));
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
