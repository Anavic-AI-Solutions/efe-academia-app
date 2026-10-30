import 'dart:async';

import 'package:dio/dio.dart';
import 'package:efe_mobile/core/api/api_client.dart';
import 'package:efe_mobile/core/storage/secure_storage.dart';
import 'package:efe_mobile/features/push/data/push_api.dart';
import 'package:efe_mobile/features/push/data/push_repository.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uuid/uuid.dart';

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
  Future<String> getOrCreateDeviceId() async {
    var id = values['device_id'];
    if (id == null) {
      id = const Uuid().v4();
      values['device_id'] = id;
    }
    return id;
  }

  @override
  Future<bool> hasSeenPushPrimer() async => values['push_primer_seen'] == '1';

  @override
  Future<void> savePushPrimerSeen() async => values['push_primer_seen'] = '1';
}

class _RecordingApiClient extends ApiClient {
  _RecordingApiClient() : super(_FakeSecureStorage());

  final List<Map<String, dynamic>> posts = [];
  final List<Map<String, dynamic>> deletes = [];
  bool throwOnPost = false;

  @override
  Future<Response> post(String path, {dynamic data}) async {
    if (throwOnPost) {
      throw DioException(requestOptions: RequestOptions(path: path));
    }
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

class _FakeTokens implements PushTokenProvider {
  _FakeTokens({required this.status, required this.token});

  PushPermission status;
  String? token;
  final StreamController<String> _controller =
      StreamController<String>.broadcast();

  @override
  Future<PushPermission> permissionStatus() async => status;

  @override
  Future<PushPermission> requestPermission() async => status;

  @override
  Future<String?> getToken() async => token;

  @override
  Stream<String> get onTokenRefresh => _controller.stream;

  void emitRefresh() => _controller.add(token ?? '');

  Future<void> close() => _controller.close();
}

PushRepository _repo(
  _RecordingApiClient client,
  _FakeSecureStorage storage,
  _FakeTokens tokens,
) {
  return PushRepository(
    api: PushApi(client),
    storage: storage,
    tokens: tokens,
  );
}

void main() {
  test('ensureRegistered postea una vez y la segunda es no-op', () async {
    dotenv.testLoad(fileInput: '');
    final client = _RecordingApiClient();
    final storage = _FakeSecureStorage();
    final tokens = _FakeTokens(status: PushPermission.granted, token: 'tok-1');
    addTearDown(tokens.close);
    final repo = _repo(client, storage, tokens);

    expect(await repo.ensureRegistered(), isTrue);
    expect(await repo.ensureRegistered(), isTrue);
    expect(client.posts.length, 1);
    expect(await storage.getFcmToken(), 'tok-1');
    expect(await storage.getOrCreateDeviceId(),
        await storage.getOrCreateDeviceId());
  });

  test('denegado o fallo de red no lanza y devuelve false', () async {
    dotenv.testLoad(fileInput: '');
    final client = _RecordingApiClient();
    final storage = _FakeSecureStorage();
    final tokens = _FakeTokens(status: PushPermission.denied, token: 'tok-1');
    addTearDown(tokens.close);
    final repo = _repo(client, storage, tokens);

    expect(await repo.ensureRegistered(), isFalse);
    expect(client.posts, isEmpty);

    tokens.status = PushPermission.granted;
    client.throwOnPost = true;
    expect(await repo.ensureRegistered(), isFalse);
  });

  test('refresh con token distinto re-registra', () async {
    dotenv.testLoad(fileInput: '');
    final client = _RecordingApiClient();
    final storage = _FakeSecureStorage();
    final tokens = _FakeTokens(status: PushPermission.granted, token: 'tok-1');
    addTearDown(tokens.close);
    final repo = _repo(client, storage, tokens);

    expect(await repo.ensureRegistered(), isTrue);
    expect(client.posts.length, 1);

    final sub = repo.tokenRefreshes.listen((_) => repo.ensureRegistered());
    tokens.token = 'tok-2';
    tokens.emitRefresh();
    await Future.delayed(const Duration(milliseconds: 100));
    await sub.cancel();

    expect(client.posts.length, 2);
    expect(client.posts.last['data']['token'], 'tok-2');
  });

  test('unregister borra en backend y local; sin token no llama', () async {
    dotenv.testLoad(fileInput: '');
    final client = _RecordingApiClient();
    final storage = _FakeSecureStorage();
    final tokens = _FakeTokens(status: PushPermission.granted, token: 'tok-1');
    addTearDown(tokens.close);
    final repo = _repo(client, storage, tokens);

    await storage.saveFcmToken('tok-1');
    await repo.unregisterCurrentDevice();
    expect(client.deletes.single['path'], '/push/unregister');
    expect(client.deletes.single['queryParameters'], {'token': 'tok-1'});
    expect(await storage.getFcmToken(), isNull);

    await repo.unregisterCurrentDevice();
    expect(client.deletes.length, 1);
  });
}
