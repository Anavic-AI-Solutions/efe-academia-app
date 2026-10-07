import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../core/utils/status_labels.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/status_badge.dart';
import '../../../../l10n/l10n.dart';
import '../../domain/absence_model.dart';

class AbsenceTile extends StatelessWidget {
  final AbsenceModel absence;

  const AbsenceTile({super.key, required this.absence});

  Color _statusColor(AbsenceModel absence) {
    final status = absence.status.toLowerCase();
    if (status == 'pending') return AppColors.warning;
    if (status == 'unjustified') return AppColors.error;
    return absenceIsJustified(absence.status, absence.justified)
        ? AppColors.success
        : AppColors.error;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = context.l10n;
    final subtitle = [
      if (absence.period.isNotEmpty) absence.period,
      if (absence.date.isNotEmpty) absence.date,
    ].join(' · ');

    return AppCard(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.error.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            alignment: Alignment.center,
            child: Text(
              '${absence.quantity}',
              style: AppTypography.titleMedium.copyWith(
                color: AppColors.error,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  absence.description.isNotEmpty
                      ? absence.description
                      : l10n.studentsAbsenceTitle,
                  style: AppTypography.titleSmall.copyWith(
                    color: isDark
                        ? AppColors.darkTextPrimary
                        : AppColors.lightTextPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (subtitle.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: AppTypography.bodySmall.copyWith(
                      color: isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.lightTextSecondary,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          StatusBadge(
            status: absenceStatusLabel(
              absence.status,
              absence.justified,
              l10n,
            ),
            color: _statusColor(absence),
          ),
        ],
      ),
    );
  }
}
