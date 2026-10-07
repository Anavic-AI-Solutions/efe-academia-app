import 'package:dio/dio.dart';

import '../../../core/api/api_client.dart';

class MaterialApi {
  final ApiClient _client;

  MaterialApi(this._client);

  static final Options _uploadOptions = Options(
    sendTimeout: const Duration(minutes: 5),
    receiveTimeout: const Duration(minutes: 5),
  );

  Future<Response> createMaterial(FormData data) =>
      _client.upload('/materials', data, options: _uploadOptions);

  Future<Response> updateMaterial(String id, Map<String, dynamic> data) =>
      _client.patch('/materials/$id', data: data);

  Future<Response> replaceFiles(String id, FormData data) =>
      _client.upload('/materials/$id/upload', data, options: _uploadOptions);

  Future<Response> deleteMaterial(String id) => _client.delete('/materials/$id');

  Future<Response> getMaterial(String id) => _client.get('/materials/$id');
}