import 'package:dio/dio.dart';
import '../../../core/api/api_client.dart';

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

  Future<Response> createFaq(Map<String, dynamic> data) =>
      _client.post('/faqs', data: data);

  Future<Response> updateFaq(String id, Map<String, dynamic> data) =>
      _client.patch('/faqs/$id', data: data);

  Future<Response> deleteFaq(String id) => _client.delete('/faqs/$id');
}
