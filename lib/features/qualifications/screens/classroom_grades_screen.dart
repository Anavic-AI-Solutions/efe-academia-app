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
import '../domain/classroom_grades_summary.dart';
import '../providers/qualification_provider.dart';
import 'widgets/grade_student_row.dart';
import 'widgets/qualification_form_sheet.dart';

class ClassroomGradesScreen extends ConsumerWidget {
  final String classroomId;

  const ClassroomGradesScreen({super.key, required this.classroomId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final provider = classroomGradesProvider(classroomId);
    final summaryAsync = ref.watch(provider);
    final summary = summaryAsync.valueOrNull;
    final l10n = context.l10n;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hasStudents = (summary?.students.isNotEmpty) ?? false;

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.darkBackground : AppColors.lightBackground,
      body: Column(
        children: [
          ScreenHeader(
            title: l10n.gradesTitle,
            subtitle: summary?.classroomName,
            onBack: () => _leave(context),
            child: _AverageBox(average: summary?.classroomAverage),
          ),
          Expanded(
            child: summaryAsync.when(
              data: (data) => data.students.isEmpty
                  ? EmptyState(
                      icon: PhosphorIconsRegular.users,
                      title: l10n.attendanceEmpty,
                    )
                  : RefreshIndicator(
                      onRefresh: () => ref.refresh(provider.future),
                      child: ListView.separated(
                        padding: const EdgeInsets.fromLTRB(14, 13, 14, 13),
                        physics: const AlwaysScrollableScrollPhysics(),
                        itemCount: data.students.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 9),
                        itemBuilder: (context, index) {
                          final student = data.students[index];

                          return GradeStudentRow(
                            fullname: student.fullname,
                            average: student.average,
                          );
                        },
                      ),
                    ),
              loading: () => ListView.separated(
                padding: const EdgeInsets.fromLTRB(14, 13, 14, 13),
                itemCount: 6,
                separatorBuilder: (_, __) => const SizedBox(height: 9),
                itemBuilder: (_, __) => const LoadingShimmer(
                  width: double.infinity,
                  height: 44,
                  borderRadius: 13,
                ),
              ),
              error: (error, _) => ErrorView(
                message: l10n.gradesLoadError,
                detail: error.toString(),
                onRetry: () => ref.invalidate(provider),
              ),
            ),
          ),
          if (summary != null && hasStudents)
            _LoadGradeBar(
              onTap: () => _openCreateSheet(context, summary),
            ),
        ],
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

  Future<void> _openCreateSheet(
    BuildContext context,
    ClassroomGradesSummary summary,
  ) async {
    final result = await showModalBottomSheet<QualificationFormResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => QualificationFormSheet(
        classroomId: classroomId,
        students: summary.students,
      ),
    );

    if (result == QualificationFormResult.saved && context.mounted) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(context.l10n.gradeFormSaved)));
    }
  }
}

class _AverageBox extends StatelessWidget {
  final double? average;

  const _AverageBox({this.average});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.overlay,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            context.l10n.gradesClassroomAverage,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppColors.onPrimaryMuted,
            ),
          ),
          Text(
            AppColors.formatGrade(average),
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: AppColors.onPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

class _LoadGradeBar extends StatelessWidget {
  final VoidCallback onTap;

  const _LoadGradeBar({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 8, 14, 12),
        child: SizedBox(
          height: 46,
          width: double.infinity,
          child: ElevatedButton(
            onPressed: onTap,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(13),
              ),
            ),
            child: Text(
              context.l10n.gradesLoadGrade,
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
