import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:uuid/uuid.dart';

class SecureStorage {
  final FlutterSecureStorage _storage;

  SecureStorage({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  static const _tokenKey = 'auth_token';
  static const _themeKey = 'theme_mode';
  static const _languageKey = 'language_code';
  static const _fcmTokenKey = 'fcm_token';
  static const _deviceIdKey = 'device_id';
  static const _pushPrimerSeenKey = 'push_primer_seen';

  Future<void> saveToken(String token) async =>
      await _storage.write(key: _tokenKey, value: token);

  Future<String?> getToken() async => await _storage.read(key: _tokenKey);

  Future<void> deleteToken() async => await _storage.delete(key: _tokenKey);

  Future<void> clearAll() async => await _storage.deleteAll();

  Future<void> saveThemeMode(String mode) async =>
      await _storage.write(key: _themeKey, value: mode);

  Future<String?> getThemeMode() async => await _storage.read(key: _themeKey);

  Future<void> saveLanguageCode(String code) async =>
      await _storage.write(key: _languageKey, value: code);

  Future<String?> getLanguageCode() async =>
      await _storage.read(key: _languageKey);

  Future<void> saveFcmToken(String token) async =>
      await _storage.write(key: _fcmTokenKey, value: token);

  Future<String?> getFcmToken() async => await _storage.read(key: _fcmTokenKey);

  Future<void> deleteFcmToken() async =>
      await _storage.delete(key: _fcmTokenKey);

  Future<String> getOrCreateDeviceId() async {
    final existing = await _storage.read(key: _deviceIdKey);
    if (existing != null) return existing;
    final id = const Uuid().v4();
    await _storage.write(key: _deviceIdKey, value: id);
    return id;
  }

  Future<bool> hasSeenPushPrimer() async =>
      await _storage.read(key: _pushPrimerSeenKey) == '1';

  Future<void> savePushPrimerSeen() async =>
      await _storage.write(key: _pushPrimerSeenKey, value: '1');
}
