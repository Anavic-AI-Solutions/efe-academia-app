import 'package:efe_mobile/core/realtime/realtime_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:laravel_reverb/laravel_reverb.dart';
import 'package:laravel_reverb/testing.dart';

void main() {
  const chatChannel = 'presence-public.chat.1';

  late ReverbFake fake;
  late RealtimeService service;

  setUp(() {
    fake = ReverbFake();
    service = RealtimeService(reverb: fake.reverb);
  });

  tearDown(() => fake.dispose());

  test('watchChat delivers an incoming ChatMessageSend payload', () async {
    await service.connect();
    final received = <Map<String, dynamic>>[];
    final subscription = service.watchChat(
      chatId: '1',
      onMessage: received.add,
      onRead: (_) {},
      onTyping: (_) {},
    );
    await pumpEventQueue();

    fake.emit(chatChannel, 'ChatMessageSend', {
      'id': '9',
      'body': 'hola',
      'conversation_id': '1',
    });
    await pumpEventQueue();

    expect(received, hasLength(1));
    expect(received.single['id'], '9');
    expect(received.single['body'], 'hola');
    subscription.cancel();
  });

  test('watchChat delivers MessagesRead payloads', () async {
    await service.connect();
    final received = <Map<String, dynamic>>[];
    final subscription = service.watchChat(
      chatId: '1',
      onMessage: (_) {},
      onRead: received.add,
      onTyping: (_) {},
    );
    await pumpEventQueue();

    fake.emit(chatChannel, 'MessagesRead', {
      'conversation_id': '1',
      'user_id': '7',
      'last_read_message_id': '9',
    });
    await pumpEventQueue();

    expect(received, hasLength(1));
    expect(received.single['last_read_message_id'], '9');
    subscription.cancel();
  });

  test('watchChat delivers typing whispers (client-typing)', () async {
    await service.connect();
    final received = <Map<String, dynamic>>[];
    final subscription = service.watchChat(
      chatId: '1',
      onMessage: (_) {},
      onRead: (_) {},
      onTyping: received.add,
    );
    await pumpEventQueue();

    // Wire name of a whisper: `listenForWhisper('typing')` listens on
    // `client-typing`, the protocol prefix included.
    fake.emit(chatChannel, 'client-typing', {
      'user_id': '7',
      'typing': true,
    });
    await pumpEventQueue();

    expect(received, hasLength(1));
    expect(received.single['user_id'], '7');
    expect(received.single['typing'], isTrue);
    subscription.cancel();
  });

  test('sendTyping whispers client-typing with the sender user id', () async {
    await service.connect();
    final subscription = service.watchChat(
      chatId: '1',
      onMessage: (_) {},
      onRead: (_) {},
      onTyping: (_) {},
    );
    await pumpEventQueue();

    service.sendTyping(chatId: '1', typing: true, userId: '7');
    await pumpEventQueue();

    // wire event name: the protocol's `client-` prefix plus the bare event.
    final whisper = fake.sent.lastWhere(
      (frame) => frame['event'] == 'client-typing',
    );
    expect(whisper['channel'], chatChannel);
    expect(whisper['data'], {'typing': true, 'user_id': '7'});

    subscription.cancel();
  });

  test('watchNotifications entrega el payload de notification.sent', () async {
    await service.connect();
    Map<String, dynamic>? received;
    final subscription = service.watchNotifications(
      userId: '7',
      onNotification: (data) => received = data,
    );
    await pumpEventQueue();

    fake.emit('private-notifications.7', 'notification.sent',
        {'id': '9', 'title': 'Hola', 'message': 'Cuerpo'});
    await pumpEventQueue();

    expect(received, {'id': '9', 'title': 'Hola', 'message': 'Cuerpo'});
    subscription.cancel();
  });

  test('watchChat subscription cancels when disposed', () async {
    await service.connect();
    final received = <Map<String, dynamic>>[];
    final subscription = service.watchChat(
      chatId: '1',
      onMessage: received.add,
      onRead: (_) {},
      onTyping: (_) {},
    );
    await pumpEventQueue();

    subscription.cancel();
    await pumpEventQueue();

    fake.emit(chatChannel, 'ChatMessageSend', {
      'id': '9',
      'body': 'hola',
      'conversation_id': '1',
    });
    await pumpEventQueue();

    expect(received, isEmpty);
  });

  test('addReconnectListener returns a remover', () async {
    await service.connect();
    var calls = 0;
    final remove = service.addReconnectListener(() => calls++);
    expect(remove, isA<VoidCallback>());

    remove();
    await fake.drop();
    // The first reconnect attempt backoff is 1s (+ up to 250ms of jitter);
    // wait past it so a listener that was not actually removed would fire.
    await Future<void>.delayed(const Duration(seconds: 2));

    expect(calls, 0);
  });

  test('addReconnectListener fires after the connection is restored', () async {
    await service.connect();
    var calls = 0;
    service.addReconnectListener(() => calls++);

    // An explicit disconnect + connect counts as a restore, so the package
    // fires its onReconnected callbacks (same path a dropped socket takes).
    await service.disconnect();
    await service.connect();

    expect(calls, 1);
  });

  test('service starts disconnected', () {
    expect(service.isConnected, isFalse);
  });

  test('statesWithCurrent yields current connected when handshake done',
      () async {
    await service.connect();
    expect(service.isConnected, isTrue);

    // El broadcast no hace replay: suscribirse a `states` aquí no emitiría
    // nada, pero `statesWithCurrent` debe entregar el actual primero.
    final first = await service.statesWithCurrent().first;
    expect(first, ReverbState.connected);
  });

  test('statesWithCurrent replays current then live transitions', () async {
    expect(service.isConnected, isFalse);

    // Escucha antes del handshake: el actual (disconnected) llega primero y
    // la transición a connected sigue en vivo. El `pumpEventQueue` deja que
    // el `yield*` se suscriba al broadcast antes de conectar, así ningún
    // evento intermedio se pierde en la rendija.
    final events = <ReverbState>[];
    final subscription = service.statesWithCurrent().listen(events.add);
    await pumpEventQueue();
    await service.connect();
    await pumpEventQueue();
    await subscription.cancel();

    expect(events.first, ReverbState.disconnected);
    expect(events.last, ReverbState.connected);
  });
}
