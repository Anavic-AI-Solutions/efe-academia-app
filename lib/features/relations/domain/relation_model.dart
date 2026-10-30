import 'package:freezed_annotation/freezed_annotation.dart';

part 'relation_model.freezed.dart';

@freezed
class RelationModel with _$RelationModel {
  const factory RelationModel({
    required String id,
    required String fullname,
    required String role,
    required int userId,
  }) = _RelationModel;

  factory RelationModel.fromJson(Map<String, dynamic> json) {
    final attrs = json['attributes'] as Map<String, dynamic>? ??
        json['data']?['attributes'] as Map<String, dynamic>? ??
        json;
    return RelationModel(
      id: json['data']?['id']?.toString() ??
          json['id']?.toString() ??
          attrs['id']?.toString() ??
          '',
      fullname: attrs['fullname']?.toString() ?? '',
      role: attrs['role']?.toString() ?? '',
      userId: _parseInt(attrs['user_id']),
    );
  }
}

int _parseInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? 0;
}
