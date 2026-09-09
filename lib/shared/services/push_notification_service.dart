import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/api_provider.dart';
import '../../core/api/api_client.dart';

class PushNotificationService {
  final ApiClient _api;
  final FlutterLocalNotificationsPlugin _localNotifications;

  PushNotificationService(this._api)
      : _localNotifications = FlutterLocalNotificationsPlugin();

  Future<void> initialize() async {
    const settings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(),
    );
    await _localNotifications.initialize(settings);
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
  }

  Future<void> registerToken() async {
    final token = await FirebaseMessaging.instance.getToken();
    if (token != null) {
      await _api.post('/push/register', data: {
        'token': token,
        'platform': 'mobile',
      });
    }
  }

  Future<void> unregisterToken() async {
    await _api.delete('/push/unregister');
  }

  void _handleForegroundMessage(RemoteMessage message) {
    final notification = message.notification;
    if (notification == null) return;
    _localNotifications.show(
      notification.hashCode,
      notification.title,
      notification.body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'efe_channel',
          'EFE Notifications',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
    );
  }
}

final pushNotificationServiceProvider = Provider<PushNotificationService>((ref) {
  return PushNotificationService(ref.watch(apiClientProvider));
});
