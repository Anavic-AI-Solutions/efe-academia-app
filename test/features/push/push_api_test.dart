import 'package:dio/dio.dart';
import 'package:efe_mobile/core/api/api_client.dart';
import 'package:efe_mobile/core/storage/secure_storage.dart';
import 'package:efe_mobile/features/push/data/push_api.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeSecureStorage implements SecureStorage {
  final Map<String, String> values = {};

  @override
  Future<void> saveToken(String token) async => values['auth_token'] = token;

  @override
  Future<String?> getToken() async => values['auth_token'];

  @override
  Future<void> deleteToken() async => values.remove('auth_token');

  @override
  Future<void> clearAll() async => values.clear();

  @override
  Future<void> saveThemeMode(String mode) async => values['theme_mode'] = mode;

  @override
  Future<String?> getThemeMode() async => values['theme_mode'];

  @override
  Future<void> saveLanguageCode(String code) async =>
      values['language_code'] = code;

  @override
  Future<String?> getLanguageCode() async => values['language_code'];

  @override
  Future<void> saveFcmToken(String token) async => values['fcm_token'] = token;

  @override
  Future<String?> getFcmToken() async => values['fcm_token'];

  @override
  Future<void> deleteFcmToken() async => values.remove('fcm_token');

  @override
  Future<String> getOrCreateDeviceId() async => values['device_id'] ?? 'dev-x';

  @override
  Future<bool> hasSeenPushPrimer() async => values['push_primer_seen'] == '1';

  @override
  Future<void> savePushPrimerSeen() async => values['push_primer_seen'] = '1';
}

class _RecordingApiClient extends ApiClient {
  _RecordingApiClient() : super(_FakeSecureStorage());

  final List<Map<String, dynamic>> posts = [];
  final List<Map<String, dynamic>> deletes = [];

  @override
  Future<Response> post(String path, {dynamic data}) async {
    posts.add({'path': path, 'data': data});
    return Response(
      requestOptions: RequestOptions(path: path),
      statusCode: 201,
      data: {},
    );
  }

  @override
  Future<Response> delete(String path,
      {Map<String, dynamic>? queryParameters}) async {
    deletes.add({'path': path, 'queryParameters': queryParameters});
    return Response(
      requestOptions: RequestOptions(path: path),
      statusCode: 200,
      data: {},
    );
  }
}

void main() {
  test('register postea token, plataforma y device al endpoint', () async {
    dotenv.testLoad(fileInput: '');
    final client = _RecordingApiClient();
    await PushApi(client).register(token: 'tok-1', deviceId: 'dev-1');
    expect(client.posts.single['path'], '/push/register');
    expect(client.posts.single['data'],
        {'token': 'tok-1', 'platform': 'android', 'device_id': 'dev-1'});
  });

  test('unregister borra con el token como query', () async {
    dotenv.testLoad(fileInput: '');
    final client = _RecordingApiClient();
    await PushApi(client).unregister('tok-1');
    expect(client.deletes.single['path'], '/push/unregister');
    expect(client.deletes.single['queryParameters'], {'token': 'tok-1'});
  });
}
