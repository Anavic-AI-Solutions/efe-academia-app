import 'package:dio/dio.dart';

import '../../../core/api/api_client.dart';

class RelationsApi {
  final ApiClient _client;
  RelationsApi(this._client);

  Future<Response> getRelations({
    String? query,
    String? cursor,
    int limit = 50,
  }) =>
      _client.get('/relations', queryParameters: {
        if (query != null) 'q': query,
        if (cursor != null) 'cursor': cursor,
        'per_page': limit,
      });
}
