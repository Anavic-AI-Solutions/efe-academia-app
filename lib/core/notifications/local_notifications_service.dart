import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../../features/desktop/desktop_toast.dart';

/// IDs de canal de notificaciones push (solo Android).
///
/// Deben coincidir con lo que envía el backend (Task 1): el manifiesto
/// declara `efe_general` como canal por defecto de FCM.
class PushChannels {
  static const generalId = 'efe_general';
  static const messagesId = 'efe_mensajes';
}

/// Avisos locales mostrados al recibir un push FCM en primer plano.
///
/// Solo Android. [showPush] no hace nada si se llama antes de [init]
/// (guardia interna), para no romper nunca el arranque ni los tests.
class LocalNotificationsService {
  LocalNotificationsService({FlutterLocalNotificationsPlugin? plugin})
      : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  final FlutterLocalNotificationsPlugin _plugin;
  bool _initialized = false;
  int _desktopId = 0;
  void Function(String route)? _onTap;

  /// Escritorio real: host Linux/Windows Y target linux/windows.
  static bool _isDesktopTarget() =>
      (Platform.isLinux || Platform.isWindows) &&
      (defaultTargetPlatform == TargetPlatform.linux ||
          defaultTargetPlatform == TargetPlatform.windows);

  /// Crea ambos canales y conecta el toque en el aviso con [onTap].
  ///
  /// En escritorio (Linux/Windows) registra los ajustes propios de cada
  /// plataforma; en cualquier otra plataforma no-Android es un no-op.
  ///
  /// La rama desktop exige ADEMÁS que el target de Flutter sea linux/windows:
  /// el plugin valida los settings contra `defaultTargetPlatform`, y en los
  /// tests de widgets el target es Android aunque el host sea Linux (ahí
  /// debe comportarse como antes: no-op).
  Future<void> init({required void Function(String route) onTap}) async {
    if (_isDesktopTarget()) {
      _onTap = onTap;
      const settings = InitializationSettings(
        linux: LinuxInitializationSettings(defaultActionName: 'Open'),
        windows: WindowsInitializationSettings(
          appName: 'EFE',
          appUserModelId: 'com.efe.efe_mobile',
          guid: 'f86b19c8-435c-4222-b8cd-21112e9f3bbf',
        ),
      );
      await _plugin.initialize(
        settings,
        onDidReceiveNotificationResponse: (response) {
          final payload = response.payload;
          if (payload != null && payload.isNotEmpty) _onTap?.call(payload);
        },
      );
      _initialized = true;
      return;
    }
    if (!Platform.isAndroid) return;
    _onTap = onTap;
    const androidSettings = AndroidInitializationSettings('ic_stat_efe');
    const settings = InitializationSettings(android: androidSettings);
    await _plugin.initialize(
      settings,
      onDidReceiveNotificationResponse: (response) {
        final payload = response.payload;
        if (payload != null && payload.isNotEmpty) _onTap?.call(payload);
      },
    );
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    await android?.createNotificationChannel(
      const AndroidNotificationChannel(
        PushChannels.generalId,
        'General',
        description: 'Avisos generales de EFE',
        importance: Importance.high,
      ),
    );
    await android?.createNotificationChannel(
      const AndroidNotificationChannel(
        PushChannels.messagesId,
        'Mensajes',
        description: 'Mensajes de chat',
        importance: Importance.max,
      ),
    );
    _initialized = true;
  }

  /// Muestra el aviso: canal de mensajes si [isChat], general si no.
  /// El `payload` lleva la ruta para navegar al tocar. No-op antes de [init].
  Future<void> showPush({
    required String? title,
    required String? body,
    required String route,
    required bool isChat,
  }) async {
    if (!_initialized) return;
    if (!Platform.isAndroid) return;
    final channelId = isChat ? PushChannels.messagesId : PushChannels.generalId;
    await _plugin.show(
      DateTime.now().millisecondsSinceEpoch.remainder(1 << 31),
      title,
      body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          channelId,
          isChat ? 'Mensajes' : 'General',
          importance: isChat ? Importance.max : Importance.high,
          icon: 'ic_stat_efe',
        ),
      ),
      payload: route,
    );
  }

  /// Muestra un toast de escritorio (Linux/Windows) con la ruta en el
  /// `payload` para navegar al tocar. No-op antes de [init] o fuera de
  /// escritorio.
  Future<void> showDesktopToast(DesktopToast toast) async {
    if (!_initialized) return;
    if (!Platform.isLinux && !Platform.isWindows) return;
    await _plugin.show(
      _desktopId++,
      toast.title,
      toast.body,
      const NotificationDetails(
        linux: LinuxNotificationDetails(),
        windows: WindowsNotificationDetails(),
      ),
      payload: toast.route,
    );
  }
}
