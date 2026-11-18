import 'package:dio/dio.dart';
import '../../../core/api/api_client.dart';

class NewsApi {
  final ApiClient _client;
  NewsApi(this._client);

  static final Options _uploadOptions = Options(
    sendTimeout: const Duration(minutes: 5),
    receiveTimeout: const Duration(minutes: 5),
  );

  Future<Response> getNews({String? cursor, int limit = 20}) =>
      _client.get('/news', queryParameters: {
        if (cursor != null) 'cursor': cursor,
        'per_page': limit,
      });

  Future<Response> createNews(FormData data) =>
      _client.upload('/news', data, options: _uploadOptions);

  /// PHP no parsea `multipart/form-data` en PATCH, por eso va por POST con el
  /// campo `_method` (lo agrega el repositorio).
  Future<Response> updateNews(String id, FormData data) =>
      _client.upload('/news/$id', data, options: _uploadOptions);

  Future<Response> deleteNews(String id) => _client.delete('/news/$id');
}
