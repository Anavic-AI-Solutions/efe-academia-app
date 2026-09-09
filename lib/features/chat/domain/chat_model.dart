import 'package:freezed_annotation/freezed_annotation.dart';

part 'chat_model.freezed.dart';

@freezed
class ChatModel with _$ChatModel {
  const factory ChatModel({
    required String id,
    @Default('') String name,
    @Default('') String lastMessage,
    @Default(0) int unreadCount,
    DateTime? lastMessageAt,
  }) = _ChatModel;

  factory ChatModel.fromJson(Map<String, dynamic> json) {
    final attrs = json['data']?['attributes'] as Map<String, dynamic>? ?? json;
    return ChatModel(
      id: json['data']?['id']?.toString() ?? attrs['id']?.toString() ?? '',
      name: attrs['name'] ?? '',
      lastMessage: attrs['last_message'] ?? '',
      unreadCount: attrs['unread_count'] ?? 0,
      lastMessageAt: attrs['last_message_at'] != null
          ? DateTime.tryParse(attrs['last_message_at'])
          : null,
    );
  }
}
