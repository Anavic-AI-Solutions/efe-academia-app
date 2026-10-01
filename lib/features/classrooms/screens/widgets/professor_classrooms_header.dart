import 'package:flutter/material.dart';

import '../../../../app/theme/app_typography.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../core/widgets/gradient_header.dart';
import '../../../../l10n/l10n.dart';

class ProfessorClassroomsHeader extends StatelessWidget {
  final String subtitle;
  final String? title;

  const ProfessorClassroomsHeader({
    super.key,
    required this.subtitle,
    this.title,
  });

  @override
  Widget build(BuildContext context) {
    return GradientHeader(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title ?? context.l10n.professorMyClassrooms,
            style: AppTypography.headlineMedium.copyWith(
              color: AppColors.onPrimary,
              fontWeight: FontWeight.w800,
            ),
          ),
          if (subtitle.isNotEmpty) ...[
            const SizedBox(height: 3),
            Text(
              subtitle,
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.onPrimaryMuted,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
