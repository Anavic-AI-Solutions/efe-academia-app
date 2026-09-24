import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../auth/providers/auth_provider.dart';
import '../../../core/widgets/avatar.dart';
import '../../../core/widgets/error_view.dart';
import '../../../core/widgets/loading_shimmer.dart';
import '../../../core/widgets/section_header.dart';
import '../../../core/widgets/stat_card.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../l10n/app_localizations.dart';
import '../../../l10n/l10n.dart';
import '../providers/dashboard_provider.dart';
import 'professor_home_screen.dart';
import 'widgets/quick_action_grid.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final user = authState.user;

    if (user?.role == 'professor') {
      return const ProfessorHomeScreen();
    }

    final dashboardState = ref.watch(dashboardProvider);
    final l10n = context.l10n;

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () => ref.read(dashboardProvider.notifier).refresh(),
        child: dashboardState.isLoading && dashboardState.data == null
            ? _buildLoading(context)
            : dashboardState.error != null && dashboardState.data == null
                ? ErrorView(
                    message: l10n.dashboardLoadError,
                    detail: dashboardState.error,
                    onRetry: () =>
                        ref.read(dashboardProvider.notifier).refresh(),
                  )
                : _buildContent(context, ref, dashboardState, user),
      ),
    );
  }

  Widget _buildLoading(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        SizedBox(height: MediaQuery.of(context).padding.top + 16),
        const Row(
          children: [
            LoadingShimmer(width: 52, height: 52, borderRadius: 26),
            SizedBox(width: 14),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                LoadingShimmer(width: 140, height: 18),
                SizedBox(height: 8),
                LoadingShimmer(width: 90, height: 13),
              ],
            ),
          ],
        ),
        const SizedBox(height: 28),
        SizedBox(
          height: 100,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: 4,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (_, __) => const LoadingShimmer(width: 160, height: 100, borderRadius: 16),
          ),
        ),
        const SizedBox(height: 28),
        const LoadingShimmer(width: 120, height: 18),
        const SizedBox(height: 14),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          childAspectRatio: 2.4,
          children: List.generate(6, (_) => const LoadingShimmer(width: double.infinity, height: double.infinity, borderRadius: 14)),
        ),
      ],
    );
  }

  Widget _buildContent(
    BuildContext context,
    WidgetRef ref,
    DashboardState dashboardState,
    dynamic user,
  ) {
    final data = dashboardState.data;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final l10n = context.l10n;
    final roleName = _getRoleName(user?.role ?? '', l10n);
    final topPadding = MediaQuery.of(context).padding.top;

    return ListView(
      padding: EdgeInsets.fromLTRB(20, topPadding + 16, 20, 20),
      children: [
        // Welcome header
        _buildWelcomeHeader(context, user, roleName, isDark),
        const SizedBox(height: 28),

        // Stats section
        _buildStatsSection(context, data, isDark),
        const SizedBox(height: 28),

        // Quick Actions
        SectionHeader(
          title: l10n.dashboardQuickActions,
          padding: EdgeInsets.zero,
        ),
        const SizedBox(height: 12),
        QuickActionGrid(
          actions: [
            QuickAction(
              icon: PhosphorIconsRegular.chalkboardTeacher,
              label: l10n.navClasses,
              color: const Color(0xFF3B82F6),
              onTap: () => context.push('/classrooms'),
            ),
            QuickAction(
              icon: PhosphorIconsRegular.users,
              label: l10n.dashboardStudents,
              color: const Color(0xFF10B981),
              onTap: () => context.push('/students'),
            ),
            QuickAction(
              icon: PhosphorIconsRegular.bell,
              label: l10n.profileNotifications,
              color: const Color(0xFFF97316),
              onTap: () => context.push('/notifications'),
            ),
            QuickAction(
              icon: PhosphorIconsRegular.newspaper,
              label: l10n.dashboardNews,
              color: const Color(0xFF8B5CF6),
              onTap: () => context.push('/news'),
            ),
            QuickAction(
              icon: PhosphorIconsRegular.calendarBlank,
              label: l10n.dashboardEvents,
              color: const Color(0xFFEF4444),
              onTap: () => context.push('/events'),
            ),
            QuickAction(
              icon: PhosphorIconsRegular.currencyDollar,
              label: l10n.dashboardFees,
              color: AppColors.primary,
              onTap: () => context.push('/fees'),
            ),
            QuickAction(
              icon: PhosphorIconsRegular.chatCircle,
              label: l10n.navChat,
              color: const Color(0xFF06B6D4),
              onTap: () => context.push('/chat'),
            ),
            QuickAction(
              icon: PhosphorIconsRegular.magnifyingGlass,
              label: l10n.dashboardSearch,
              color: const Color(0xFF64748B),
              onTap: () => context.push('/search'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildWelcomeHeader(BuildContext context, dynamic user, String roleName, bool isDark) {
    final l10n = context.l10n;

    return Row(
      children: [
        AppAvatar(
          imageUrl: user?.avatarUrl,
          name: user?.name ?? l10n.commonUser,
          size: 52,
          showGradientRing: true,
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.dashboardWelcome(
                  user?.name?.split(' ').first ?? l10n.commonUser,
                ),
                style: AppTypography.titleLarge.copyWith(
                  color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                  color: _getRoleColor(user?.role ?? '').withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  roleName,
                  style: AppTypography.labelSmall.copyWith(
                    color: _getRoleColor(user?.role ?? ''),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
        IconButton(
          onPressed: () => context.push('/search'),
          tooltip: l10n.dashboardSearch,
          icon: Icon(
            PhosphorIconsRegular.magnifyingGlass,
            color: isDark
                ? AppColors.darkTextSecondary
                : AppColors.lightTextSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildStatsSection(BuildContext context, dynamic data, bool isDark) {
    final l10n = context.l10n;

    return SizedBox(
      height: 136,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          StatCard(
            icon: PhosphorIconsRegular.users,
            value: '${data?.totalStudents ?? 0}',
            label: l10n.dashboardStudents,
            iconColor: const Color(0xFF3B82F6),
          ),
          const SizedBox(width: 12),
          StatCard(
            icon: PhosphorIconsRegular.chalkboardTeacher,
            value: '${data?.totalClassrooms ?? 0}',
            label: l10n.dashboardClassrooms,
            iconColor: const Color(0xFF10B981),
          ),
          const SizedBox(width: 12),
          StatCard(
            icon: PhosphorIconsRegular.calendarCheck,
            value: '${data?.attendanceRate ?? 0}%',
            label: l10n.dashboardAttendance,
            iconColor: const Color(0xFFF97316),
          ),
          const SizedBox(width: 12),
          StatCard(
            icon: PhosphorIconsRegular.currencyDollar,
            value: '${data?.pendingFees ?? 0}',
            label: l10n.dashboardPendingFees,
            iconColor: const Color(0xFFEF4444),
          ),
        ],
      ),
    );
  }

  Color _getRoleColor(String role) {
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
