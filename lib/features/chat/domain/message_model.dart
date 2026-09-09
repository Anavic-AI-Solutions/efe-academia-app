import 'package:freezed_annotation/freezed_annotation.dart';

part 'message_model.freezed.dart';

@freezed
class MessageModel with _$MessageModel {
  const factory MessageModel({
    required String id,
    required String body,
    required String senderId,
    @Default('') String senderName,
    @Default(false) bool isMe,
    required DateTime createdAt,
  }) = _MessageModel;

  factory MessageModel.fromJson(Map<String, dynamic> json) {
    final attrs = json['data']?['attributes'] as Map<String, dynamic>? ?? json;
    return MessageModel(
      id: json['data']?['id']?.toString() ?? attrs['id']?.toString() ?? '',
      body: attrs['body'] ?? '',
      senderId: attrs['sender_id']?.toString() ?? '',
      senderName: attrs['sender_name'] ?? '',
      isMe: attrs['is_me'] ?? false,
      createdAt: DateTime.tryParse(attrs['created_at'] ?? '') ?? DateTime.now(),
    );
  }
}
