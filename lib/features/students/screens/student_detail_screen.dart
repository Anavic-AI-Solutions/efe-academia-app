import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../core/widgets/error_view.dart';
import '../../../core/widgets/gradient_header.dart';
import '../../../core/widgets/loading_shimmer.dart';
import '../../../l10n/app_localizations.dart';
import '../../../l10n/l10n.dart';
import '../../auth/domain/user_model.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/student_provider.dart';
import 'widgets/student_detail_header.dart';
import 'widgets/student_info_tab.dart';
import 'widgets/student_parents_tab.dart';
import 'widgets/student_related_tabs.dart';
import 'widgets/student_request_tab.dart';

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
    final user = ref.watch(authProvider).user;
    final isProfessor = user?.isProfessor ?? false;
    final canManageQualifications = user?.canManageQualifications ?? false;
    final role = user?.role ?? '';
    final showRequestTabs =
        role == 'admin' || role == 'branch' || role == 'sede';
    final accent = AppColors.accentFor(isDark);

    return studentAsync.when(
      loading: () => _buildLoading(context, isDark, l10n),
      error: (e, _) => _buildError(context, isDark, l10n, e, ref),
      data: (student) => DefaultTabController(
        key: ValueKey('student-tabs-$showRequestTabs'),
        length: showRequestTabs ? 6 : 4,
        child: Scaffold(
          backgroundColor: AppColors.backgroundFor(isDark),
          body: Column(
            children: [
              StudentDetailHeader(
                student: student,
              ),
              TabBar(
                isScrollable: true,
                tabAlignment: TabAlignment.start,
                labelPadding: const EdgeInsets.symmetric(horizontal: 8),
                labelColor: accent,
                unselectedLabelColor: isDark
                    ? AppColors.darkTextSecondary
                    : AppColors.lightTextSecondary,
                indicatorColor: accent,
                labelStyle: AppTypography.titleSmall,
                unselectedLabelStyle: AppTypography.titleSmall,
                tabs: [
                  Tab(text: l10n.studentsTabGrades),
                  Tab(text: l10n.studentsTabAbsences),
                  Tab(text: l10n.studentsTabFees),
                  Tab(text: l10n.studentsTabInfo),
                  if (showRequestTabs) ...[
                    Tab(text: l10n.studentsTabRequest),
                    Tab(text: l10n.studentsTabParents),
                  ],
                ],
              ),
              Expanded(
                child: TabBarView(
                  children: [
                    StudentGradesTab(
                      studentId: studentId,
                      classroomId: classroomId,
                      canWrite: canManageQualifications,
                      studentFullname: student.fullname,
                    ),
                    StudentAbsencesTab(
                      studentId: studentId,
                      classroomId: classroomId,
                      canWrite: isProfessor,
                    ),
                    StudentFeesTab(
                      studentId: studentId,
                    ),
                    StudentInfoTab(
                      student: student,
                    ),
                    if (showRequestTabs) ...[
                      StudentRequestTab(student: student),
                      StudentParentsTab(student: student),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoading(
      BuildContext context, bool isDark, AppLocalizations l10n) {
    return Scaffold(
      backgroundColor: AppColors.backgroundFor(isDark),
      body: Column(
        children: [
          ScreenHeader(
            title: l10n.studentsDetailFallbackTitle,
          ),
          Expanded(
            child: ListShimmer(itemCount: 5, itemHeight: 60),
          ),
        ],
      ),
    );
  }

  Widget _buildError(BuildContext context, bool isDark, AppLocalizations l10n,
      Object error, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppColors.backgroundFor(isDark),
      body: Column(
        children: [
          ScreenHeader(
            title: l10n.studentsDetailFallbackTitle,
          ),
          Expanded(
            child: ErrorView(
              message: l10n.studentsDetailLoadError,
              detail: error.toString(),
              onRetry: () => ref.invalidate(studentDetailProvider(studentId)),
            ),
          ),
        ],
      ),
    );
  }
}
