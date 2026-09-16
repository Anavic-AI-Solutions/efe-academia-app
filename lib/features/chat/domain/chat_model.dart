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
    final attrs = json['attributes'] as Map<String, dynamic>? ?? json['data']?['attributes'] as Map<String, dynamic>? ?? json;
    final lastMessage = attrs['last_message'];
    return ChatModel(
      id: json['data']?['id']?.toString() ?? json['id']?.toString() ?? attrs['id']?.toString() ?? '',
      name: attrs['name'] ?? '',
      lastMessage: lastMessage is Map<String, dynamic>
          ? (lastMessage['body']?.toString() ?? '')
          : (lastMessage?.toString() ?? ''),
      unreadCount: attrs['unread_count'] ?? 0,
      lastMessageAt: _parseDate(
            lastMessage is Map<String, dynamic> ? lastMessage['created_at'] : null,
          ) ??
          _parseDate(attrs['updated_at']),
    );
  }
}

DateTime? _parseDate(dynamic value) =>
    value is String ? DateTime.tryParse(value) : null;
