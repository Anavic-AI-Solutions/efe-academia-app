import 'package:efe_mobile/app/locale/locale_provider.dart';
import 'package:efe_mobile/core/api/api_provider.dart';
import 'package:efe_mobile/core/storage/secure_storage.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';

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
  Future<void> saveFcmToken(String token) async {}

  @override
  Future<String?> getFcmToken() async => null;

  @override
  Future<void> deleteFcmToken() async {}

  @override
  Future<String> getOrCreateDeviceId() async => 'test-device';

  @override
  Future<bool> hasSeenPushPrimer() async => false;

  @override
  Future<void> savePushPrimerSeen() async {}
}

class _ThrowingSecureStorage extends _FakeSecureStorage {
  @override
  Future<String?> getLanguageCode() =>
      Future.error(StateError('storage unavailable'));
}

void main() {
  late _FakeSecureStorage storage;
  late ProviderContainer container;

  setUp(() {
    storage = _FakeSecureStorage();
    container = ProviderContainer(
      overrides: [secureStorageProvider.overrideWithValue(storage)],
    );
  });

  tearDown(() => container.dispose());

  test('defaults to es_AR', () {
    expect(container.read(localeProvider), const Locale('es', 'AR'));
    expect(Intl.defaultLocale, 'es_AR');
  });

  test('setLocale updates state, Intl.defaultLocale and persists', () async {
    await container.read(localeProvider.notifier).setLocale(const Locale('en'));

    expect(container.read(localeProvider), const Locale('en'));
    expect(Intl.defaultLocale, 'en');
    expect(storage.values['language_code'], 'en');
  });

  test('load restores the stored language', () async {
    storage.values['language_code'] = 'en';

    await container.read(localeProvider.notifier).load();

    expect(container.read(localeProvider), const Locale('en'));
    expect(Intl.defaultLocale, 'en');
  });

  test('load keeps es_AR when nothing is stored', () async {
    await container.read(localeProvider.notifier).load();

    expect(container.read(localeProvider), const Locale('es', 'AR'));
  });

  test('load keeps es_AR when storage fails', () async {
    final failing = ProviderContainer(
      overrides: [
        secureStorageProvider.overrideWithValue(_ThrowingSecureStorage()),
      ],
    );
    addTearDown(failing.dispose);

    await failing.read(localeProvider.notifier).load();

    expect(failing.read(localeProvider), const Locale('es', 'AR'));
  });
}
