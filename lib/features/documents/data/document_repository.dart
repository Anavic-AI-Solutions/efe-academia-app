import 'package:dio/dio.dart';

import '../../../core/api/api_exception.dart';
import '../../../core/api/cursor_pagination.dart';
import '../../../core/utils/upload_file.dart';
import '../domain/document_model.dart';
import 'document_api.dart';

class DocumentRepository {
  final DocumentApi _api;
  DocumentRepository(this._api);

  Future<CursorPagination<DocumentModel>> getDocuments({String? cursor}) async {
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
        nextCursor: meta['cursor']?.toString(),
        hasMore: meta['has_more'] == true,
        total: int.tryParse('${meta['total']}'),
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

  /// URL absoluta de descarga directa para el detalle.
  String downloadUrl(String id) => _api.downloadUrl(id);

  Future<DocumentModel> createDocument({
    required String title,
    String description = '',
    UploadFile? file,
  }) async {
    final form = await _buildFormData(
      title: title,
      description: description,
      file: file,
    );
    try {
      final response = await _api.createDocument(form);
      return DocumentModel.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<DocumentModel> updateDocument(
    String id, {
    required String title,
    String description = '',
    UploadFile? file,
  }) async {
    final form = await _buildFormData(
      title: title,
      description: description,
      file: file,
      isUpdate: true,
    );
    try {
      final response = await _api.updateDocument(id, form);
      return DocumentModel.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<void> deleteDocument(String id) async {
    try {
      await _api.deleteDocument(id);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<FormData> _buildFormData({
    required String title,
    required String description,
    UploadFile? file,
    bool isUpdate = false,
  }) async {
    final form = FormData();
    if (isUpdate) form.fields.add(const MapEntry('_method', 'PATCH'));
    form.fields.add(MapEntry('title', title));
    form.fields.add(MapEntry('description', description));
    if (file != null) {
      final multipart = file.bytes != null
          ? MultipartFile.fromBytes(file.bytes!, filename: file.name)
          : await MultipartFile.fromFile(file.path!, filename: file.name);
      form.files.add(MapEntry('file', multipart));
    }
    return form;
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
