import 'package:flutter/material.dart';

import '../../../../core/widgets/header_stats_row.dart';
import '../../../../l10n/l10n.dart';

/// Professor home stats, delegating to the neutral [HeaderStatsRow].
class ProfessorStatsRow extends StatelessWidget {
  final int classrooms;
  final int students;
  final int absences;

  const ProfessorStatsRow({
    super.key,
    required this.classrooms,
    required this.students,
    required this.absences,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return HeaderStatsRow(
      stats: [
        HeaderStat(value: '$classrooms', label: l10n.professorStatClassrooms),
        HeaderStat(value: '$students', label: l10n.professorStatStudents),
        HeaderStat(
          value: '$absences',
          label: l10n.professorStatAbsences,
          highlighted: true,
        ),
      ],
    );
  }
}
