import 'package:dio/dio.dart';
import '../../../core/api/api_client.dart';

class DocumentApi {
  final ApiClient _client;
  DocumentApi(this._client);

  static final Options _uploadOptions = Options(
    sendTimeout: const Duration(minutes: 5),
    receiveTimeout: const Duration(minutes: 5),
  );

  Future<Response> getDocuments({String? cursor, int limit = 20}) =>
      _client.get('/documents', queryParameters: {
        if (cursor != null) 'cursor': cursor,
        'per_page': limit,
      });

  Future<Response> getDocument(String id) => _client.get('/documents/$id');

  Future<Response> createDocument(FormData data) =>
      _client.upload('/documents', data, options: _uploadOptions);

  /// PHP no parsea `multipart/form-data` en PATCH, por eso va por POST con el
  /// campo `_method` (lo agrega el repositorio).
  Future<Response> updateDocument(String id, FormData data) =>
      _client.upload('/documents/$id', data, options: _uploadOptions);

  Future<Response> deleteDocument(String id) =>
      _client.delete('/documents/$id');

  /// URL absoluta de descarga directa (fallback cuando no hay file/media URL).
  String downloadUrl(String id) {
    final base = _client.dio.options.baseUrl.replaceAll(RegExp(r'/+$'), '');
    return '$base/documents/$id/download';
  }
}
