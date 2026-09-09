import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorage {
  final FlutterSecureStorage _storage;

  SecureStorage({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  static const _tokenKey = 'auth_token';
  static const _themeKey = 'theme_mode';

  Future<void> saveToken(String token) async =>
      await _storage.write(key: _tokenKey, value: token);

  Future<String?> getToken() async => await _storage.read(key: _tokenKey);

  Future<void> deleteToken() async => await _storage.delete(key: _tokenKey);

  Future<void> clearAll() async => await _storage.deleteAll();

  Future<void> saveThemeMode(String mode) async =>
      await _storage.write(key: _themeKey, value: mode);

  Future<String?> getThemeMode() async => await _storage.read(key: _themeKey);
}
