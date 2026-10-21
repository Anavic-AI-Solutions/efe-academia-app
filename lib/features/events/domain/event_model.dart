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
    final attrs = json['attributes'] as Map<String, dynamic>? ??
        json['data']?['attributes'] as Map<String, dynamic>? ??
        json;
    final startRaw = attrs['start_date'] ?? attrs['start'];
    final endRaw = attrs['end_date'] ?? attrs['end'];
    return EventModel(
      id: json['data']?['id']?.toString() ??
          json['id']?.toString() ??
          attrs['id']?.toString() ??
          '',
      title: attrs['title']?.toString() ?? '',
      description: attrs['description']?.toString() ?? '',
      start: startRaw is String ? DateTime.tryParse(startRaw) : null,
      end: endRaw is String ? DateTime.tryParse(endRaw) : null,
      color: _parseColor(attrs['color']),
    );
  }

  static int _parseColor(dynamic value) {
    if (value is int) return value;
    if (value is String) {
      return int.tryParse(value.replaceFirst('#', '0xFF'), radix: 16) ??
          0xFF3B82F6;
    }
    return 0xFF3B82F6;
  }
}
