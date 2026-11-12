import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../app/theme/app_colors.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/error_view.dart';
import '../../../core/widgets/gradient_header.dart';
import '../../../core/widgets/header_stats_row.dart';
import '../../../core/widgets/home_header.dart';
import '../../../core/widgets/loading_shimmer.dart';
import '../../../core/widgets/section_header.dart';
import '../../../l10n/app_localizations.dart';
import '../../../l10n/l10n.dart';
import '../../auth/domain/user_model.dart';
import '../../auth/providers/auth_provider.dart';
import '../../notifications/providers/notification_provider.dart';
import '../domain/dashboard_data.dart';
import '../domain/professor_classroom_summary.dart';
import '../providers/dashboard_provider.dart';
import 'parent_home_screen.dart';
import 'professor_home_screen.dart';
import 'widgets/quick_action_grid.dart';
import '../../role_mode/widgets/mode_switch_chip.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final user = authState.user;

    if (user?.role == 'professor') {
      return const ProfessorHomeScreen();
    }

    if (user?.role == 'parent') {
      return const ParentHomeScreen();
    }

    final dashboardState = ref.watch(dashboardProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = context.l10n;

    if (dashboardState.isLoading && dashboardState.data == null) {
      return _buildLoading(isDark);
    }

    if (dashboardState.error != null && dashboardState.data == null) {
      return Scaffold(
        backgroundColor: AppColors.backgroundFor(isDark),
        body: SafeArea(
          child: ErrorView(
            message: l10n.dashboardLoadError,
            detail: dashboardState.error,
            onRetry: () => ref.read(dashboardProvider.notifier).refresh(),
          ),
        ),
      );
    }

    return _buildContent(context, ref, dashboardState.data, user, isDark);
  }

  Widget _buildLoading(bool isDark) {
    return Scaffold(
      backgroundColor: AppColors.backgroundFor(isDark),
      body: const Column(
        children: [
          GradientHeader(
            child: Column(
              children: [
                Row(
                  children: [
                    LoadingShimmer(width: 48, height: 48, borderRadius: 24),
                    SizedBox(width: 14),
                    LoadingShimmer(width: 140, height: 16),
                  ],
                ),
                SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(
                      child: LoadingShimmer(
                        width: double.infinity,
                        height: 78,
                        borderRadius: 14,
                      ),
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: LoadingShimmer(
                        width: double.infinity,
                        height: 78,
                        borderRadius: 14,
                      ),
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: LoadingShimmer(
                        width: double.infinity,
                        height: 78,
                        borderRadius: 14,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(child: ListShimmer()),
        ],
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    WidgetRef ref,
    DashboardData? data,
    UserModel? user,
    bool isDark,
  ) {
    final unreadCount = ref.watch(unreadCountProvider).valueOrNull ?? 0;
    final l10n = context.l10n;
    final classrooms = data?.classrooms ?? const <ProfessorClassroomSummary>[];

    final rawName = user?.name.trim() ?? '';
    final displayName = rawName.isEmpty ? l10n.commonUser : rawName;
    final firstName = rawName.isEmpty
        ? l10n.commonUser
        : rawName.split(' ').first;

    return Scaffold(
      backgroundColor: AppColors.backgroundFor(isDark),
      body: RefreshIndicator(
        onRefresh: () => ref.read(dashboardProvider.notifier).refresh(),
        child: ListView(
          padding: EdgeInsets.zero,
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            HomeHeader(
              badge: const ModeSwitchChip(),
              name: displayName,
              title: l10n.dashboardWelcome(firstName),
              avatarUrl: user?.avatarUrl,
              unreadCount: unreadCount,
              onNotifications: () => context.push('/notifications'),
              onSearch: () => context.push('/search'),
              child: HeaderStatsRow(
                stats: [
                  HeaderStat(
                    value: '${data?.totalStudents ?? 0}',
                    label: l10n.dashboardStudents,
                  ),
                  HeaderStat(
                    value: '${data?.totalClassrooms ?? 0}',
                    label: l10n.dashboardClassrooms,
                  ),
                  HeaderStat(
                    value: '${data?.pendingFees ?? 0}',
                    label: l10n.dashboardPendingFees,
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
                  _RoleBadge(
                    role: user?.role ?? '',
                    roleName: _getRoleName(user?.role ?? '', l10n),
                  ),
                  const SizedBox(height: 14),
                  SectionHeader(
                    title: l10n.classroomsTitle,
                    padding: EdgeInsets.zero,
                  ),
                  const SizedBox(height: 11),
                  if (classrooms.isEmpty)
                    EmptyState(
                      icon: PhosphorIconsRegular.chalkboardTeacher,
                      title: l10n.classroomsEmptyTitle,
                      subtitle: l10n.classroomsEmptySubtitle,
                    )
                  else
                    ...classrooms.map(
                      (classroom) => Padding(
                        padding: const EdgeInsets.only(bottom: 11),
                        child: _ParentClassroomCard(classroom: classroom),
                      ),
                    ),
                  const SizedBox(height: 14),
                  SectionHeader(
                    title: l10n.dashboardQuickActions,
                    padding: EdgeInsets.zero,
                  ),
                  const SizedBox(height: 11),
                  QuickActionGrid(
                    actions: [
                      QuickAction(
                        icon: PhosphorIconsRegular.chalkboardTeacher,
                        label: l10n.navClasses,
                        onTap: () => context.push('/classrooms'),
                      ),
                      QuickAction(
                        icon: PhosphorIconsRegular.users,
                        label: l10n.dashboardStudents,
                        onTap: () => context.push('/students'),
                      ),
                      QuickAction(
                        icon: PhosphorIconsRegular.bell,
                        label: l10n.profileNotifications,
                        onTap: () => context.push('/notifications'),
                      ),
                      QuickAction(
                        icon: PhosphorIconsRegular.newspaper,
                        label: l10n.dashboardNews,
                        onTap: () => context.push('/news'),
                      ),
                      QuickAction(
                        icon: PhosphorIconsRegular.calendarBlank,
                        label: l10n.dashboardEvents,
                        onTap: () => context.push('/events'),
                      ),
                      QuickAction(
                        icon: PhosphorIconsRegular.currencyDollar,
                        label: l10n.dashboardFees,
                        onTap: () => context.push('/fees'),
                      ),
                      QuickAction(
                        icon: PhosphorIconsRegular.chatCircle,
                        label: l10n.navChat,
                        onTap: () => context.push('/chat'),
                      ),
                      QuickAction(
                        icon: PhosphorIconsRegular.magnifyingGlass,
                        label: l10n.dashboardSearch,
                        onTap: () => context.push('/search'),
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

  String _getRoleName(String role, AppLocalizations l10n) {
    switch (role) {
      case 'admin':
        return l10n.roleAdmin;
      case 'branch':
        return l10n.roleBranch;
      case 'professor':
        return l10n.roleProfessor;
      case 'parent':
        return l10n.roleParent;
      case 'student':
        return l10n.roleStudent;
      default:
        return role.isNotEmpty ? role : l10n.commonUser;
    }
  }
}

class _RoleBadge extends StatelessWidget {
  final String role;
  final String roleName;

  const _RoleBadge({required this.role, required this.roleName});

  Color _color() {
    switch (role) {
      case 'admin':
        return AppColors.roleAdmin;
      case 'branch':
        return AppColors.roleBranch;
      case 'professor':
        return AppColors.roleProfessor;
      case 'student':
        return AppColors.roleStudent;
      case 'parent':
        return AppColors.roleParent;
      default:
        return AppColors.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _color();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        roleName,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}

class _ParentClassroomCard extends StatelessWidget {
  final ProfessorClassroomSummary classroom;

  const _ParentClassroomCard({required this.classroom});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AppCard(
      onTap: () => context.push('/classrooms/${classroom.id}'),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  classroom.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: isDark
                        ? AppColors.darkTextPrimary
                        : AppColors.lightInk,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  context.l10n.professorStudentsCount(classroom.studentsCount),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.mutedFor(isDark),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          const Icon(
            PhosphorIconsRegular.caretRight,
            size: 18,
            color: AppColors.primary,
          ),
        ],
      ),
    );
  }
}
