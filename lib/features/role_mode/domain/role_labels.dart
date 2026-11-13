import '../../../l10n/app_localizations.dart';

String roleLabel(AppLocalizations l10n, String role) {
  switch (role) {
    case 'admin':
      return l10n.roleAdmin;
    case 'branch':
      return l10n.roleBranch;
    case 'professor':
      return l10n.roleProfessor;
    case 'parent':
      return l10n.roleParent;
    case 'student':
      return l10n.roleStudent;
    default:
      return role.isNotEmpty ? role : l10n.commonUser;
  }
}

String roleModeDescription(AppLocalizations l10n, String role) {
  switch (role) {
    case 'professor':
      return l10n.roleModeDescriptionProfessor;
    case 'parent':
      return l10n.roleModeDescriptionParent;
    case 'student':
      return l10n.roleModeDescriptionStudent;
    case 'admin':
      return l10n.roleModeDescriptionAdmin;
    case 'branch':
      return l10n.roleModeDescriptionBranch;
    default:
      return '';
  }
}
