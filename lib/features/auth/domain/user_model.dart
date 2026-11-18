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
    // Handle API wrapper: {success, data: {...}} → extract data
    final data = json['data'] as Map<String, dynamic>? ?? json;
    // Handle JSON:API: {type, id, attributes} → extract attributes
    final attrs = data['attributes'] as Map<String, dynamic>? ?? data;
    return UserModel(
      id: data['id']?.toString() ?? attrs['id']?.toString() ?? '',
      name: attrs['name'] ?? '',
      email: attrs['email'] ?? '',
      role: attrs['role'] ?? '',
      roles: (attrs['roles'] as List<dynamic>?)?.cast<String>() ?? [],
      avatarUrl: (attrs['avatar_url'] ?? attrs['avatar'])?.toString(),
      branchName: attrs['branch_name'],
    );
  }
}

extension UserModelRoleX on UserModel {
  /// The mobile API exposes the branch role as "branch"; the web name "sede"
  /// is accepted as a fallback so both spellings behave the same.
  String get _normalizedRole {
    final value = role.trim().toLowerCase();
    return value == 'sede' ? 'branch' : value;
  }

  bool get isProfessor => _normalizedRole == 'professor';

  bool get isAdmin => _normalizedRole == 'admin';

  bool get isBranch => _normalizedRole == 'branch';

  bool get isStaff => isAdmin || isBranch;

  bool get canManageStudents => isStaff;

  bool get canManageProfessors => isAdmin;

  bool get canManageParents => isStaff;

  bool get canManageClassrooms => isStaff;

  bool get canManageNews => isStaff;

  bool get canManageEvents => isStaff || isProfessor;

  bool get canManageDocuments => isStaff;

  bool get canManageFaqs => isAdmin;

  bool get canManageQualifications => isStaff || isProfessor;

  bool get canDeleteQualifications => isStaff;

  bool get canManageMaterials => isStaff || isProfessor;
}
