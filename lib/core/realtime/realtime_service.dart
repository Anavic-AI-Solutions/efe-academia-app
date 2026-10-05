import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:laravel_reverb/laravel_reverb.dart';

/// Envoltorio de `laravel_reverb` para la app.
///
/// Expone canales de chat y notificaciones ya resueltos a los wire names del
/// backend y centraliza los listeners de resync: viven en un [Set] propio y se
/// despachan desde un único `reverb.onReconnected` registrado en [connect].
class RealtimeService {
  RealtimeService({required Reverb reverb}) : _reverb = reverb;

  final Reverb _reverb;
  final Set<VoidCallback> _reconnectListeners = <VoidCallback>{};
  bool _reconnectRegistered = false;

  /// `true` solo con el handshake completo y el socket vivo.
  bool get isConnected => _reverb.state == ReverbState.connected;

  /// Cambios del ciclo de vida de la conexión del cliente.
  Stream<ReverbState> get states => _reverb.states;

  /// Abre el socket y registra el despachador único de resync.
  ///
  /// El registro se repite tras un [disconnect] con `forget: true`, porque el
  /// paquete descarta los callbacks de `onReconnected` en ese camino.
  Future<void> connect() async {
    if (!_reconnectRegistered) {
      _reverb.onReconnected(_dispatchReconnect);
      _reconnectRegistered = true;
    }
    await _reverb.connect();
  }

  /// Cierra el socket. Con `forget: true` (logout) además se descartan los
  /// canales, los listeners de resync y todo handle previo.
  Future<void> disconnect({bool forget = false}) async {
    if (forget) {
      _reconnectListeners.clear();
      _reconnectRegistered = false;
    }
    await _reverb.disconnect(forget: forget);
  }

  /// Suscribe `presence-public.chat.{chatId}` y devuelve el handle a cancelar.
  ///
  /// Wire names del backend (nombres literales de `broadcastAs()`, por eso el
  /// punto inicial): `.ChatMessageSend` y `.MessagesRead`. El whisper viaja
  /// como `client-typing`: `listenForWhisper` antepone el prefijo `client-`
  /// del protocolo, así que se registra con el nombre sin prefijo.
  Subscription watchChat({
    required String chatId,
    required void Function(Map<String, dynamic> data) onMessage,
    required void Function(Map<String, dynamic> data) onRead,
    required void Function(Map<String, dynamic> data) onTyping,
  }) {
    return _reverb
        .presence('public.chat.$chatId')
        .listen('.ChatMessageSend', onMessage)
        .listen('.MessagesRead', onRead)
        .listenForWhisper('typing', onTyping);
  }

  /// Suscribe `private-notifications.{userId}` y escucha `.notification.sent`.
  Subscription watchNotifications({
    required String userId,
    required void Function() onNotification,
  }) {
    return _reverb
        .private('notifications.$userId')
        .listen('.notification.sent', (_) => onNotification());
  }

  /// Registra un listener de resync; devuelve la función que lo remueve.
  VoidCallback addReconnectListener(void Function() listener) {
    _reconnectListeners.add(listener);
    return () => _reconnectListeners.remove(listener);
  }

  void _dispatchReconnect() {
    for (final listener in List<VoidCallback>.of(_reconnectListeners)) {
      listener();
    }
  }
}
