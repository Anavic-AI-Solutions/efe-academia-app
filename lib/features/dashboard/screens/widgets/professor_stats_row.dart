import 'package:flutter/material.dart';

import '../../../../app/theme/professor_colors.dart';
import '../../../../l10n/l10n.dart';

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

    return Row(
      children: [
        Expanded(
          child: _StatTile(
            value: '$classrooms',
            label: l10n.professorStatClassrooms,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatTile(
            value: '$students',
            label: l10n.professorStatStudents,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatTile(
            value: '$absences',
            label: l10n.professorStatAbsences,
            highlighted: true,
          ),
        ),
      ],
    );
  }
}

class _StatTile extends StatelessWidget {
  final String value;
  final String label;
  final bool highlighted;

  const _StatTile({
    required this.value,
    required this.label,
    this.highlighted = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: highlighted
            ? ProfessorColors.overlayStrong
            : ProfessorColors.overlay,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w900,
              color: ProfessorColors.onPrimary,
            ),
          ),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 11,
              color: ProfessorColors.onPrimaryMuted,
            ),
          ),
        ],
      ),
    );
  }
}
