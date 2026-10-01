import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../l10n/l10n.dart';
import '../../../professor/widgets/professor_card.dart';

class ProfessorClassroomCard extends StatelessWidget {
  final String name;
  final int studentsCount;
  final bool isSelected;
  final VoidCallback onTap;

  const ProfessorClassroomCard({
    super.key,
    required this.name,
    required this.studentsCount,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ProfessorCard(
      isSelected: isSelected,
      onTap: onTap,
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: isDark
                        ? AppColors.darkTextPrimary
                        : AppColors.lightInk,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  context.l10n.professorStudentsCount(studentsCount),
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.muted,
                  ),
                ),
              ],
            ),
          ),
          if (isSelected)
            const Icon(
              Icons.check_circle_rounded,
              size: 20,
              color: AppColors.primarySoft,
            ),
        ],
      ),
    );
  }
}
