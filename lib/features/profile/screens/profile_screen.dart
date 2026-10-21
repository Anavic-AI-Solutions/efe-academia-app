import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../auth/providers/auth_provider.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/avatar.dart';
import '../../../core/widgets/large_title_bar.dart';
import '../../../core/widgets/pill_button.dart';
import '../../../core/widgets/section_header.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../app/locale/locale_provider.dart';
import '../../../app/theme/theme_provider.dart';
import '../../../l10n/app_localizations.dart';
import '../../../l10n/l10n.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final user = authState.user;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final l10n = context.l10n;
    final locale = ref.watch(localeProvider);
    final themeMode = ref.watch(themeModeProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundFor(isDark),
      body: Column(
        children: [
          LargeTitleBar(
            title: l10n.navProfile,
            showBackButton: false,
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
              children: [
                // Profile header
                Center(
                  child: Column(
                    children: [
                      AppAvatar(
                        imageUrl: user?.avatarUrl,
                        name: user?.name ?? l10n.commonUser,
                        size: 80,
                        showGradientRing: true,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        user?.name ?? l10n.commonUser,
                        style: AppTypography.headlineMedium.copyWith(
                          color: isDark
                              ? AppColors.darkTextPrimary
                              : AppColors.lightTextPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        user?.email ?? '',
                        style: AppTypography.bodyMedium.copyWith(
                          color: isDark
                              ? AppColors.darkTextSecondary
                              : AppColors.lightTextSecondary,
                        ),
                      ),
                      const SizedBox(height: 10),
                      _RoleBadge(role: user?.role ?? ''),
                    ],
                  ),
                ),
                const SizedBox(height: 36),

                // Account section
                SectionHeader(
                  title: l10n.profileAccount,
                  padding: EdgeInsets.zero,
                ),
                const SizedBox(height: 8),
                AppCard(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Column(
                    children: [
                      _SettingsTile(
                        icon: PhosphorIconsRegular.user,
                        title: l10n.profileEditProfile,
                        onTap: () {},
                        isDark: isDark,
                      ),
                      _SettingsTile(
                        icon: PhosphorIconsRegular.bell,
                        title: l10n.profileNotifications,
                        onTap: () => context.push('/notifications'),
                        isDark: isDark,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Preferences section
                SectionHeader(
                  title: l10n.profilePreferences,
                  padding: EdgeInsets.zero,
                ),
                const SizedBox(height: 8),
                AppCard(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Column(
                    children: [
                      _SettingsTile(
                        icon: PhosphorIconsRegular.moon,
                        title: l10n.profileTheme,
                        trailing: Text(
                          _themeModeLabel(themeMode, l10n),
                          style: AppTypography.bodyMedium.copyWith(
                            color: isDark
                                ? AppColors.darkTextTertiary
                                : AppColors.lightTextTertiary,
                          ),
                        ),
                        onTap: () => _showThemeSheet(context, ref),
                        isDark: isDark,
                      ),
                      _SettingsTile(
                        icon: PhosphorIconsRegular.globe,
                        title: l10n.profileLanguage,
                        trailing: Text(
                          locale.languageCode == 'en'
                              ? l10n.languageEnglish
                              : l10n.languageSpanish,
                          style: AppTypography.bodyMedium.copyWith(
                            color: isDark
                                ? AppColors.darkTextTertiary
                                : AppColors.lightTextTertiary,
                          ),
                        ),
                        onTap: () => _showLanguageSheet(context, ref),
                        isDark: isDark,
                        showDivider: false,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // About section
                SectionHeader(
                  title: l10n.profileAbout,
                  padding: EdgeInsets.zero,
                ),
                const SizedBox(height: 8),
                AppCard(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Column(
                    children: [
                      _SettingsTile(
                        icon: PhosphorIconsRegular.info,
                        title: l10n.profileAbout,
                        onTap: () {},
                        isDark: isDark,
                      ),
                      _SettingsTile(
                        icon: PhosphorIconsRegular.question,
                        title: l10n.profileHelpSupport,
                        onTap: () {},
                        isDark: isDark,
                        showDivider: false,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // Logout button
                PillButton(
                  label: l10n.profileLogout,
                  icon: PhosphorIconsBold.power,
                  color: AppColors.error,
                  onPressed: () async {
                    final confirmed = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: Text(l10n.profileLogout),
                        content: Text(l10n.profileLogoutConfirm),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: Text(l10n.commonCancel),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(context, true),
                            child: Text(
                              l10n.profileLogout,
                              style: const TextStyle(color: AppColors.error),
                            ),
                          ),
                        ],
                      ),
                    );
                    if (confirmed == true && context.mounted) {
                      await ref.read(authProvider.notifier).logout();
                    }
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showLanguageSheet(BuildContext context, WidgetRef ref) async {
    final l10n = context.l10n;
    final current = ref.read(localeProvider);

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Theme.of(context).brightness == Brightness.dark
          ? AppColors.darkSurface
          : AppColors.lightSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
                child: Text(
                  l10n.profileSelectLanguage,
                  style: AppTypography.titleMedium,
                ),
              ),
              ListTile(
                title: Text(l10n.languageSpanish),
                trailing: current.languageCode == 'es'
                    ? const Icon(Icons.check_rounded, color: AppColors.primary)
                    : null,
                onTap: () {
                  ref
                      .read(localeProvider.notifier)
                      .setLocale(const Locale('es', 'AR'));
                  Navigator.pop(sheetContext);
                },
              ),
              ListTile(
                title: Text(l10n.languageEnglish),
                trailing: current.languageCode == 'en'
                    ? const Icon(Icons.check_rounded, color: AppColors.primary)
                    : null,
                onTap: () {
                  ref
                      .read(localeProvider.notifier)
                      .setLocale(const Locale('en'));
                  Navigator.pop(sheetContext);
                },
              ),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }

  Future<void> _showThemeSheet(BuildContext context, WidgetRef ref) async {
    final l10n = context.l10n;
    final current = ref.read(themeModeProvider);

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Theme.of(context).brightness == Brightness.dark
          ? AppColors.darkSurface
          : AppColors.lightSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
                child: Text(
                  l10n.profileSelectTheme,
                  style: AppTypography.titleMedium,
                ),
              ),
              for (final mode in const [
                ThemeMode.light,
                ThemeMode.dark,
                ThemeMode.system,
              ])
                ListTile(
                  title: Text(_themeModeLabel(mode, l10n)),
                  trailing: current == mode
                      ? const Icon(
                          Icons.check_rounded,
                          color: AppColors.primary,
                        )
                      : null,
                  onTap: () {
                    ref.read(themeModeProvider.notifier).setThemeMode(mode);
                    Navigator.pop(sheetContext);
                  },
                ),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }
}

String _themeModeLabel(ThemeMode mode, AppLocalizations l10n) {
  switch (mode) {
    case ThemeMode.light:
      return l10n.profileThemeLight;
    case ThemeMode.dark:
      return l10n.profileThemeDark;
    case ThemeMode.system:
      return l10n.profileThemeSystem;
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
        _getRoleName(context, role),
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

  String _getRoleName(BuildContext context, String role) {
    final l10n = context.l10n;
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
            color: AppColors.accentFor(isDark),
          ),
          title: Text(
            title,
            style: AppTypography.bodyLarge.copyWith(
              color: isDark
                  ? AppColors.darkTextPrimary
                  : AppColors.lightTextPrimary,
            ),
          ),
          trailing: trailing ??
              Icon(
                PhosphorIconsRegular.caretRight,
                size: 16,
                color: isDark
                    ? AppColors.darkTextTertiary
                    : AppColors.lightTextTertiary,
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
