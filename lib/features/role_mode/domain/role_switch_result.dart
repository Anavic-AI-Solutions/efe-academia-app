class RoleSwitchResult {
  final String role;
  final List<String> roles;
  final String? selectedStudentId;

  const RoleSwitchResult({
    required this.role,
    required this.roles,
    this.selectedStudentId,
  });
}
