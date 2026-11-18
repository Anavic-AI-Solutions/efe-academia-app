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
  bool get isProfessor => role == 'professor';

  bool get isAdmin => role == 'admin';

  bool get isBranch => role == 'branch';

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

  bool get canManageMaterials {
    const allowed = {'professor', 'admin', 'branch'};
    return allowed.contains(role);
  }
}
