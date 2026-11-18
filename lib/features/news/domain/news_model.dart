import 'package:freezed_annotation/freezed_annotation.dart';

part 'news_model.freezed.dart';

@freezed
class NewsModel with _$NewsModel {
  const factory NewsModel({
    required String id,
    required String title,
    @Default('') String description,
    required String content,
    DateTime? eventDate,
    @Default([]) List<String> mediaUrls,
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
      description: attrs['description'] ?? '',
      content: attrs['content'] ?? '',
      eventDate: attrs['event_date'] != null
          ? DateTime.tryParse(attrs['event_date'])
          : null,
      mediaUrls: _parseMediaUrls(attrs),
      createdAt: attrs['created_at'] != null
          ? DateTime.tryParse(attrs['created_at'])
          : null,
    );
  }
}

/// La API devuelve la colección `media` de Spatie; los registros viejos solo
/// traen `image`/`public_url`.
List<String> _parseMediaUrls(Map<String, dynamic> attrs) {
  final media = attrs['media'];
  final urls = <String>[];
  if (media is List) {
    for (final item in media) {
      if (item is Map) {
        final url = item['url']?.toString();
        if (url != null && url.isNotEmpty) urls.add(url);
      }
    }
  }
  if (urls.isEmpty) {
    for (final key in const ['image', 'public_url']) {
      final url = attrs[key]?.toString();
      if (url != null && url.isNotEmpty) {
        urls.add(url);
        break;
      }
    }
  }
  return urls;
}
