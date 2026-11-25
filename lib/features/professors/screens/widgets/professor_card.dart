import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/avatar.dart';
import '../../../../l10n/l10n.dart';
import '../../../classrooms/domain/professor_model.dart';

class ProfessorCard extends StatelessWidget {
  final ProfessorModel professor;
  final VoidCallback? onTap;

  const ProfessorCard({
    super.key,
    required this.professor,
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
            name: professor.fullname,
            size: 44,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  professor.fullname,
                  style: AppTypography.titleSmall.copyWith(color: textColor),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                Text(
                  professor.email.isNotEmpty ? professor.email : '—',
                  style: AppTypography.bodySmall.copyWith(color: mutedColor),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 12,
                  runSpacing: 4,
                  children: [
                    if (professor.specialty.isNotEmpty)
                      _Meta(
                        icon: PhosphorIconsRegular.bookOpen,
                        label: professor.specialty,
                        color: AppColors.accentFor(isDark),
                        textColor: mutedColor,
                      ),
                    _Meta(
                      icon: PhosphorIconsRegular.users,
                      label: l10n.professorsClassroomsCount(
                        professor.classroomCount,
                      ),
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
