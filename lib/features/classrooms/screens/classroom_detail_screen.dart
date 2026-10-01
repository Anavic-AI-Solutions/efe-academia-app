import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../app/theme/professor_colors.dart';
import '../../../core/widgets/error_view.dart';
import '../../../core/widgets/gradient_header.dart';
import '../../../core/widgets/loading_shimmer.dart';
import '../../../l10n/app_localizations.dart';
import '../../../l10n/l10n.dart';
import '../../auth/domain/user_model.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/classroom_provider.dart';
import 'widgets/classroom_detail_header.dart';
import 'widgets/classroom_related_tabs.dart';
import 'widgets/classroom_summary_tab.dart';

class ClassroomDetailScreen extends ConsumerWidget {
  final String classroomId;

  const ClassroomDetailScreen({super.key, required this.classroomId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final classroomAsync = ref.watch(classroomDetailProvider(classroomId));
    final isProfessor = ref.watch(authProvider).user?.isProfessor ?? false;
    final background = isProfessor
        ? (isDark ? AppColors.darkBackground : ProfessorColors.surface)
        : null;

    return classroomAsync.when(
      loading: () => _buildLoading(context, isDark, isProfessor, l10n),
      error: (e, _) => _buildError(context, isDark, isProfessor, l10n, e, ref),
      data: (classroom) => DefaultTabController(
        length: 4,
        child: Scaffold(
          backgroundColor: background,
          body: Column(
            children: [
              ClassroomDetailHeader(
                classroom: classroom,
                isProfessor: isProfessor,
                onAttendance: () =>
                    context.push('/classrooms/$classroomId/attendance'),
                onGrades: () =>
                    context.push('/classrooms/$classroomId/grades'),
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
                  Tab(text: l10n.classroomsTabSummary),
                  Tab(text: l10n.classroomsTabStudents),
                  Tab(text: l10n.classroomsTabProfessors),
                  Tab(text: l10n.classroomsTabMaterials),
                ],
              ),
              Expanded(
                child: TabBarView(
                  children: [
                    ClassroomSummaryTab(
                      classroom: classroom,
                      isProfessor: isProfessor,
                    ),
                    ClassroomStudentsTab(
                      classroomId: classroomId,
                      isProfessor: isProfessor,
                    ),
                    ClassroomProfessorsTab(
                      classroomId: classroomId,
                      isProfessor: isProfessor,
                    ),
                    ClassroomMaterialsTab(
                      classroomId: classroomId,
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
            title: l10n.classroomsDetailTitle,
            subtitle: isProfessor ? 'Profesor' : null,
          ),
          Expanded(
            child: ListShimmer(itemCount: 5, itemHeight: 60),
          ),
        ],
      ),
    );
  }

  Widget _buildError(BuildContext context, bool isDark, bool isProfessor, AppLocalizations l10n, Object error, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppColors.backgroundFor(isDark),
      body: Column(
        children: [
          ScreenHeader(
            title: l10n.classroomsDetailTitle,
            subtitle: isProfessor ? 'Profesor' : null,
          ),
          Expanded(
            child: ErrorView(
              message: l10n.classroomsDetailLoadError,
              detail: error.toString(),
              accentColor: isProfessor ? ProfessorColors.primarySoft : null,
              onRetry: () => ref.invalidate(classroomDetailProvider(classroomId)),
            ),
          ),
        ],
      ),
    );
  }
}