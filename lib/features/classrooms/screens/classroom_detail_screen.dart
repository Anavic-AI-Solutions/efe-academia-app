import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../core/widgets/error_view.dart';
import '../../../core/widgets/loading_shimmer.dart';
import '../../../l10n/l10n.dart';
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
    final background = AppColors.backgroundFor(isDark);

    return classroomAsync.when(
      loading: () => Scaffold(
        backgroundColor: background,
        appBar: AppBar(title: Text(l10n.classroomsDetailTitle)),
        body: const ListShimmer(itemCount: 5, itemHeight: 60),
      ),
      error: (e, _) => Scaffold(
        backgroundColor: background,
        appBar: AppBar(title: Text(l10n.classroomsDetailTitle)),
        body: ErrorView(
          message: l10n.classroomsDetailLoadError,
          detail: e.toString(),
          onRetry: () => ref.invalidate(classroomDetailProvider(classroomId)),
        ),
      ),
      data: (classroom) => DefaultTabController(
        length: 4,
        child: Scaffold(
          backgroundColor: background,
          body: Column(
            children: [
              ClassroomDetailHeader(
                classroom: classroom,
                onAttendance: () =>
                    context.push('/classrooms/$classroomId/attendance'),
                onGrades: () =>
                    context.push('/classrooms/$classroomId/grades'),
              ),
              TabBar(
                isScrollable: true,
                tabAlignment: TabAlignment.start,
                labelPadding: const EdgeInsets.symmetric(horizontal: 8),
                labelColor: AppColors.accentFor(isDark),
                unselectedLabelColor: isDark
                    ? AppColors.darkTextSecondary
                    : AppColors.lightTextSecondary,
                indicatorColor: AppColors.accentFor(isDark),
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
}
