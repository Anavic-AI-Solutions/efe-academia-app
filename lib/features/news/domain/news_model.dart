import 'package:freezed_annotation/freezed_annotation.dart';

part 'news_model.freezed.dart';

@freezed
class NewsModel with _$NewsModel {
  const factory NewsModel({
    required String id,
    required String title,
    required String content,
    DateTime? eventDate,
    DateTime? createdAt,
  }) = _NewsModel;

  factory NewsModel.fromJson(Map<String, dynamic> json) {
    final attrs = json['attributes'] as Map<String, dynamic>? ??
        json['data']?['attributes'] as Map<String, dynamic>? ??
        json;
    return NewsModel(
      id: json['data']?['id']?.toString() ??
          json['id']?.toString() ??
          attrs['id']?.toString() ??
          '',
      title: attrs['title'] ?? '',
      content: attrs['content'] ?? '',
      eventDate: attrs['event_date'] != null
          ? DateTime.tryParse(attrs['event_date'])
          : null,
      createdAt: attrs['created_at'] != null
          ? DateTime.tryParse(attrs['created_at'])
          : null,
    );
  }
}
