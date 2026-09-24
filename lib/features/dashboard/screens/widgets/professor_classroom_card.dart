import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/professor_colors.dart';
import '../../../../l10n/l10n.dart';

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

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? ProfessorColors.primarySoft : Colors.transparent,
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected
                  ? ProfessorColors.primarySoft.withOpacity(0.35)
                  : const Color(0x59232D3C).withOpacity(isDark ? 0.3 : 0.12),
              blurRadius: 24,
              offset: const Offset(0, 10),
              spreadRadius: -14,
            ),
          ],
        ),
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
                          : ProfessorColors.ink,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    context.l10n.professorStudentsCount(studentsCount),
                    style: const TextStyle(
                      fontSize: 11,
                      color: ProfessorColors.muted,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              const Icon(
                Icons.check_circle_rounded,
                size: 20,
                color: ProfessorColors.primarySoft,
              ),
          ],
        ),
      ),
    );
  }
}
