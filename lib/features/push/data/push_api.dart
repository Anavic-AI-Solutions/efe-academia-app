import '../../../core/api/api_client.dart';

class PushApi {
  PushApi(this._client);
  final ApiClient _client;

  Future<void> register({required String token, required String deviceId}) =>
      _client.post('/push/register', data: {
        'token': token,
        'platform': 'android',
        'device_id': deviceId,
      });

  Future<void> unregister(String token) =>
      _client.delete('/push/unregister', queryParameters: {'token': token});
}
