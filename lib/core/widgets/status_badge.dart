import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_typography.dart';

class StatusBadge extends StatelessWidget {
  final String status;
  final String? label;
  final Color? color;

  const StatusBadge({super.key, required this.status, this.label, this.color});

  static Color colorFor(String status) {
    switch (status.toLowerCase()) {
      case 'active':
      case 'paid':
      case 'approved':
        return AppColors.success;
      case 'inactive':
      case 'archived':
      case 'overdue':
      case 'rejected':
        return AppColors.error;
      case 'pending':
      case 'partial':
      case 'unjustified':
        return AppColors.warning;
      case 'justified':
        return AppColors.success;
      default:
        return AppColors.lightTextTertiary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final badgeColor = color ?? colorFor(status);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: badgeColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label ?? status,
        style: AppTypography.labelSmall.copyWith(
          color: badgeColor,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
