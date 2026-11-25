import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../core/utils/status_labels.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/info_row.dart';
import '../../../../core/widgets/section_header.dart';
import '../../../../core/widgets/stat_card.dart';
import '../../../../l10n/l10n.dart';
import '../../domain/classroom_model.dart';

class ClassroomSummaryTab extends StatelessWidget {
  final ClassroomModel classroom;

  const ClassroomSummaryTab({
    super.key,
    required this.classroom,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      children: [
        SizedBox(
          height: 150,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              StatCard(
                icon: PhosphorIconsRegular.users,
                value: '${classroom.studentCount}',
                label: l10n.classroomsStudents,
                iconColor: AppColors.primary,
              ),
              const SizedBox(width: 12),
              StatCard(
                icon: PhosphorIconsRegular.mapPin,
                value: classroom.room.isNotEmpty ? classroom.room : '—',
                label: l10n.classroomsRoom,
                iconColor: AppColors.primarySoft,
              ),
              const SizedBox(width: 12),
              StatCard(
                icon: PhosphorIconsRegular.clock,
                value: classroom.shift.isNotEmpty
                    ? classroomShiftLabel(classroom.shift, l10n)
                    : '—',
                label: l10n.classroomsShift,
                iconColor: AppColors.accent,
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        if (classroom.description.isNotEmpty) ...[
          SectionHeader(
              title: l10n.classroomsDescription, padding: EdgeInsets.zero),
          const SizedBox(height: 8),
          AppCard(
            padding: const EdgeInsets.all(16),
            child: Text(
              classroom.description,
              style: AppTypography.bodyMedium.copyWith(
                color: Theme.of(context).brightness == Brightness.dark
                    ? AppColors.darkTextSecondary
                    : AppColors.lightTextSecondary,
              ),
            ),
          ),
          const SizedBox(height: 20),
        ],
        SectionHeader(
            title: l10n.classroomsSectionSchedule, padding: EdgeInsets.zero),
        const SizedBox(height: 8),
        AppCard(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Column(
            children: [
              InfoRow(
                label: l10n.classroomsShift,
                value: classroomShiftLabel(classroom.shift, l10n),
              ),
              InfoRow(label: l10n.classroomsDay, value: classroom.day),
              InfoRow(label: l10n.classroomsHour, value: classroom.hour),
              InfoRow(
                label: l10n.classroomsCourseDays,
                value:
                    classroom.courseDays > 0 ? '${classroom.courseDays}' : '',
                isLast: true,
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        SectionHeader(
            title: l10n.classroomsSectionAcademic, padding: EdgeInsets.zero),
        const SizedBox(height: 8),
        AppCard(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Column(
            children: [
              InfoRow(label: l10n.classroomsLevel, value: classroom.level),
              InfoRow(label: l10n.classroomsGrade, value: classroom.grade),
              InfoRow(label: l10n.classroomsBook, value: classroom.book),
              InfoRow(
                label: l10n.classroomsCommission,
                value: classroom.commission,
              ),
              InfoRow(
                label: l10n.classroomsYear,
                value: classroom.year,
                isLast: true,
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        SectionHeader(
            title: l10n.classroomsSectionLocation, padding: EdgeInsets.zero),
        const SizedBox(height: 8),
        AppCard(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Column(
            children: [
              InfoRow(label: l10n.classroomsBranch, value: classroom.branch),
              InfoRow(
                label: l10n.classroomsRoom,
                value: classroom.room,
                isLast: true,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
