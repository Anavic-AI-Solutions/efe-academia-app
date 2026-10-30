import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class DesktopSettings {
  final FlutterSecureStorage _storage;

  DesktopSettings({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  static const _autostartConfiguredKey = 'tray_autostart_configured';

  Future<bool> isAutostartConfigured() async =>
      await _storage.read(key: _autostartConfiguredKey) == '1';

  Future<void> markAutostartConfigured() async =>
      await _storage.write(key: _autostartConfiguredKey, value: '1');
}
