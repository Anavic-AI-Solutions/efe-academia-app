import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../../core/utils/status_labels.dart';
import '../../../../core/widgets/avatar.dart';
import '../../../../core/widgets/detail_hero.dart';
import '../../../../l10n/l10n.dart';
import '../../domain/student_model.dart';

class StudentDetailHeader extends StatelessWidget {
  final StudentModel student;

  const StudentDetailHeader({
    super.key,
    required this.student,
  });

  @override
  Widget build(BuildContext context) {
    return DetailHero(
      leading: AppAvatar(
        imageUrl: student.avatarUrl,
        name: student.fullname,
        size: 52,
        showBorder: true,
      ),
      title: student.fullname,
      status: studentStatusLabel(student.status, context.l10n),
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
