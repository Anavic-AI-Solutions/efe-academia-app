import 'package:freezed_annotation/freezed_annotation.dart';

part 'notification_model.freezed.dart';

@freezed
class NotificationModel with _$NotificationModel {
  const factory NotificationModel({
    required String id,
    required String title,
    required String body,
    @Default(false) bool read,
    @Default('') String type,
    @Default('') String typeId,
    required DateTime createdAt,
  }) = _NotificationModel;

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    final attrs = json['attributes'] as Map<String, dynamic>? ?? json['data']?['attributes'] as Map<String, dynamic>? ?? json;
    return NotificationModel(
      id: json['data']?['id']?.toString() ?? json['id']?.toString() ?? attrs['id']?.toString() ?? '',
      title: attrs['title'] ?? '',
      body: attrs['body'] ?? '',
      read: attrs['read'] ?? false,
      type: attrs['type'] ?? '',
      typeId: attrs['type_id']?.toString() ?? '',
      createdAt: DateTime.tryParse(attrs['created_at'] ?? '') ?? DateTime.now(),
    );
  }
}
