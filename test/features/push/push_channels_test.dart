import 'dart:io';

import 'package:efe_mobile/core/notifications/local_notifications_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('el canal por defecto del manifest es el creado en código', () {
    final manifest =
        File('android/app/src/main/AndroidManifest.xml').readAsStringSync();
    expect(
      manifest,
      contains(
          'com.google.firebase.messaging.default_notification_channel" android:value="${PushChannels.generalId}"'),
    );
    expect(
      File('android/app/src/main/res/drawable/ic_stat_efe.xml').existsSync(),
      isTrue,
    );
  });
}
