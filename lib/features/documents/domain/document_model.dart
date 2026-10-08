import 'package:freezed_annotation/freezed_annotation.dart';

part 'document_model.freezed.dart';

@freezed
class DocumentModel with _$DocumentModel {
  const factory DocumentModel({
    required String id,
    required String title,
    @Default('') String description,
    @Default('') String fileUrl,
    DateTime? createdAt,
    @Default([]) List<String> mediaUrls,
  }) = _DocumentModel;

  factory DocumentModel.fromJson(Map<String, dynamic> json) {
    final attrs = json['attributes'] as Map<String, dynamic>? ??
        json['data']?['attributes'] as Map<String, dynamic>? ??
        json;
    return DocumentModel(
      id: json['data']?['id']?.toString() ??
          json['id']?.toString() ??
          attrs['id']?.toString() ??
          '',
      title: attrs['title'] ?? '',
      description: attrs['description'] ?? '',
      fileUrl: attrs['file_url'] ?? attrs['fileUrl'] ?? '',
      createdAt: attrs['created_at'] != null
          ? DateTime.tryParse(attrs['created_at'])
          : null,
      mediaUrls: _parseMediaUrls(attrs['media']),
    );
  }

  static List<String> _parseMediaUrls(dynamic value) {
    if (value is! List) return [];
    return value
        .whereType<Map<String, dynamic>>()
        .map((e) => e['url']?.toString())
        .whereType<String>()
        .where((url) => url.isNotEmpty)
        .toList();
  }
}
