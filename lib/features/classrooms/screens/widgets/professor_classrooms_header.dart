import 'package:flutter/material.dart';

import '../../../../app/theme/app_typography.dart';
import '../../../../app/theme/professor_colors.dart';
import '../../../../l10n/l10n.dart';
import '../../../professor/widgets/professor_gradient_header.dart';

class ProfessorClassroomsHeader extends StatelessWidget {
  final String subtitle;

  const ProfessorClassroomsHeader({super.key, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return ProfessorGradientHeader(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.l10n.professorMyClassrooms,
            style: AppTypography.headlineMedium.copyWith(
              color: ProfessorColors.onPrimary,
              fontWeight: FontWeight.w800,
            ),
          ),
          if (subtitle.isNotEmpty) ...[
            const SizedBox(height: 3),
            Text(
              subtitle,
              style: const TextStyle(
                fontSize: 11,
                color: ProfessorColors.onPrimaryMuted,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
