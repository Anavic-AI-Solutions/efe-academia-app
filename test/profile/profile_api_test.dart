import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:efe_mobile/core/api/api_client.dart';
import 'package:efe_mobile/core/storage/secure_storage.dart';
import 'package:efe_mobile/features/profile/data/profile_api.dart';
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

class _RecordedRequest {
  final String method;
  final String url;
  final String body;

  const _RecordedRequest({
    required this.method,
    required this.url,
    required this.body,
  });
}

/// Fake `HttpClientAdapter` that records the actual request that Dio would put
/// on the wire and replies with a configurable JSON body.
class _RecordingAdapter implements HttpClientAdapter {
  Object? responseBody;
  final List<_RecordedRequest> requests = [];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final bytes = <int>[];
    if (requestStream != null) {
      await for (final chunk in requestStream) {
        bytes.addAll(chunk);
      }
    }

    requests.add(
      _RecordedRequest(
        method: options.method,
        url: options.uri.toString(),
        body: utf8.decode(bytes, allowMalformed: true),
      ),
    );

    return ResponseBody.fromString(
      jsonEncode(responseBody ?? {'data': {}}),
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

ProfileApi _buildApi(_RecordingAdapter adapter) {
  final client = ApiClient(_FakeSecureStorage());
  client.dio.options.baseUrl = 'http://test';
  client.dio.httpClientAdapter = adapter;
  return ProfileApi(client);
}

void main() {
  test('update sends PATCH /profile with name and email', () async {
    final adapter = _RecordingAdapter()
      ..responseBody = {
        'data': {
          'id': 7,
          'name': 'Ada',
          'email': 'ada@example.com',
        },
      };
    final api = _buildApi(adapter);

    await api.update(name: 'Ada', email: 'ada@example.com');

    final request = adapter.requests.single;
    expect(request.method, 'PATCH');
    expect(request.url, 'http://test/profile');
    expect(
      jsonDecode(request.body),
      {'name': 'Ada', 'email': 'ada@example.com'},
    );
  });

  test('changePassword sends PATCH /profile/password with snake_case fields',
      () async {
    final adapter = _RecordingAdapter()..responseBody = {'success': true};
    final api = _buildApi(adapter);

    await api.changePassword(
      currentPassword: 'old-secret',
      password: 'new-secret',
      passwordConfirmation: 'new-secret',
    );

    final request = adapter.requests.single;
    expect(request.method, 'PATCH');
    expect(request.url, 'http://test/profile/password');
    expect(jsonDecode(request.body), {
      'current_password': 'old-secret',
      'password': 'new-secret',
      'password_confirmation': 'new-secret',
    });
  });

  test('uploadAvatar sends POST /profile/avatar with the avatar multipart part',
      () async {
    final adapter = _RecordingAdapter()
      ..responseBody = {
        'data': {'avatar': 'https://cdn/new.png'},
      };
    final api = _buildApi(adapter);

    await api.uploadAvatar(
      FormData.fromMap({
        'avatar': MultipartFile.fromBytes(
          Uint8List.fromList([1, 2, 3]),
          filename: 'photo.png',
        ),
      }),
    );

    final request = adapter.requests.single;
    expect(request.method, 'POST');
    expect(request.url, 'http://test/profile/avatar');
    expect(request.body, contains('name="avatar"'));
    expect(request.body, contains('filename="photo.png"'));
  });
}
