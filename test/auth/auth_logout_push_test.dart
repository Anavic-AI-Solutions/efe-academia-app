import 'package:dio/dio.dart';
import 'package:efe_mobile/core/api/api_client.dart';
import 'package:efe_mobile/core/storage/secure_storage.dart';
import 'package:efe_mobile/features/auth/data/auth_repository.dart';
import 'package:efe_mobile/features/auth/domain/user_model.dart';
import 'package:efe_mobile/features/auth/providers/auth_provider.dart';
import 'package:efe_mobile/features/push/data/push_api.dart';
import 'package:efe_mobile/features/push/data/push_repository.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uuid/uuid.dart';

class _FakeSecureStorage implements SecureStorage {
  final Map<String, String> values = {'fcm_token': 'tok-1'};

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
  _RecordingApiClient(super.storage, this.calls);

  final List<String> calls;

  @override
  Future<Response> delete(String path,
      {Map<String, dynamic>? queryParameters}) async {
    calls.add('push.unregister');
    return Response(
      requestOptions: RequestOptions(path: path),
      statusCode: 200,
      data: {},
    );
  }
}

class _DeniedTokens implements PushTokenProvider {
  @override
  Future<PushPermission> permissionStatus() async => PushPermission.denied;

  @override
  Future<PushPermission> requestPermission() async => PushPermission.denied;

  @override
  Future<String?> getToken() async => null;

  @override
  Stream<String> get onTokenRefresh => const Stream.empty();
}

class _FakeAuthRepository implements AuthRepository {
  _FakeAuthRepository(this.calls);

  final List<String> calls;

  @override
  Future<bool> hasToken() async => false;

  @override
  Future<UserModel> getCurrentUser() => Future.error(UnimplementedError());

  @override
  Future<UserModel> login({
    required String email,
    required String password,
  }) =>
      Future.error(UnimplementedError());

  @override
  Future<UserModel> register({
    required String name,
    required String email,
    required String password,
    required String passwordConfirmation,
  }) =>
      Future.error(UnimplementedError());

  @override
  Future<void> logout() async {
    calls.add('auth.logout');
  }

  @override
  Future<void> forgotPassword(String email) =>
      Future.error(UnimplementedError());

  @override
  Future<void> loadTokenIntoClient() => Future.error(UnimplementedError());
}

void main() {
  test('logout desregistra el push antes de limpiar la sesión', () async {
    dotenv.testLoad(fileInput: '');
    final calls = <String>[];
    final storage = _FakeSecureStorage();
    final client = _RecordingApiClient(storage, calls);
    final pushRepo = PushRepository(
      api: PushApi(client),
      storage: storage,
      tokens: _DeniedTokens(),
    );
    final notifier = AuthNotifier(_FakeAuthRepository(calls), pushRepo);

    await notifier.logout();

    expect(calls, ['push.unregister', 'auth.logout']);
    expect(await storage.getFcmToken(), isNull);
  });
}
