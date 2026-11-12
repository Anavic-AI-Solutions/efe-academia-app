import 'package:dio/dio.dart';

import '../../../core/api/api_client.dart';

class RoleModeApi {
  final ApiClient _client;

  RoleModeApi(this._client);

  Future<Response> switchRole(String role) =>
      _client.post('/user-data/switch-role', data: {'role': role});
}
