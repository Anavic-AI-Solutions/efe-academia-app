import '../../../core/api/api_exception.dart';
import '../domain/role_switch_result.dart';
import 'role_mode_api.dart';

class RoleModeRepository {
  final RoleModeApi _api;

  RoleModeRepository(this._api);

  Future<RoleSwitchResult> switchRole(String role) async {
    final response = await _api.switchRole(role);
    final data = response.data is Map<String, dynamic>
        ? (response.data['data'] as Map<String, dynamic>?)
        : null;

    if (data == null) {
      throw ApiException(message: 'Respuesta inválida al cambiar de modo');
    }

    final newRole = data['role']?.toString() ?? '';
    final roles = (data['roles'] as List<dynamic>?)
            ?.map((item) => item.toString())
            .toList() ??
        const <String>[];

    if (newRole.isEmpty) {
      throw ApiException(message: 'Respuesta inválida al cambiar de modo');
    }

    final selectedStudentUserIdRaw = data['selected_student_user_id'];
    final selectedStudentUserId = selectedStudentUserIdRaw is int
        ? selectedStudentUserIdRaw
        : int.tryParse(selectedStudentUserIdRaw?.toString() ?? '');

    return RoleSwitchResult(
      role: newRole,
      roles: roles,
      selectedStudentId: data['selected_student_id']?.toString(),
      selectedStudentUserId: selectedStudentUserId,
    );
  }
}
