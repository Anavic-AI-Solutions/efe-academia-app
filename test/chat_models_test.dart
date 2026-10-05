import 'package:flutter_test/flutter_test.dart';

import 'package:efe_mobile/features/chat/domain/chat_model.dart';
import 'package:efe_mobile/features/chat/domain/message_model.dart';

void main() {
  group('ChatModel.fromJson', () {
    test('parses the ChatResource payload', () {
      final json = {
        'type': 'chat',
        'id': '1',
        'attributes': {
          'type': 'private',
          'name': 'Carolina Pelaez',
          'classroom_id': null,
          'updated_at': '2026-09-15T21:05:17.000000Z',
          'last_message': {
            'body': 'Hola, prueba de reparacion',
            'created_at': '2026-09-15T21:05:17.000000Z',
            'sender_id': 53,
          },
          'unread_count': 0,
          'participant_count': 2,
        },
        'relationships': {
          'participants': {'data': []},
        },
      };

      final chat = ChatModel.fromJson(json);

      expect(chat.id, '1');
      expect(chat.name, 'Carolina Pelaez');
      expect(chat.lastMessage, 'Hola, prueba de reparacion');
      expect(chat.unreadCount, 0);
      expect(chat.lastMessageAt, DateTime.parse('2026-09-15T21:05:17.000000Z'));
    });

    test('tolerates a null last_message', () {
      final json = {
        'type': 'chat',
        'id': '7',
        'attributes': {
          'name': 'Empty chat',
          'updated_at': '2026-09-15T21:05:17.000000Z',
          'last_message': null,
          'unread_count': 3,
        },
      };

      final chat = ChatModel.fromJson(json);

      expect(chat.id, '7');
      expect(chat.lastMessage, '');
      expect(chat.unreadCount, 3);
      expect(chat.lastMessageAt, DateTime.parse('2026-09-15T21:05:17.000000Z'));
    });
  });

  group('MessageModel.fromJson', () {
    test('parses the MessageResource payload with sender object', () {
      final json = {
        'type': 'message',
        'id': '4',
        'attributes': {
          'body': 'Prueba envio mobile',
          'type': 'text',
          'data': [],
          'created_at': '2026-09-15T21:13:11.000000Z',
          'sender': {
            'id': 53,
            'name': 'Test Admin 3',
            'fullname': 'Test Admin 3',
          },
        },
        'relationships': [],
      };

      final message = MessageModel.fromJson(json);

      expect(message.id, '4');
      expect(message.body, 'Prueba envio mobile');
      expect(message.senderId, '53');
      expect(message.senderName, 'Test Admin 3');
      expect(message.createdAt, DateTime.parse('2026-09-15T21:13:11.000000Z'));
    });

    test('parses the flat broadcast payload with user_id and user_name', () {
      final message = MessageModel.fromJson({
        'id': 9,
        'conversation_id': 1,
        'body': 'hola',
        'created_at': '2026-10-05T12:00:00+00:00',
        'user_id': 53,
        'user_name': 'Test Admin 3',
      });

      expect(message.id, '9');
      expect(message.senderId, '53');
      expect(message.senderName, 'Test Admin 3');
    });
  });
}
