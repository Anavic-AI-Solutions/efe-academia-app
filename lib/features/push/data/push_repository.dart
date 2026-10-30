import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';

import '../../../core/storage/secure_storage.dart';
import 'push_api.dart';

enum PushPermission { granted, denied }

abstract class PushTokenProvider {
  Future<PushPermission> permissionStatus();
  Future<PushPermission> requestPermission();
  Future<String?> getToken();
  Stream<String> get onTokenRefresh;
}

class FirebasePushTokenProvider implements PushTokenProvider {
  @override
  Future<PushPermission> permissionStatus() async {
    if (!Platform.isAndroid) return PushPermission.denied;
    final settings = await FirebaseMessaging.instance.getNotificationSettings();
    return settings.authorizationStatus == AuthorizationStatus.authorized
        ? PushPermission.granted
        : PushPermission.denied;
  }

  @override
  Future<PushPermission> requestPermission() async {
    if (!Platform.isAndroid) return PushPermission.denied;
    final settings = await FirebaseMessaging.instance.requestPermission();
    return settings.authorizationStatus == AuthorizationStatus.authorized
        ? PushPermission.granted
        : PushPermission.denied;
  }

  @override
  Future<String?> getToken() async {
    if (!Platform.isAndroid) return null;
    return FirebaseMessaging.instance.getToken();
  }

  @override
  Stream<String> get onTokenRefresh {
    if (!Platform.isAndroid) return const Stream.empty();
    return FirebaseMessaging.instance.onTokenRefresh;
  }
}

class PushRepository {
  PushRepository(
      {required PushApi api,
      required SecureStorage storage,
      required PushTokenProvider tokens})
      : _api = api,
        _storage = storage,
        _tokens = tokens;

  final PushApi _api;
  final SecureStorage _storage;
  final PushTokenProvider _tokens;

  Future<bool> ensureRegistered() async {
    try {
      final status = await _tokens.permissionStatus();
      if (status != PushPermission.granted) return false;
      final token = await _tokens.getToken();
      if (token == null || token.isEmpty) return false;
      final stored = await _storage.getFcmToken();
      if (stored == token) return true;
      final deviceId = await _storage.getOrCreateDeviceId();
      await _api.register(token: token, deviceId: deviceId);
      await _storage.saveFcmToken(token);
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> unregisterCurrentDevice() async {
    try {
      final token = await _storage.getFcmToken();
      if (token == null) return;
      try {
        await _api.unregister(token);
      } finally {
        await _storage.deleteFcmToken();
      }
    } catch (_) {}
  }

  Stream<String> get tokenRefreshes => _tokens.onTokenRefresh;
}
