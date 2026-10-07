import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/utils/status_labels.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/status_badge.dart';
import '../../../../l10n/l10n.dart';
import '../../domain/classroom_model.dart';

class ProfessorClassroomListCard extends StatelessWidget {
  final ClassroomModel classroom;
  final VoidCallback onTap;

  const ProfessorClassroomListCard({
    super.key,
    required this.classroom,
    required this.onTap,
  });

  String get _schedule => [classroom.shift, classroom.day, classroom.hour]
      .where((value) => value.isNotEmpty)
      .join(' · ');

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = context.l10n;
    final status = classroom.status.toLowerCase();

    return AppCard(
      onTap: onTap,
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.10),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              PhosphorIconsRegular.chalkboardTeacher,
              size: 20,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  classroom.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: isDark
                        ? AppColors.darkTextPrimary
                        : AppColors.lightInk,
                  ),
                ),
                if (_schedule.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(
                    _schedule,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.mutedFor(isDark),
                    ),
                  ),
                ],
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(
                      PhosphorIconsRegular.mapPin,
                      size: 13,
                      color: AppColors.mutedFor(isDark),
                    ),
                    const SizedBox(width: 3),
                    Flexible(
                      child: Text(
                        classroom.room.isNotEmpty ? classroom.room : '—',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.mutedFor(isDark),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Icon(
                      PhosphorIconsRegular.users,
                      size: 13,
                      color: AppColors.mutedFor(isDark),
                    ),
                    const SizedBox(width: 3),
                    Text(
                      '${classroom.studentCount}',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.mutedFor(isDark),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (status.isNotEmpty)
                StatusBadge(status: classroomStatusLabel(status, l10n)),
              const SizedBox(height: 8),
              Icon(
                PhosphorIconsRegular.caretRight,
                size: 16,
                color: AppColors.mutedFor(isDark),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
