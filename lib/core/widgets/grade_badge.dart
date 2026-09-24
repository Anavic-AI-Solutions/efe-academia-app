import 'package:flutter/material.dart';

import '../../app/theme/professor_colors.dart';

/// Grade pill following the professor mockup: colored background + white text.
class GradeBadge extends StatelessWidget {
  final double? grade;
  final double fontSize;

  const GradeBadge({super.key, required this.grade, this.fontSize = 12});

  @override
  Widget build(BuildContext context) {
    final isEmpty = grade == null;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isEmpty
            ? ProfessorColors.gradeEmptyBackground
            : ProfessorColors.gradeColor(grade),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        ProfessorColors.formatGrade(grade),
        style: TextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.w800,
          color: isEmpty ? ProfessorColors.muted : Colors.white,
        ),
      ),
    );
  }
}
