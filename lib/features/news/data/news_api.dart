import 'package:dio/dio.dart';
import '../../../core/api/api_client.dart';

class NewsApi {
  final ApiClient _client;
  NewsApi(this._client);

  Future<Response> getNews({String? cursor, int limit = 20}) =>
      _client.get('/news', queryParameters: {
        if (cursor != null) 'cursor': cursor,
        'per_page': limit,
      });
}
