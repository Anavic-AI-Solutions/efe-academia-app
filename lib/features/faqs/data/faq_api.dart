import 'package:dio/dio.dart';
import '../../../core/api/api_client.dart';
import '../domain/faq_model.dart';

class FaqApi {
  final ApiClient _client;
  FaqApi(this._client);

  Future<Response> getFaqs({
    String? search,
    int page = 1,
    int perPage = 20,
  }) =>
      _client.get('/faqs', queryParameters: {
        if (search != null && search.isNotEmpty) 'search': search,
        'page': page,
        'per_page': perPage,
      });
}