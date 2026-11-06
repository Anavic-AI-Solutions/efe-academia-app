import 'package:dio/dio.dart';
import '../../../core/api/api_client.dart';

class LibraryApi {
  final ApiClient _client;
  LibraryApi(this._client);

  Future<Response> getMaterials({
    String? search,
    String? nextCursor,
    int perPage = 20,
  }) =>
      _client.get('/materials', queryParameters: {
        if (search != null && search.isNotEmpty) 'search': search,
        if (nextCursor != null && nextCursor.isNotEmpty) 'cursor': nextCursor,
        'per_page': perPage,
      });
}
