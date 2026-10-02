import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../app/theme/professor_colors.dart';
import '../../../core/widgets/error_view.dart';
import '../../../core/widgets/gradient_header.dart';
import '../../../core/widgets/loading_shimmer.dart';
import '../../../core/widgets/screen_header.dart';
import '../../../l10n/l10n.dart';
import '../../auth/domain/user_model.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/student_provider.dart';
import 'widgets/student_detail_header.dart';
import 'widgets/student_info_tab.dart';
import 'widgets/student_related_tabs.dart';

class StudentDetailScreen extends ConsumerWidget {
  final String studentId;
  final String? classroomId;

  const StudentDetailScreen({
    super.key,
    required this.studentId,
    this.classroomId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final studentAsync = ref.watch(studentDetailProvider(studentId));
    final isProfessor = ref.watch(authProvider).user?.isProfessor ?? false;
    final background = isProfessor
        ? (isDark ? AppColors.darkBackground : ProfessorColors.surface)
        : null;

    return studentAsync.when(
      loading: () => _buildLoading(context, isDark, isProfessor, l10n),
      error: (e, _) => _buildError(context, isDark, isProfessor, l10n, e),
      data: (student) => DefaultTabController(
        length: 4,
        child: Scaffold(
          backgroundColor: background,
          body: Column(
            children: [
              StudentDetailHeader(
                student: student,
                isProfessor: isProfessor,
              ),
              TabBar(
                isScrollable: true,
                tabAlignment: TabAlignment.start,
                labelPadding: const EdgeInsets.symmetric(horizontal: 8),
                labelColor: isProfessor
                    ? ProfessorColors.primary
                    : (isDark ? const Color(0xFF6366F1) : AppColors.primary),
                unselectedLabelColor: isDark
                    ? AppColors.darkTextSecondary
                    : AppColors.lightTextSecondary,
                indicatorColor: isProfessor
                    ? ProfessorColors.primary
                    : (isDark ? const Color(0xFF6366F1) : AppColors.primary),
                labelStyle: AppTypography.titleSmall,
                unselectedLabelStyle: AppTypography.titleSmall,
                tabs: [
                  Tab(text: l10n.studentsTabGrades),
                  Tab(text: l10n.studentsTabAbsences),
                  Tab(text: l10n.studentsTabFees),
                  Tab(text: l10n.studentsTabInfo),
                ],
              ),
              Expanded(
                child: TabBarView(
                  children: [
                    StudentGradesTab(
                      studentId: studentId,
                      classroomId: classroomId,
                      isProfessor: isProfessor,
                    ),
                    StudentAbsencesTab(
                      studentId: studentId,
                      isProfessor: isProfessor,
                    ),
                    StudentFeesTab(
                      studentId: studentId,
                      isProfessor: isProfessor,
                    ),
                    StudentInfoTab(
                      student: student,
                      isProfessor: isProfessor,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoading(BuildContext context, bool isDark, bool isProfessor, AppLocalizations l10n) {
    return Scaffold(
      backgroundColor: AppColors.backgroundFor(isDark),
      body: Column(
        children: [
          ScreenHeader(
            title: l10n.studentsDetailFallbackTitle,
            subtitle: isProfessor ? 'Profesor' : null,
          ),
          Expanded(
            child: ListShimmer(itemCount: 5, itemHeight: 60),
          ),
        ],
      ),
    );
  }

  Widget _buildError(BuildContext context, bool isDark, bool isProfessor, AppLocalizations l10n, Object error) {
    return Scaffold(
      backgroundColor: AppColors.backgroundFor(isDark),
      body: Column(
        children: [
          ScreenHeader(
            title: l10n.studentsDetailFallbackTitle,
            subtitle: isProfessor ? 'Profesor' : null,
          ),
          Expanded(
            child: ErrorView(
              message: l10n.studentsDetailLoadError,
              detail: error.toString(),
              accentColor: isProfessor ? ProfessorColors.primarySoft : null,
              onRetry: () => ref.invalidate(studentDetailProvider(studentId)),
            ),
          ),
        ],
      ),
    );
  }
}