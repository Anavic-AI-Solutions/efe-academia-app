import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../l10n/l10n.dart';
import '../../domain/attendance_day.dart';

class AttendanceStudentRow extends StatelessWidget {
  final AttendanceStudent student;
  final VoidCallback onToggle;

  const AttendanceStudentRow({
    super.key,
    required this.student,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final isAbsent = student.isAbsent;
    final l10n = context.l10n;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(13),
        boxShadow: [
          BoxShadow(
            color: (isAbsent ? AppColors.absent : const Color(0xFF28325A))
                .withOpacity(0.24),
            blurRadius: 20,
            offset: const Offset(0, 8),
            spreadRadius: -14,
          ),
        ],
        border: Border.all(
          color: isAbsent
              ? AppColors.absent.withOpacity(0.35)
              : Colors.transparent,
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          _StudentAvatar(name: student.fullname, isAbsent: isAbsent),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              student.fullname,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.lightInk,
              ),
            ),
          ),
          _StatusToggle(
            label: l10n.attendancePresent,
            isActive: !isAbsent,
            activeColor: AppColors.present,
            onTap: isAbsent ? onToggle : null,
          ),
          const SizedBox(width: 3),
          _StatusToggle(
            label: l10n.attendanceAbsent,
            isActive: isAbsent,
            activeColor: AppColors.absent,
            onTap: isAbsent ? null : onToggle,
          ),
        ],
      ),
    );
  }
}

class _StudentAvatar extends StatelessWidget {
  final String name;
  final bool isAbsent;

  const _StudentAvatar({required this.name, required this.isAbsent});

  String get _initials {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return '?';
    final parts = trimmed.split(RegExp(r'\s+'));
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts[0][0]}${parts[parts.length - 1][0]}'.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 26,
      height: 26,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: isAbsent ? const Color(0xFFF6DEDE) : const Color(0xFFE3E7F5),
        shape: BoxShape.circle,
      ),
      child: Text(
        _initials,
        style: const TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w800,
          color: AppColors.lightInk,
        ),
      ),
    );
  }
}

class _StatusToggle extends StatelessWidget {
  final String label;
  final bool isActive;
  final Color activeColor;
  final VoidCallback? onTap;

  const _StatusToggle({
    required this.label,
    required this.isActive,
    required this.activeColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        width: 34,
        height: 28,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isActive ? activeColor : const Color(0xFFEEF0F6),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: isActive ? FontWeight.w800 : FontWeight.w700,
            color: isActive ? Colors.white : AppColors.navInactive,
          ),
        ),
      ),
    );
  }
}
