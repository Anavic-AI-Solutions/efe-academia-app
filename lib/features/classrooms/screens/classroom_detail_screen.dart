import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../core/widgets/error_view.dart';
import '../../../core/widgets/loading_shimmer.dart';
import '../../../l10n/l10n.dart';
import '../providers/classroom_provider.dart';
import 'widgets/classroom_detail_header.dart';
import 'widgets/classroom_summary_tab.dart';

class ClassroomDetailScreen extends ConsumerWidget {
  final String classroomId;

  const ClassroomDetailScreen({super.key, required this.classroomId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final classroomAsync = ref.watch(classroomDetailProvider(classroomId));

    return classroomAsync.when(
      loading: () => Scaffold(
        appBar: AppBar(title: Text(l10n.classroomsDetailTitle)),
        body: const ListShimmer(itemCount: 5, itemHeight: 60),
      ),
      error: (e, _) => Scaffold(
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
          body: Column(
            children: [
              ClassroomDetailHeader(classroom: classroom),
              TabBar(
                isScrollable: true,
                tabAlignment: TabAlignment.start,
                labelColor:
                    isDark ? const Color(0xFF6366F1) : AppColors.primary,
                unselectedLabelColor: isDark
                    ? AppColors.darkTextSecondary
                    : AppColors.lightTextSecondary,
                indicatorColor:
                    isDark ? const Color(0xFF6366F1) : AppColors.primary,
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
                    ClassroomSummaryTab(classroom: classroom),
                    _PlaceholderTab(message: l10n.classroomsNoStudents),
                    _PlaceholderTab(message: l10n.classroomsNoProfessors),
                    _PlaceholderTab(message: l10n.classroomsNoMaterials),
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

class _PlaceholderTab extends StatelessWidget {
  final String message;

  const _PlaceholderTab({required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        message,
        style: const TextStyle(color: Colors.grey),
      ),
    );
  }
}
