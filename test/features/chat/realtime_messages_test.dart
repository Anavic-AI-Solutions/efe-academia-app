import 'dart:async';

import 'package:efe_mobile/core/api/cursor_pagination.dart';
import 'package:efe_mobile/features/chat/data/chat_repository.dart';
import 'package:efe_mobile/features/chat/domain/chat_model.dart';
import 'package:efe_mobile/features/chat/domain/message_model.dart';
import 'package:efe_mobile/features/chat/providers/chat_provider.dart';
import 'package:flutter_test/flutter_test.dart';

// ---------------------------------------------------------------------------
// Fakes
// ---------------------------------------------------------------------------

/// Repository driven by callbacks so every test shapes its own responses.
class _FakeChatRepository implements ChatRepository {
  Future<CursorPagination<MessageModel>> Function(
      String chatId, String? cursor)? onGetMessages;
  Future<MessageModel> Function(String chatId, String body)? onSendMessage;

  final List<String?> messageCursors = <String?>[];
  int getMessagesCalls = 0;
  int sendCalls = 0;

  @override
  Future<CursorPagination<ChatModel>> getChats({String? cursor}) =>
      Future.error(UnimplementedError());

  @override
  Future<CursorPagination<MessageModel>> getMessages(
    String chatId, {
    String? cursor,
  }) {
    getMessagesCalls++;
    messageCursors.add(cursor);
    final handler = onGetMessages;
    if (handler == null) return Future.value(_page(const []));
    return handler(chatId, cursor);
  }

  @override
  Future<MessageModel> sendMessage(String chatId, String body) {
    sendCalls++;
    final handler = onSendMessage;
    if (handler == null) return Future.error(UnimplementedError());
    return handler(chatId, body);
  }
}

CursorPagination<MessageModel> _page(List<MessageModel> data) =>
    CursorPagination<MessageModel>(data: data, hasMore: false);

MessageModel _message(
  String id, {
  String body = 'hola',
  String senderId = '2',
  DateTime? createdAt,
}) =>
    MessageModel(
      id: id,
      body: body,
      senderId: senderId,
      senderName: 'Ada',
      createdAt: createdAt ?? DateTime(2026, 10, 5, 12),
    );

Map<String, dynamic> _incoming(String id, {String body = 'nuevo'}) => {
      'id': id,
      'body': body,
      'sender_id': '2',
      'sender_name': 'Ada',
      'created_at': '2026-10-05T12:00:00Z',
    };

Future<MessagesNotifier> _notifier(
  _FakeChatRepository repository, {
  Duration typingTimeout = const Duration(seconds: 3),
}) async {
  final notifier =
      MessagesNotifier(repository, 'c1', typingTimeout: typingTimeout);
  await pumpEventQueue();
  return notifier;
}

void main() {
  test('appendIncoming adds a new message', () async {
    final repository = _FakeChatRepository();
    final notifier = await _notifier(repository);

    await notifier.appendIncoming(_incoming('5'));

    expect(notifier.state.messages.map((m) => m.id), ['5']);
    expect(notifier.state.messages.single.body, 'nuevo');
  });

  test('incoming message with an id that already exists is ignored', () async {
    final repository = _FakeChatRepository();
    final notifier = await _notifier(repository);

    await notifier.appendIncoming(_incoming('5', body: 'primero'));
    await notifier.appendIncoming(_incoming('5', body: 'duplicado'));

    expect(notifier.state.messages, hasLength(1));
    expect(notifier.state.messages.single.body, 'primero');
  });

  test('incoming messages are sorted by id ascending', () async {
    final repository = _FakeChatRepository();
    final notifier = await _notifier(repository);

    await notifier.appendIncoming(_incoming('9'));
    await notifier.appendIncoming(_incoming('3'));

    expect(notifier.state.messages.map((m) => m.id), ['3', '9']);
  });

  test(
      'backfill merges missing messages keeping ascending order without duplicates',
      () async {
    final repository = _FakeChatRepository()
      ..onGetMessages = (chatId, cursor) async {
        if (cursor == null) {
          return _page([_message('1'), _message('2')]);
        }
        // The server may repeat the cursor message: dedupe must absorb it.
        return _page([_message('2'), _message('3'), _message('4')]);
      };
    final notifier = await _notifier(repository);
    expect(notifier.state.messages.map((m) => m.id), ['1', '2']);

    await notifier.backfill();

    expect(repository.messageCursors, [null, '2']);
    expect(notifier.state.messages.map((m) => m.id), ['1', '2', '3', '4']);
  });

  test('backfill loads the first page when the conversation is empty',
      () async {
    var firstLoad = true;
    final repository = _FakeChatRepository()
      ..onGetMessages = (chatId, cursor) async {
        if (firstLoad) {
          firstLoad = false;
          return _page(const []);
        }
        return _page([_message('1')]);
      };
    final notifier = await _notifier(repository);
    expect(notifier.state.messages, isEmpty);

    await notifier.backfill();

    expect(repository.messageCursors, [null, null]);
    expect(notifier.state.messages.map((m) => m.id), ['1']);
  });

  test('applyReadReceipt marks own messages up to lastReadMessageId as read',
      () async {
    final repository = _FakeChatRepository();
    final notifier = await _notifier(repository);
    await notifier.appendIncoming(_incoming('1'));
    await notifier.appendIncoming(_incoming('2'));
    await notifier.appendIncoming(_incoming('3'));

    notifier.applyReadReceipt({'last_read_message_id': '2'});

    expect(notifier.state.lastReadMessageId, 2);
    expect(notifier.state.isRead('1'), isTrue);
    expect(notifier.state.isRead('2'), isTrue);
    expect(notifier.state.isRead('3'), isFalse);

    // An older receipt must not move the marker backwards.
    notifier.applyReadReceipt({'last_read_message_id': '1'});
    expect(notifier.state.lastReadMessageId, 2);
  });

  test('typing event is cleared after the timeout', () async {
    final repository = _FakeChatRepository();
    final notifier = await _notifier(
      repository,
      typingTimeout: const Duration(milliseconds: 30),
    );

    notifier.setTyping({'user_id': '2', 'typing': true});
    expect(notifier.state.typingUserId, '2');

    await Future<void>.delayed(const Duration(milliseconds: 60));
    expect(notifier.state.typingUserId, isNull);

    notifier.setTyping({'user_id': '2', 'typing': true});
    notifier.setTyping({'user_id': '2', 'typing': false});
    expect(notifier.state.typingUserId, isNull);
  });

  test('dispose cancels the typing timeout timer', () async {
    final repository = _FakeChatRepository();
    final notifier = await _notifier(
      repository,
      typingTimeout: const Duration(milliseconds: 30),
    );
    notifier.setTyping({'user_id': '2', 'typing': true});
    expect(notifier.state.typingUserId, '2');

    notifier.dispose();

    // Without the cancel in dispose, the timer would fire _clearTyping on a
    // disposed notifier and the uncaught StateError would fail this test.
    await Future<void>.delayed(const Duration(milliseconds: 60));
  });

  test('setTyping shows the realistic payload and ignores another user stop',
      () async {
    final repository = _FakeChatRepository();
    final notifier = await _notifier(repository);

    notifier.setTyping({'user_id': '2', 'typing': true});
    expect(notifier.state.typingUserId, '2');

    // A `typing: false` for a different user must not clear the indicator.
    notifier.setTyping({'user_id': '9', 'typing': false});
    expect(notifier.state.typingUserId, '2');

    notifier.setTyping({'user_id': '2', 'typing': false});
    expect(notifier.state.typingUserId, isNull);
  });

  test('appendIncoming reads the flat user_id/user_name broadcast payload',
      () async {
    final repository = _FakeChatRepository();
    final notifier = await _notifier(repository);

    await notifier.appendIncoming({
      'id': 9,
      'conversation_id': 1,
      'body': 'hola',
      'created_at': '2026-10-05T12:00:00Z',
      'user_id': 53,
      'user_name': 'Test Admin 3',
    });

    final message = notifier.state.messages.single;
    expect(message.senderId, '53');
    expect(message.senderName, 'Test Admin 3');
  });

  test('send publishes a sending bubble and settles it as sent', () async {
    final repository = _FakeChatRepository();
    final completer = Completer<MessageModel>();
    repository.onSendMessage = (chatId, body) => completer.future;
    final notifier = await _notifier(repository);

    final pending = notifier.send('hola');

    final optimistic = notifier.state.messages.single;
    expect(optimistic.body, 'hola');
    expect(notifier.state.statusOf(optimistic.id), MessageStatus.sending);
    expect(notifier.state.isOwn(optimistic.id), isTrue);

    completer.complete(_message('42', body: 'hola', senderId: '7'));
    await pending;

    expect(notifier.state.messages.single.id, '42');
    expect(notifier.state.statusOf('42'), MessageStatus.sent);
    expect(notifier.state.isOwn('42'), isTrue);
  });

  test('a server echo arriving first replaces the optimistic bubble', () async {
    final repository = _FakeChatRepository();
    final completer = Completer<MessageModel>();
    repository.onSendMessage = (chatId, body) => completer.future;
    final notifier = await _notifier(repository);

    final pending = notifier.send('hola');
    final tempId = notifier.state.messages.single.id;
    await notifier.appendIncoming(_incoming('42', body: 'hola'));
    // The echo and the in-flight optimistic bubble coexist for now.
    expect(notifier.state.messages.map((m) => m.id), ['42', tempId]);

    completer.complete(_message('42', body: 'hola', senderId: '7'));
    await pending;

    // The temp bubble is dropped, never duplicated alongside the echo.
    expect(notifier.state.messages.map((m) => m.id), ['42']);
    expect(notifier.state.isOwn(tempId), isFalse);
    expect(notifier.state.isOwn('42'), isTrue);
  });

  test('send failure marks the message as failed and retrySend re-sends it',
      () async {
    var fail = true;
    final repository = _FakeChatRepository();
    repository.onSendMessage = (chatId, body) async {
      if (fail) {
        fail = false;
        throw Exception('sin conexión');
      }
      return _message('42', body: body, senderId: '7');
    };
    final notifier = await _notifier(repository);

    await notifier.send('hola');

    expect(notifier.state.messages, hasLength(1));
    final failed = notifier.state.messages.single;
    expect(failed.body, 'hola');
    expect(notifier.state.statusOf(failed.id), MessageStatus.failed);
    expect(notifier.state.isOwn(failed.id), isTrue);

    await notifier.retrySend(failed.id);

    expect(repository.sendCalls, 2);
    expect(notifier.state.messages.single.id, '42');
    expect(notifier.state.statusOf('42'), MessageStatus.sent);
    expect(notifier.state.isOwn('42'), isTrue);
  });
}
