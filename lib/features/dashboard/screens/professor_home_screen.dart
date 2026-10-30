import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../app/theme/app_colors.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/error_view.dart';
import '../../../core/widgets/gradient_header.dart';
import '../../../core/widgets/header_stats_row.dart';
import '../../../core/widgets/home_header.dart';
import '../../../core/widgets/loading_shimmer.dart';
import '../../../l10n/l10n.dart';
import '../../auth/providers/auth_provider.dart';
import '../../birthdays/providers/birthday_provider.dart';
import '../../documents/providers/document_provider.dart';
import '../../events/providers/event_provider.dart';
import '../../news/providers/news_provider.dart';
import '../../notifications/providers/notification_provider.dart';
import '../domain/professor_classroom_summary.dart';
import '../providers/dashboard_provider.dart';
import 'widgets/home_summary_grid.dart';
import 'widgets/professor_classroom_card.dart';

class ProfessorHomeScreen extends ConsumerStatefulWidget {
  const ProfessorHomeScreen({super.key});

  @override
  ConsumerState<ProfessorHomeScreen> createState() =>
      _ProfessorHomeScreenState();
}

class _ProfessorHomeScreenState extends ConsumerState<ProfessorHomeScreen> {
  String? _selectedClassroomId;

  @override
  Widget build(BuildContext context) {
    final dashboardState = ref.watch(dashboardProvider);
    final user = ref.watch(authProvider).user;
    final unreadCount = ref.watch(unreadCountProvider).valueOrNull ?? 0;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = context.l10n;

    if (dashboardState.isLoading && dashboardState.data == null) {
      return _buildLoading(context, isDark);
    }

    if (dashboardState.error != null && dashboardState.data == null) {
      return ErrorView(
        message: l10n.professorLoadError,
        detail: dashboardState.error,
        onRetry: () => ref.read(dashboardProvider.notifier).refresh(),
      );
    }

    final data = dashboardState.data;
    final classrooms = data?.classrooms ?? const <ProfessorClassroomSummary>[];
    final selectedId = _selectedClassroomId ??
        (classrooms.isNotEmpty ? classrooms.first.id : null);

    return Scaffold(
      backgroundColor: AppColors.backgroundFor(isDark),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(homeCalendarProvider);
          ref.invalidate(todayBirthdaysProvider);
          ref.invalidate(homeDocumentsProvider);
          await Future.wait([
            ref.read(dashboardProvider.notifier).refresh(),
            ref.read(newsListProvider.notifier).refresh(),
          ]);
        },
        child: ListView(
          padding: EdgeInsets.zero,
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            HomeHeader(
              name: user?.name ?? '',
              avatarUrl: user?.avatarUrl,
              unreadCount: unreadCount,
              onNotifications: () => context.push('/notifications'),
              onSearch: () => context.push('/search'),
              child: HeaderStatsRow(
                stats: [
                  HeaderStat(
                    value: '${data?.totalClassrooms ?? 0}',
                    label: l10n.professorStatClassrooms,
                  ),
                  HeaderStat(
                    value: '${data?.totalStudents ?? 0}',
                    label: l10n.professorStatStudents,
                  ),
                  HeaderStat(
                    value: '${data?.absencesToday ?? 0}',
                    label: l10n.professorStatAbsences,
                    highlighted: true,
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const HomeSummaryGrid(),
                  const SizedBox(height: 16),
                  Text(
                    l10n.professorMyClassrooms.toUpperCase(),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.6,
                      color: AppColors.sectionLabel,
                    ),
                  ),
                  const SizedBox(height: 11),
                  if (classrooms.isEmpty)
                    EmptyState(
                      icon: PhosphorIconsRegular.chalkboardTeacher,
                      title: l10n.professorMyClassroomsEmpty,
                    )
                  else
                    ...classrooms.map(
                      (classroom) => Padding(
                        padding: const EdgeInsets.only(bottom: 11),
                        child: ProfessorClassroomCard(
                          name: classroom.name,
                          studentsCount: classroom.studentsCount,
                          isSelected: classroom.id == selectedId,
                          onTap: () => setState(
                            () => _selectedClassroomId = classroom.id,
                          ),
                        ),
                      ),
                    ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: _ProfessorActionButton(
                          label: l10n.professorTakeAttendance,
                          color: AppColors.primary,
                          onPressed: selectedId == null
                              ? null
                              : () => context.go(
                                    '/classrooms/$selectedId/attendance',
                                  ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _ProfessorActionButton(
                          label: l10n.professorLoadGrade,
                          color: AppColors.primarySoft,
                          onPressed: selectedId == null
                              ? null
                              : () => context.go(
                                    '/classrooms/$selectedId/grades',
                                  ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoading(BuildContext context, bool isDark) {
    return Scaffold(
      backgroundColor: AppColors.backgroundFor(isDark),
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          GradientHeader(
            child: const Column(
              children: [
                Row(
                  children: [
                    LoadingShimmer(width: 36, height: 36, borderRadius: 18),
                    SizedBox(width: 10),
                    LoadingShimmer(width: 140, height: 14),
                  ],
                ),
                SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: LoadingShimmer(
                        width: double.infinity,
                        height: 46,
                        borderRadius: 12,
                      ),
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: LoadingShimmer(
                        width: double.infinity,
                        height: 46,
                        borderRadius: 12,
                      ),
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: LoadingShimmer(
                        width: double.infinity,
                        height: 46,
                        borderRadius: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              children: [
                LoadingShimmer(
                  width: double.infinity,
                  height: 68,
                  borderRadius: 16,
                ),
                SizedBox(height: 11),
                LoadingShimmer(
                  width: double.infinity,
                  height: 68,
                  borderRadius: 16,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfessorActionButton extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback? onPressed;

  const _ProfessorActionButton({
    required this.label,
    required this.color,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          disabledBackgroundColor: color.withOpacity(0.4),
          disabledForegroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(13),
          ),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800),
        ),
      ),
    );
  }
}
