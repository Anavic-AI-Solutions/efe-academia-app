import 'package:freezed_annotation/freezed_annotation.dart';

part 'user_model.freezed.dart';

@freezed
class UserModel with _$UserModel {
  const factory UserModel({
    required String id,
    required String name,
    required String email,
    @Default('') String role,
    @Default([]) List<String> roles,
    String? avatarUrl,
    String? branchName,
  }) = _UserModel;

  factory UserModel.fromJson(Map<String, dynamic> json) {
    final attrs = json['data']?['attributes'] as Map<String, dynamic>? ?? json;
    return UserModel(
      id: json['data']?['id']?.toString() ?? attrs['id']?.toString() ?? '',
      name: attrs['name'] ?? '',
      email: attrs['email'] ?? '',
      role: attrs['role'] ?? '',
      roles: (attrs['roles'] as List<dynamic>?)?.cast<String>() ?? [],
      avatarUrl: attrs['avatar_url'],
      branchName: attrs['branch_name'],
    );
  }
}
