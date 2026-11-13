import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/app_colors.dart';
import '../../../l10n/l10n.dart';
import '../../auth/providers/auth_provider.dart';
import '../domain/role_labels.dart';
import '../providers/role_switch_provider.dart';

Future<void> openModeSwitcher(BuildContext context, WidgetRef ref) async {
  final switched = await showModeSwitchSheet(context);
  if (switched != true || !context.mounted) return;

  final l10n = context.l10n;
  final role = ref.read(authProvider).user?.role ?? '';
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(l10n.roleModeSwitched(roleLabel(l10n, role)))),
  );
  context.go('/dashboard');
}

Future<bool?> showModeSwitchSheet(BuildContext context) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => const ModeSwitchSheet(),
  );
}

class ModeSwitchSheet extends ConsumerWidget {
  const ModeSwitchSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).user;
    final state = ref.watch(roleSwitchControllerProvider);
    final l10n = context.l10n;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final roles = user?.roles ?? const <String>[];
    final textColor =
        isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color:
                          isDark ? AppColors.darkBorder : AppColors.lightBorder,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  l10n.roleModeTitle,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  l10n.roleModeSubtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.mutedFor(isDark),
                  ),
                ),
                if (state.isSwitching) ...[
                  const SizedBox(height: 14),
                  const LinearProgressIndicator(minHeight: 2),
                  const SizedBox(height: 4),
                  Text(
                    l10n.roleModeLoading,
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.mutedFor(isDark),
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                for (final role in roles)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: _RoleRow(
                      role: role,
                      selected: role == user?.role,
                      disabled: state.isSwitching,
                      onTap: () async {
                        final ok = await ref
                            .read(roleSwitchControllerProvider.notifier)
                            .switchTo(role);
                        if (!context.mounted) return;
                        if (ok) Navigator.of(context).pop(true);
                      },
                    ),
                  ),
                if (state.status == RoleSwitchStatus.error) ...[
                  const SizedBox(height: 4),
                  Text(
                    state.error ?? l10n.roleModeSwitchError,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.error,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RoleRow extends StatelessWidget {
  final String role;
  final bool selected;
  final bool disabled;
  final VoidCallback onTap;

  const _RoleRow({
    required this.role,
    required this.selected,
    required this.disabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = _roleColor(role);
    final textColor =
        isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final description = roleModeDescription(l10n, role);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: disabled || selected ? null : onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: selected
                ? color.withValues(alpha: 0.08)
                : (isDark ? AppColors.darkSurface : AppColors.lightSurface),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected
                  ? color.withValues(alpha: 0.4)
                  : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(_roleIcon(role), size: 18, color: color),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      roleLabel(l10n, role),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: textColor,
                      ),
                    ),
                    if (description.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        description,
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.mutedFor(isDark),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (selected)
                Icon(Icons.check_rounded, size: 20, color: color)
              else if (!disabled)
                Icon(
                  Icons.chevron_right_rounded,
                  size: 20,
                  color: AppColors.mutedFor(isDark),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

IconData _roleIcon(String role) {
  switch (role) {
    case 'professor':
      return Icons.co_present_rounded;
    case 'parent':
      return Icons.family_restroom_rounded;
    case 'student':
      return Icons.school_rounded;
    case 'admin':
      return Icons.admin_panel_settings_rounded;
    case 'branch':
      return Icons.apartment_rounded;
    default:
      return Icons.person_rounded;
  }
}

Color _roleColor(String role) {
  switch (role) {
    case 'admin':
      return AppColors.roleAdmin;
    case 'branch':
      return AppColors.roleBranch;
    case 'professor':
      return AppColors.roleProfessor;
    case 'parent':
      return AppColors.roleParent;
    case 'student':
      return AppColors.roleStudent;
    default:
      return AppColors.primary;
  }
}
