import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
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
    final accent = AppColors.accentFor(isDark);

    return classroomAsync.when(
      loading: () => _buildLoading(context, isDark, l10n),
      error: (e, _) => _buildError(context, isDark, l10n, e, ref),
      data: (classroom) => DefaultTabController(
        length: 4,
        child: Scaffold(
          backgroundColor: AppColors.backgroundFor(isDark),
          body: Column(
            children: [
              ClassroomDetailHeader(
                classroom: classroom,
                showActions: isProfessor,
                onAttendance: () =>
                    context.push('/classrooms/$classroomId/attendance'),
                onGrades: () =>
                    context.push('/classrooms/$classroomId/grades'),
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
                    ),
                    ClassroomStudentsTab(
                      classroomId: classroomId,
                    ),
                    ClassroomProfessorsTab(
                      classroomId: classroomId,
                    ),
                    ClassroomMaterialsTab(
                      classroomId: classroomId,
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

  Widget _buildLoading(BuildContext context, bool isDark, AppLocalizations l10n) {
    return Scaffold(
      backgroundColor: AppColors.backgroundFor(isDark),
      body: Column(
        children: [
          ScreenHeader(
            title: l10n.classroomsDetailTitle,
          ),
          Expanded(
            child: ListShimmer(itemCount: 5, itemHeight: 60),
          ),
        ],
      ),
    );
  }

  Widget _buildError(BuildContext context, bool isDark, AppLocalizations l10n, Object error, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppColors.backgroundFor(isDark),
      body: Column(
        children: [
          ScreenHeader(
            title: l10n.classroomsDetailTitle,
          ),
          Expanded(
            child: ErrorView(
              message: l10n.classroomsDetailLoadError,
              detail: error.toString(),
              onRetry: () => ref.invalidate(classroomDetailProvider(classroomId)),
            ),
          ),
        ],
      ),
    );
  }
}