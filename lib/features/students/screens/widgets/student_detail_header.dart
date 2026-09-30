import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../../app/theme/professor_colors.dart';
import '../../../../core/widgets/avatar.dart';
import '../../../../core/widgets/detail_hero.dart';
import '../../domain/student_model.dart';

class StudentDetailHeader extends StatelessWidget {
  final StudentModel student;
  final bool isProfessor;

  const StudentDetailHeader({
    super.key,
    required this.student,
    this.isProfessor = false,
  });

  @override
  Widget build(BuildContext context) {
    return DetailHero(
      gradient: isProfessor ? ProfessorColors.headerGradient : null,
      leading: AppAvatar(
        imageUrl: student.avatarUrl,
        name: student.fullname,
        size: 52,
        showBorder: true,
      ),
      title: student.fullname,
      status: student.status,
      fallbackRoute: '/students',
      chips: [
        if (student.branch.isNotEmpty)
          DetailHeroChip(
            icon: PhosphorIconsRegular.mapPin,
            label: student.branch,
          ),
        if (student.year.isNotEmpty)
          DetailHeroChip(
            icon: PhosphorIconsRegular.calendarBlank,
            label: student.year,
          ),
      ],
    );
  }
}
