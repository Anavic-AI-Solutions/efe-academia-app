import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../auth/providers/auth_provider.dart';
import '../../../core/widgets/avatar.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final user = authState.user;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      body: ListView(
        padding: EdgeInsets.fromLTRB(
          20,
          MediaQuery.of(context).padding.top + 16,
          20,
          40,
        ),
        children: [
          // Profile header
          Center(
            child: Column(
              children: [
                AppAvatar(
                  imageUrl: user?.avatarUrl,
                  name: user?.name ?? 'User',
                  size: 80,
                  showGradientRing: true,
                ),
                const SizedBox(height: 16),
                Text(
                  user?.name ?? 'User',
                  style: AppTypography.headlineMedium.copyWith(
                    color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  user?.email ?? '',
                  style: AppTypography.bodyMedium.copyWith(
                    color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                  ),
                ),
                const SizedBox(height: 10),
                _RoleBadge(role: user?.role ?? ''),
              ],
            ),
          ),
          const SizedBox(height: 36),

          // Account section
          _SectionLabel(title: 'Account', isDark: isDark),
          const SizedBox(height: 8),
          _SettingsGroup(
            isDark: isDark,
            children: [
              _SettingsTile(
                icon: PhosphorIconsRegular.user,
                title: 'Edit Profile',
                onTap: () {},
                isDark: isDark,
              ),
              _SettingsTile(
                icon: PhosphorIconsRegular.bell,
                title: 'Notifications',
                onTap: () => context.push('/notifications'),
                isDark: isDark,
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Preferences section
          _SectionLabel(title: 'Preferences', isDark: isDark),
          const SizedBox(height: 8),
          _SettingsGroup(
            isDark: isDark,
            children: [
              _SettingsTile(
                icon: PhosphorIconsRegular.moon,
                title: 'Theme',
                onTap: () {},
                isDark: isDark,
              ),
              _SettingsTile(
                icon: PhosphorIconsRegular.globe,
                title: 'Language',
                trailing: Text(
                  'English',
                  style: AppTypography.bodyMedium.copyWith(
                    color: isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary,
                  ),
                ),
                onTap: () {},
                isDark: isDark,
                showDivider: false,
              ),
            ],
          ),
          const SizedBox(height: 24),

          // About section
          _SectionLabel(title: 'About', isDark: isDark),
          const SizedBox(height: 8),
          _SettingsGroup(
            isDark: isDark,
            children: [
              _SettingsTile(
                icon: PhosphorIconsRegular.info,
                title: 'About',
                onTap: () {},
                isDark: isDark,
              ),
              _SettingsTile(
                icon: PhosphorIconsRegular.question,
                title: 'Help & Support',
                onTap: () {},
                isDark: isDark,
                showDivider: false,
              ),
            ],
          ),
          const SizedBox(height: 32),

          // Logout button
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () async {
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Logout'),
                    content: const Text('Are you sure you want to logout?'),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text(
                          'Logout',
                          style: TextStyle(color: AppColors.error),
                        ),
                      ),
                    ],
                  ),
                );
                if (confirmed == true && context.mounted) {
                  await ref.read(authProvider.notifier).logout();
                }
              },
              icon: const Icon(PhosphorIconsBold.power, size: 20),
              label: const Text('Logout'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.error,
                side: BorderSide(color: AppColors.error.withOpacity(0.3)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RoleBadge extends StatelessWidget {
  final String role;

  const _RoleBadge({required this.role});

  @override
  Widget build(BuildContext context) {
    final roleColor = _getRoleColor(role);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: roleColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        _getRoleName(role),
        style: AppTypography.labelSmall.copyWith(
          color: roleColor,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Color _getRoleColor(String role) {
    switch (role) {
      case 'admin':
        return AppColors.roleAdmin;
      case 'branch':
        return AppColors.roleBranch;
      case 'professor':
        return AppColors.roleProfessor;
      case 'student':
        return AppColors.roleStudent;
      case 'parent':
        return AppColors.roleParent;
      default:
        return AppColors.primary;
    }
  }

  String _getRoleName(String role) {
    switch (role) {
      case 'admin':
        return 'Administrator';
      case 'branch':
        return 'Branch Director';
      case 'professor':
        return 'Professor';
      case 'parent':
        return 'Parent';
      case 'student':
        return 'Student';
      default:
        return role.isNotEmpty ? role : 'User';
    }
  }
}

class _SectionLabel extends StatelessWidget {
  final String title;
  final bool isDark;

  const _SectionLabel({required this.title, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Text(
      title.toUpperCase(),
      style: AppTypography.labelSmall.copyWith(
        color: isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary,
        letterSpacing: 0.8,
      ),
    );
  }
}

class _SettingsGroup extends StatelessWidget {
  final List<Widget> children;
  final bool isDark;

  const _SettingsGroup({required this.children, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.04),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: children,
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool isDark;
  final bool showDivider;

  const _SettingsTile({
    required this.icon,
    required this.title,
    this.trailing,
    this.onTap,
    required this.isDark,
    this.showDivider = true,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ListTile(
          onTap: onTap,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16),
          leading: Icon(
            icon,
            size: 20,
            color: isDark ? const Color(0xFF6366F1) : AppColors.primary,
          ),
          title: Text(
            title,
            style: AppTypography.bodyLarge.copyWith(
              color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
            ),
          ),
          trailing: trailing ??
              Icon(
                PhosphorIconsRegular.caretRight,
                size: 16,
                color: isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary,
              ),
        ),
        if (showDivider)
          Divider(
            height: 1,
            indent: 52,
            color: isDark ? AppColors.darkBorder : AppColors.lightDivider,
          ),
      ],
    );
  }
}
