import 'package:efe_mobile/app/theme/theme_provider.dart';
import 'package:efe_mobile/core/api/api_provider.dart';
import 'package:efe_mobile/core/storage/secure_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
  Future<String?> getThemeMode() =>
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

  test('defaults to light', () {
    expect(container.read(themeModeProvider), ThemeMode.light);
  });

  test('setThemeMode updates state and persists', () async {
    await container
        .read(themeModeProvider.notifier)
        .setThemeMode(ThemeMode.dark);

    expect(container.read(themeModeProvider), ThemeMode.dark);
    expect(storage.values['theme_mode'], 'dark');
  });

  test('setThemeMode persists system', () async {
    await container
        .read(themeModeProvider.notifier)
        .setThemeMode(ThemeMode.system);

    expect(container.read(themeModeProvider), ThemeMode.system);
    expect(storage.values['theme_mode'], 'system');
  });

  test('load restores a stored dark mode', () async {
    storage.values['theme_mode'] = 'dark';

    await container.read(themeModeProvider.notifier).load();

    expect(container.read(themeModeProvider), ThemeMode.dark);
  });

  test('load restores a stored system mode', () async {
    storage.values['theme_mode'] = 'system';

    await container.read(themeModeProvider.notifier).load();

    expect(container.read(themeModeProvider), ThemeMode.system);
  });

  test('load keeps light when nothing is stored', () async {
    await container.read(themeModeProvider.notifier).load();

    expect(container.read(themeModeProvider), ThemeMode.light);
  });

  test('load keeps light when the stored value is unknown', () async {
    storage.values['theme_mode'] = 'sepia';

    await container.read(themeModeProvider.notifier).load();

    expect(container.read(themeModeProvider), ThemeMode.light);
  });

  test('load keeps light when storage fails', () async {
    final failing = ProviderContainer(
      overrides: [
        secureStorageProvider.overrideWithValue(_ThrowingSecureStorage()),
      ],
    );
    addTearDown(failing.dispose);

    await failing.read(themeModeProvider.notifier).load();

    expect(failing.read(themeModeProvider), ThemeMode.light);
  });
}
