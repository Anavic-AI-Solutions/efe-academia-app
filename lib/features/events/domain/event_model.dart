import 'package:freezed_annotation/freezed_annotation.dart';

part 'event_model.freezed.dart';

@freezed
class EventModel with _$EventModel {
  const factory EventModel({
    required String id,
    required String title,
    @Default('') String description,
    DateTime? start,
    DateTime? end,
    @Default(0xFF3B82F6) int color,
  }) = _EventModel;

  factory EventModel.fromJson(Map<String, dynamic> json) {
    final attrs = json['data']?['attributes'] as Map<String, dynamic>? ?? json;
    return EventModel(
      id: json['data']?['id']?.toString() ?? attrs['id']?.toString() ?? '',
      title: attrs['title'] ?? '',
      description: attrs['description'] ?? '',
      start: attrs['start'] != null ? DateTime.tryParse(attrs['start']) : null,
      end: attrs['end'] != null ? DateTime.tryParse(attrs['end']) : null,
      color: _parseColor(attrs['color']),
    );
  }

  static int _parseColor(dynamic value) {
    if (value is int) return value;
    if (value is String) {
      return int.tryParse(value.replaceFirst('#', '0xFF'), radix: 16) ?? 0xFF3B82F6;
    }
    return 0xFF3B82F6;
  }
}
