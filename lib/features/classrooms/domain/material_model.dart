import 'package:freezed_annotation/freezed_annotation.dart';

part 'material_model.freezed.dart';

@freezed
class MaterialModel with _$MaterialModel {
  const factory MaterialModel({
    required String id,
    @Default('') String name,
    @Default('') String description,
    @Default('') String type,
    @Default('') String publicUrl,
    @Default('') String category,
    @Default('') String visibility,
    @Default('') String availableUntil,
    @Default(0) int downloadCount,
    @Default('') String createdAt,
  }) = _MaterialModel;

  factory MaterialModel.fromJson(Map<String, dynamic> json) {
    final attrs = json['attributes'] as Map<String, dynamic>? ??
        json['data']?['attributes'] as Map<String, dynamic>? ??
        json;
    return MaterialModel(
      id: json['data']?['id']?.toString() ??
          json['id']?.toString() ??
          attrs['id']?.toString() ??
          '',
      name: attrs['name'] ?? '',
      description: attrs['description'] ?? '',
      type: attrs['type'] ?? '',
      publicUrl: attrs['public_url'] ?? '',
      category: attrs['category'] ?? '',
      visibility: attrs['visibility'] ?? '',
      availableUntil: attrs['available_until'] ?? '',
      downloadCount: _parseInt(attrs['download_count']),
      createdAt: attrs['created_at'] ?? '',
    );
  }

  static int _parseInt(dynamic value) {
    if (value is int) return value;
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }
}
