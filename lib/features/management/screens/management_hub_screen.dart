import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/large_title_bar.dart';
import '../../../l10n/app_localizations.dart';
import '../../../l10n/l10n.dart';
import '../../auth/domain/user_model.dart';
import '../../auth/providers/auth_provider.dart';

/// Management hub: starts the CRUD flows available to staff users.
///
/// The route is only linked from the menu for admins and branch users.
class ManagementHubScreen extends ConsumerWidget {
  const ManagementHubScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isStaff = ref.watch(authProvider).user?.isStaff ?? false;

    return Scaffold(
      backgroundColor: AppColors.backgroundFor(isDark),
      body: Column(
        children: [
          LargeTitleBar(title: l10n.managementTitle),
          Expanded(
            child: isStaff
                ? ListView(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                    children: [
                      for (final section in _sections(l10n))
                        ..._buildSection(context, section, isDark),
                    ],
                  )
                : EmptyState(
                    icon: PhosphorIconsRegular.lockSimple,
                    title: l10n.noData,
                    subtitle: l10n.noDataSubtitle,
                  ),
          ),
        ],
      ),
    );
  }

  List<_HubSection> _sections(AppLocalizations l10n) => [
        _HubSection(
          label: l10n.managementPeople,
          links: [
            _HubLink(
              label: l10n.managementStudents,
              icon: PhosphorIconsRegular.graduationCap,
              route: '/students',
            ),
            _HubLink(
              label: l10n.managementProfessors,
              icon: PhosphorIconsRegular.chalkboardTeacher,
              route: '/professors',
            ),
          ],
        ),
        _HubSection(
          label: l10n.managementAcademic,
          links: [
            _HubLink(
              label: l10n.managementClassrooms,
              icon: PhosphorIconsRegular.chalkboardTeacher,
              route: '/classrooms',
            ),
          ],
        ),
        _HubSection(
          label: l10n.managementContent,
          links: [
            _HubLink(
              label: l10n.managementNews,
              icon: PhosphorIconsRegular.article,
              route: '/news',
            ),
            _HubLink(
              label: l10n.managementEvents,
              icon: PhosphorIconsRegular.calendarBlank,
              route: '/events',
            ),
            _HubLink(
              label: l10n.managementDocuments,
              icon: PhosphorIconsRegular.fileText,
              route: '/documents',
            ),
            _HubLink(
              label: l10n.managementFaqs,
              icon: PhosphorIconsRegular.question,
              route: '/faqs',
            ),
          ],
        ),
      ];

  List<Widget> _buildSection(
    BuildContext context,
    _HubSection section,
    bool isDark,
  ) {
    return [
      Padding(
        padding: const EdgeInsets.fromLTRB(4, 12, 4, 10),
        child: Text(
          section.label,
          style: AppTypography.titleSmall.copyWith(
            color: isDark
                ? AppColors.darkTextSecondary
                : AppColors.lightTextSecondary,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      for (final link in section.links)
        _HubTile(link: link, onTap: () => context.push(link.route)),
    ];
  }
}

class _HubSection {
  final String label;
  final List<_HubLink> links;

  const _HubSection({required this.label, required this.links});
}

class _HubLink {
  final String label;
  final IconData icon;
  final String route;

  const _HubLink({
    required this.label,
    required this.icon,
    required this.route,
  });
}

class _HubTile extends StatelessWidget {
  final _HubLink link;
  final VoidCallback onTap;

  const _HubTile({required this.link, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = AppColors.accentFor(isDark);
    final textColor =
        isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final mutedColor =
        isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary;

    return AppCard(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      onTap: onTap,
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(link.icon, size: 20, color: accent),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              link.label,
              style: AppTypography.titleSmall.copyWith(color: textColor),
            ),
          ),
          Icon(PhosphorIconsRegular.caretRight, size: 18, color: mutedColor),
        ],
      ),
    );
  }
}
