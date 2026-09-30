import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../../app/theme/professor_colors.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/info_row.dart';
import '../../../../core/widgets/section_header.dart';
import '../../../../core/widgets/stat_card.dart';
import '../../../../l10n/l10n.dart';
import '../../domain/student_model.dart';

class StudentInfoTab extends StatelessWidget {
  final StudentModel student;
  final bool isProfessor;

  const StudentInfoTab({
    super.key,
    required this.student,
    this.isProfessor = false,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      children: [
        SizedBox(
          height: 150,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              StatCard(
                icon: PhosphorIconsRegular.calendarBlank,
                value: student.year.isNotEmpty ? student.year : '—',
                label: l10n.studentsInfoYear,
                iconColor: isProfessor
                    ? ProfessorColors.primary
                    : const Color(0xFF3B82F6),
              ),
              const SizedBox(width: 12),
              StatCard(
                icon: PhosphorIconsRegular.mapPin,
                value: student.branch.isNotEmpty ? student.branch : '—',
                label: l10n.studentsInfoBranch,
                iconColor: isProfessor
                    ? ProfessorColors.primarySoft
                    : const Color(0xFF10B981),
              ),
              const SizedBox(width: 12),
              StatCard(
                icon: PhosphorIconsRegular.chalkboardTeacher,
                value: '${student.classroomCount}',
                label: l10n.studentsInfoClassrooms,
                iconColor: isProfessor
                    ? ProfessorColors.accent
                    : const Color(0xFFF97316),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        SectionHeader(
          title: l10n.studentsSectionPersonal,
          padding: EdgeInsets.zero,
        ),
        const SizedBox(height: 8),
        AppCard(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Column(
            children: [
              InfoRow(
                label: l10n.studentsInfoFullName,
                value: student.fullname,
              ),
              InfoRow(label: l10n.studentsInfoEmail, value: student.email),
              InfoRow(
                label: l10n.studentsInfoIdentityNumber,
                value: student.identityNumber,
                isLast: true,
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        SectionHeader(
          title: l10n.studentsSectionInstitutional,
          padding: EdgeInsets.zero,
        ),
        const SizedBox(height: 8),
        AppCard(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Column(
            children: [
              InfoRow(label: l10n.studentsInfoYear, value: student.year),
              InfoRow(label: l10n.studentsInfoBranch, value: student.branch),
              InfoRow(
                label: l10n.studentsInfoClassrooms,
                value: '${student.classroomCount}',
                isLast: true,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
