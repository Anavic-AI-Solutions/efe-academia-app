import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../core/widgets/error_view.dart';
import '../../../core/widgets/loading_shimmer.dart';
import '../../../l10n/l10n.dart';
import '../providers/student_provider.dart';
import 'widgets/student_detail_header.dart';
import 'widgets/student_info_tab.dart';

class StudentDetailScreen extends ConsumerWidget {
  final String studentId;

  const StudentDetailScreen({super.key, required this.studentId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final studentAsync = ref.watch(studentDetailProvider(studentId));

    return studentAsync.when(
      loading: () => Scaffold(
        appBar: AppBar(title: Text(l10n.studentsDetailFallbackTitle)),
        body: const ListShimmer(itemCount: 5, itemHeight: 60),
      ),
      error: (e, _) => Scaffold(
        appBar: AppBar(title: Text(l10n.studentsDetailFallbackTitle)),
        body: ErrorView(
          message: l10n.studentsDetailLoadError,
          detail: e.toString(),
          onRetry: () => ref.invalidate(studentDetailProvider(studentId)),
        ),
      ),
      data: (student) => DefaultTabController(
        length: 4,
        child: Scaffold(
          body: Column(
            children: [
              StudentDetailHeader(student: student),
              TabBar(
                isScrollable: true,
                tabAlignment: TabAlignment.start,
                labelPadding: const EdgeInsets.symmetric(horizontal: 8),
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
                  Tab(text: l10n.studentsTabGrades),
                  Tab(text: l10n.studentsTabAbsences),
                  Tab(text: l10n.studentsTabFees),
                  Tab(text: l10n.studentsTabInfo),
                ],
              ),
              Expanded(
                child: TabBarView(
                  children: [
                    _PlaceholderTab(message: l10n.studentsNoGrades),
                    _PlaceholderTab(message: l10n.studentsNoAbsences),
                    _PlaceholderTab(message: l10n.studentsNoFees),
                    StudentInfoTab(student: student),
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
