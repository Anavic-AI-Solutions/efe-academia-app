import 'package:dio/dio.dart';
import '../../../core/api/api_client.dart';

class DocumentApi {
  final ApiClient _client;
  DocumentApi(this._client);

  Future<Response> getDocuments({String? cursor, int limit = 20}) =>
      _client.get('/documents', queryParameters: {
        if (cursor != null) 'cursor': cursor,
        'per_page': limit,
      });

  Future<Response> getDocument(String id) => _client.get('/documents/$id');
}
