import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../../core/widgets/detail_hero.dart';
import '../../domain/classroom_model.dart';

class ClassroomDetailHeader extends StatelessWidget {
  final ClassroomModel classroom;

  const ClassroomDetailHeader({super.key, required this.classroom});

  @override
  Widget build(BuildContext context) {
    return DetailHero(
      leading: const DetailHeroIcon(
        icon: PhosphorIconsRegular.chalkboardTeacher,
      ),
      title: classroom.name,
      status: classroom.status,
      fallbackRoute: '/classrooms',
      chips: [
        if (classroom.branch.isNotEmpty)
          DetailHeroChip(
            icon: PhosphorIconsRegular.mapPin,
            label: classroom.branch,
          ),
        if (classroom.level.isNotEmpty)
          DetailHeroChip(
            icon: PhosphorIconsRegular.graduationCap,
            label: classroom.level,
          ),
        if (classroom.year.isNotEmpty)
          DetailHeroChip(
            icon: PhosphorIconsRegular.calendarBlank,
            label: classroom.year,
          ),
      ],
    );
  }
}
