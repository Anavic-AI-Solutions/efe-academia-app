import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/professor_colors.dart';
import '../../../../core/widgets/grade_badge.dart';

class GradeStudentRow extends StatelessWidget {
  final String fullname;
  final double? average;
  final VoidCallback? onTap;

  const GradeStudentRow({
    super.key,
    required this.fullname,
    this.average,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : Colors.white,
          borderRadius: BorderRadius.circular(13),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF28325A).withOpacity(isDark ? 0.3 : 0.14),
              blurRadius: 20,
              offset: const Offset(0, 8),
              spreadRadius: -14,
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                fullname,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isDark
                      ? AppColors.darkTextPrimary
                      : ProfessorColors.ink,
                ),
              ),
            ),
            GradeBadge(grade: average),
          ],
        ),
      ),
    );
  }
}
