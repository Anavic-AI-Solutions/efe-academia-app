import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/section_header.dart';
import '../../../../core/widgets/stat_card.dart';
import '../../../../l10n/l10n.dart';
import '../../domain/classroom_model.dart';

class ClassroomSummaryTab extends StatelessWidget {
  final ClassroomModel classroom;

  const ClassroomSummaryTab({super.key, required this.classroom});

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
                icon: PhosphorIconsRegular.users,
                value: '${classroom.studentCount}',
                label: l10n.classroomsStudents,
                iconColor: const Color(0xFF3B82F6),
              ),
              const SizedBox(width: 12),
              StatCard(
                icon: PhosphorIconsRegular.mapPin,
                value: classroom.room.isNotEmpty ? classroom.room : '—',
                label: l10n.classroomsRoom,
                iconColor: const Color(0xFF10B981),
              ),
              const SizedBox(width: 12),
              StatCard(
                icon: PhosphorIconsRegular.clock,
                value: classroom.shift.isNotEmpty ? classroom.shift : '—',
                label: l10n.classroomsShift,
                iconColor: const Color(0xFFF97316),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        if (classroom.description.isNotEmpty) ...[
          SectionHeader(title: l10n.classroomsDescription, padding: EdgeInsets.zero),
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
        SectionHeader(title: l10n.classroomsSectionSchedule, padding: EdgeInsets.zero),
        const SizedBox(height: 8),
        AppCard(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Column(
            children: [
              _InfoRow(label: l10n.classroomsShift, value: classroom.shift),
              _InfoRow(label: l10n.classroomsDay, value: classroom.day),
              _InfoRow(label: l10n.classroomsHour, value: classroom.hour),
              _InfoRow(
                label: l10n.classroomsCourseDays,
                value: classroom.courseDays > 0 ? '${classroom.courseDays}' : '',
                isLast: true,
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        SectionHeader(title: l10n.classroomsSectionAcademic, padding: EdgeInsets.zero),
        const SizedBox(height: 8),
        AppCard(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Column(
            children: [
              _InfoRow(label: l10n.classroomsLevel, value: classroom.level),
              _InfoRow(label: l10n.classroomsGrade, value: classroom.grade),
              _InfoRow(label: l10n.classroomsBook, value: classroom.book),
              _InfoRow(
                label: l10n.classroomsCommission,
                value: classroom.commission,
              ),
              _InfoRow(
                label: l10n.classroomsYear,
                value: classroom.year,
                isLast: true,
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        SectionHeader(title: l10n.classroomsSectionLocation, padding: EdgeInsets.zero),
        const SizedBox(height: 8),
        AppCard(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Column(
            children: [
              _InfoRow(label: l10n.classroomsBranch, value: classroom.branch),
              _InfoRow(
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

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isLast;

  const _InfoRow({
    required this.label,
    required this.value,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 4,
                child: Text(
                  label,
                  style: AppTypography.bodySmall.copyWith(
                    color: isDark
                        ? AppColors.darkTextTertiary
                        : AppColors.lightTextTertiary,
                  ),
                ),
              ),
              Expanded(
                flex: 6,
                child: Text(
                  value.isNotEmpty ? value : '—',
                  textAlign: TextAlign.right,
                  style: AppTypography.titleSmall.copyWith(
                    color: isDark
                        ? AppColors.darkTextPrimary
                        : AppColors.lightTextPrimary,
                  ),
                ),
              ),
            ],
          ),
        ),
        if (!isLast)
          Divider(
            height: 1,
            indent: 16,
            endIndent: 16,
            color: isDark ? AppColors.darkDivider : AppColors.lightDivider,
          ),
      ],
    );
  }
}
