import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../l10n/app_localizations.dart';
import '../../../l10n/l10n.dart';
import '../../auth/providers/auth_provider.dart';
import '../domain/menu_entry.dart';
import 'widgets/menu_tile.dart';

class MenuScreen extends ConsumerWidget {
  const MenuScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final role = ref.watch(authProvider).user?.role ?? '';
    final entries = menuEntriesForRole(role);

    return Scaffold(
      backgroundColor: AppColors.backgroundFor(isDark),
      appBar: AppBar(title: Text(l10n.navMenu)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          for (final group in MenuGroup.values)
            ..._buildGroup(
              context: context,
              group: group,
              entries: entries.where((entry) => entry.group == group).toList(),
              role: role,
              isDark: isDark,
              l10n: l10n,
            ),
        ],
      ),
    );
  }

  List<Widget> _buildGroup({
    required BuildContext context,
    required MenuGroup group,
    required List<MenuEntry> entries,
    required String role,
    required bool isDark,
    required AppLocalizations l10n,
  }) {
    if (entries.isEmpty) return const [];

    return [
      Padding(
        padding: const EdgeInsets.fromLTRB(4, 12, 4, 10),
        child: Text(
          _groupLabel(group, l10n),
          style: AppTypography.titleSmall.copyWith(
            color: isDark
                ? AppColors.darkTextSecondary
                : AppColors.lightTextSecondary,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      for (final entry in entries)
        MenuTile(
          entry: entry,
          label: _sectionLabel(entry.section, l10n),
          onTap: () {
            final route = entry.routeFor(role);
            if (entry.isShellTabFor(role)) {
              context.go(route);
            } else {
              context.push(route);
            }
          },
        ),
    ];
  }

  String _groupLabel(MenuGroup group, AppLocalizations l10n) {
    switch (group) {
      case MenuGroup.management:
        return l10n.menuGroupManagement;
      case MenuGroup.academic:
        return l10n.menuGroupAcademic;
      case MenuGroup.communication:
        return l10n.menuGroupCommunication;
      case MenuGroup.accountSupport:
        return l10n.menuGroupAccountSupport;
    }
  }

  String _sectionLabel(MenuSection section, AppLocalizations l10n) {
    switch (section) {
      case MenuSection.management:
        return l10n.menuManagement;
      case MenuSection.calendar:
        return l10n.menuCalendar;
      case MenuSection.courses:
        return l10n.menuCourses;
      case MenuSection.requests:
        return l10n.menuRequests;
      case MenuSection.communication:
        return l10n.menuCommunication;
      case MenuSection.notifications:
        return l10n.menuNotifications;
      case MenuSection.profile:
        return l10n.menuProfile;
      case MenuSection.fees:
        return l10n.menuFees;
      case MenuSection.history:
        return l10n.menuHistory;
      case MenuSection.library:
        return l10n.menuLibrary;
      case MenuSection.documents:
        return l10n.menuDocuments;
      case MenuSection.faq:
        return l10n.menuFaq;
      case MenuSection.birthdays:
        return l10n.menuBirthdays;
      case MenuSection.statistics:
        return l10n.menuStatistics;
    }
  }
}
