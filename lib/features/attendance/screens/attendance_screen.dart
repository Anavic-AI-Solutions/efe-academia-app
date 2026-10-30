import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../app/theme/app_colors.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/error_view.dart';
import '../../../core/widgets/gradient_header.dart';
import '../../../core/widgets/loading_shimmer.dart';
import '../../../l10n/l10n.dart';
import '../domain/attendance_day.dart';
import '../providers/attendance_provider.dart';
import 'widgets/attendance_student_row.dart';

const _monthsEs = [
  'ene',
  'feb',
  'mar',
  'abr',
  'may',
  'jun',
  'jul',
  'ago',
  'sep',
  'oct',
  'nov',
  'dic',
];
const _monthsEn = [
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Oct',
  'Nov',
  'Dec',
];

String _dateLabel(BuildContext context, String date) {
  final parsed = DateTime.tryParse(date);
  if (parsed == null) return date;

  final isSpanish = Localizations.localeOf(context).languageCode != 'en';
  final months = isSpanish ? _monthsEs : _monthsEn;
  final now = DateTime.now();
  final isToday = parsed.year == now.year &&
      parsed.month == now.month &&
      parsed.day == now.day;
  final monthLabel = months[parsed.month - 1];

  if (isToday) {
    return '${context.l10n.attendanceToday}, ${parsed.day} $monthLabel';
  }

  return '${parsed.day} $monthLabel';
}

class AttendanceScreen extends ConsumerWidget {
  final String classroomId;

  const AttendanceScreen({super.key, required this.classroomId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final provider = attendanceProvider(classroomId);
    final state = ref.watch(provider);
    final l10n = context.l10n;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    ref.listen(provider, (previous, next) {
      if (next.saved && previous?.saved != true) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(l10n.attendanceSaved)));
      }
      if (next.saveError != null && previous?.saveError != next.saveError) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(l10n.attendanceSaveError)));
      }
    });

    final day = state.day;

    return PopScope(
      canPop: !state.hasChanges,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          _confirmLeave(context, ref, state.hasChanges);
        }
      },
      child: Scaffold(
        backgroundColor:
            isDark ? AppColors.darkBackground : AppColors.lightBackground,
        body: Column(
          children: [
            ScreenHeader(
              title: l10n.attendanceTitle(day?.classroomName ?? ''),
              subtitle: l10n.attendanceSubtitle(
                _dateLabel(context, day?.date ?? ''),
                day?.studentsCount ?? 0,
              ),
              onBack: () {
                if (state.hasChanges) {
                  _confirmLeave(context, ref, true);
                } else {
                  _leave(context);
                }
              },
            ),
            Expanded(
              child: _buildBody(context, ref, state, day, isDark),
            ),
            if (day != null && day.students.isNotEmpty)
              _SaveBar(
                isSaving: state.isSaving,
                onSave: () => ref.read(provider.notifier).save(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    WidgetRef ref,
    AttendanceState state,
    AttendanceDay? day,
    bool isDark,
  ) {
    final l10n = context.l10n;

    if (state.isLoading && day == null) {
      return ListView.separated(
        padding: const EdgeInsets.fromLTRB(14, 13, 14, 13),
        itemCount: 6,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (_, __) => const LoadingShimmer(
            width: double.infinity, height: 50, borderRadius: 13),
      );
    }

    if (state.error != null && day == null) {
      return ErrorView(
        message: l10n.attendanceLoadError,
        detail: state.error,
        onRetry: () =>
            ref.read(attendanceProvider(classroomId).notifier).load(),
      );
    }

    final students = day?.students ?? const <AttendanceStudent>[];

    if (students.isEmpty) {
      return EmptyState(
        icon: PhosphorIconsRegular.users,
        title: l10n.attendanceEmpty,
      );
    }

    return RefreshIndicator(
      onRefresh: () =>
          ref.read(attendanceProvider(classroomId).notifier).load(),
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(14, 13, 14, 13),
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: students.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (context, index) {
          final student = students[index];

          return AttendanceStudentRow(
            student: student,
            onToggle: () => ref
                .read(attendanceProvider(classroomId).notifier)
                .toggle(student.id),
          );
        },
      ),
    );
  }

  void _leave(BuildContext context) {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/dashboard');
    }
  }

  Future<void> _confirmLeave(
    BuildContext context,
    WidgetRef ref,
    bool hasChanges,
  ) async {
    if (!hasChanges) {
      _leave(context);
      return;
    }

    final l10n = context.l10n;
    final leave = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.attendanceUnsavedTitle),
        content: Text(l10n.attendanceUnsavedMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l10n.attendanceUnsavedStay),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(l10n.attendanceUnsavedLeave),
          ),
        ],
      ),
    );

    if (leave == true && context.mounted) {
      // Programmatic pop ignores the PopScope guard.
      _leave(context);
    }
  }
}

class _SaveBar extends StatelessWidget {
  final bool isSaving;
  final VoidCallback onSave;

  const _SaveBar({required this.isSaving, required this.onSave});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 8, 14, 12),
        color: Colors.transparent,
        child: SizedBox(
          height: 46,
          width: double.infinity,
          child: ElevatedButton(
            onPressed: isSaving ? null : onSave,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              disabledBackgroundColor: AppColors.primary.withOpacity(0.5),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(13),
              ),
            ),
            child: isSaving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Text(
                    context.l10n.attendanceSave,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}
