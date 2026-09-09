import '../domain/chat_model.dart';
import '../domain/message_model.dart';
import 'chat_api.dart';

class ChatRepository {
  final ChatApi _api;
  ChatRepository(this._api);

  Future<List<ChatModel>> getChats({String? cursor}) async {
    final response = await _api.getChats(cursor: cursor);
    final data = response.data;
    final items = data is Map<String, dynamic>
        ? (data['data'] as List<dynamic>? ?? [])
        : data as List<dynamic>? ?? [];
    return items
        .map((e) => ChatModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<MessageModel>> getMessages(String chatId, {String? cursor}) async {
    final response = await _api.getMessages(chatId, cursor: cursor);
    final data = response.data;
    final items = data is Map<String, dynamic>
        ? (data['data'] as List<dynamic>? ?? [])
        : data as List<dynamic>? ?? [];
    return items
        .map((e) => MessageModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<MessageModel> sendMessage(String chatId, String body) async {
    final response = await _api.sendMessage(chatId, body);
    final data = response.data;
    return MessageModel.fromJson(data as Map<String, dynamic>);
  }
}
