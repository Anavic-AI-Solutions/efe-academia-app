import 'package:flutter/material.dart';

import '../../../../core/widgets/app_card.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../l10n/l10n.dart';
import '../../domain/qualification_model.dart';

class QualificationCard extends StatelessWidget {
  final QualificationModel qualification;

  const QualificationCard({
    super.key,
    required this.qualification,
  });

  Color _scoreColor() {
    if (qualification.score >= 7) return AppColors.success;
    if (qualification.score >= 4) return AppColors.warning;
    return AppColors.error;
  }

  @override
  Widget build(BuildContext context) {
    final color = _scoreColor();
    final l10n = context.l10n;

    return AppCard(
      margin: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                qualification.score.toStringAsFixed(1),
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  qualification.studentName.isNotEmpty
                      ? qualification.studentName
                      : l10n.qualificationsUnknownStudent,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  qualification.classroomName.isNotEmpty
                      ? qualification.classroomName
                      : l10n.qualificationsUnknownClassroom,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey,
                      ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (qualification.date.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    qualification.date,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey,
                          fontSize: 11,
                        ),
                  ),
                ],
              ],
            ),
          ),
          if (qualification.type.isNotEmpty) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                qualification.type,
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
