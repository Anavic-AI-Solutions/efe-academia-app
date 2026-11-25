import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/avatar.dart';
import '../../../../core/widgets/status_badge.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../l10n/l10n.dart';
import '../../domain/parent_model.dart';

/// Localized label for the raw parent status returned by the API.
///
/// Shared by the list card, the detail screen and the form dropdown.
String parentStatusLabel(String status, AppLocalizations l10n) {
  switch (status.toLowerCase()) {
    case 'approved':
      return l10n.parentsStatusApproved;
    case 'pending':
      return l10n.parentsStatusPending;
    case 'rejected':
      return l10n.parentsStatusRejected;
    default:
      return status;
  }
}

class ParentCard extends StatelessWidget {
  final ParentModel parent;
  final VoidCallback? onTap;

  const ParentCard({
    super.key,
    required this.parent,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = context.l10n;
    final textColor =
        isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final mutedColor = AppColors.mutedFor(isDark);

    return AppCard(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      onTap: onTap,
      child: Row(
        children: [
          AppAvatar(
            name: parent.fullname,
            size: 44,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  parent.fullname,
                  style: AppTypography.titleSmall.copyWith(color: textColor),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                Text(
                  parent.email.isNotEmpty ? parent.email : '—',
                  style: AppTypography.bodySmall.copyWith(color: mutedColor),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 10,
                  runSpacing: 6,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    if (parent.status.isNotEmpty)
                      StatusBadge(
                        status: parent.status,
                        label: parentStatusLabel(parent.status, l10n),
                      ),
                    _Meta(
                      icon: PhosphorIconsRegular.users,
                      label: l10n.parentsStudentCount(parent.studentCount),
                      color: AppColors.primary,
                      textColor: mutedColor,
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Icon(
            PhosphorIconsRegular.caretRight,
            size: 16,
            color: isDark
                ? AppColors.darkTextTertiary
                : AppColors.lightTextTertiary,
          ),
        ],
      ),
    );
  }
}

class _Meta extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final Color textColor;

  const _Meta({
    required this.icon,
    required this.label,
    required this.color,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: color),
        const SizedBox(width: 4),
        Text(
          label,
          style: AppTypography.bodySmall.copyWith(color: textColor),
        ),
      ],
    );
  }
}
