import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../auth/providers/auth_provider.dart';
import '../../../core/widgets/avatar.dart';
import '../../../core/widgets/error_view.dart';
import '../../../core/widgets/loading_shimmer.dart';
import '../../../app/theme/app_colors.dart';
import '../providers/dashboard_provider.dart';
import 'widgets/quick_action_grid.dart';
import 'widgets/stat_card.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboardState = ref.watch(dashboardProvider);
    final authState = ref.watch(authProvider);
    final user = authState.user;

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () => ref.read(dashboardProvider.notifier).refresh(),
        child: dashboardState.isLoading && dashboardState.data == null
            ? _buildLoading(context)
            : dashboardState.error != null && dashboardState.data == null
                ? ErrorView(
                    message: 'Failed to load dashboard',
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
      padding: const EdgeInsets.all(16),
      children: [
        const SizedBox(height: 48),
        Row(
          children: [
            const LoadingShimmer(width: 56, height: 56, borderRadius: 28),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                LoadingShimmer(width: 160, height: 20),
                SizedBox(height: 8),
                LoadingShimmer(width: 100, height: 14),
              ],
            ),
          ],
        ),
        const SizedBox(height: 32),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.4,
          children: List.generate(4, (_) => const LoadingShimmer(width: double.infinity, height: double.infinity)),
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
    final roleName = _getRoleName(user?.role ?? '');

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Welcome header
        _buildWelcomeHeader(context, user, roleName),
        const SizedBox(height: 24),

        // Stats grid
        _buildStatsGrid(context, data),
        const SizedBox(height: 24),

        // Quick Actions
        Text(
          'Quick Actions',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        QuickActionGrid(
          actions: [
            QuickAction(
              icon: PhosphorIconsRegular.chalkboardTeacher,
              label: 'Classes',
              color: Colors.blue,
              onTap: () => context.push('/classrooms'),
            ),
            QuickAction(
              icon: PhosphorIconsRegular.users,
              label: 'Students',
              color: Colors.green,
              onTap: () => context.push('/students'),
            ),
            QuickAction(
              icon: PhosphorIconsRegular.bell,
              label: 'Notifications',
              color: Colors.orange,
              onTap: () => context.push('/notifications'),
            ),
            QuickAction(
              icon: PhosphorIconsRegular.newspaper,
              label: 'News',
              color: Colors.purple,
              onTap: () => context.push('/news'),
            ),
            QuickAction(
              icon: PhosphorIconsRegular.calendarBlank,
              label: 'Events',
              color: Colors.red,
              onTap: () => context.push('/events'),
            ),
            QuickAction(
              icon: PhosphorIconsRegular.currencyDollar,
              label: 'Fees',
              color: AppColors.primary,
              onTap: () => context.push('/fees'),
            ),
            QuickAction(
              icon: PhosphorIconsRegular.chatCircle,
              label: 'Chat',
              color: Colors.teal,
              onTap: () => context.push('/chat'),
            ),
            QuickAction(
              icon: PhosphorIconsRegular.magnifyingGlass,
              label: 'Search',
              color: Colors.grey,
              onTap: () => context.push('/search'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildWelcomeHeader(BuildContext context, dynamic user, String roleName) {
    final theme = Theme.of(context);

    return Row(
      children: [
        AppAvatar(
          imageUrl: user?.avatarUrl,
          name: user?.name ?? 'User',
          size: 56,
          showBorder: true,
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Welcome, ${user?.name ?? 'User'}!',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                roleName,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.textTheme.bodySmall?.color?.withOpacity(0.7),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatsGrid(BuildContext context, dynamic data) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.4,
      children: [
        StatCard(
          icon: PhosphorIconsRegular.users,
          value: '${data?.totalStudents ?? 0}',
          label: 'Students',
          iconColor: Colors.blue,
        ),
        StatCard(
          icon: PhosphorIconsRegular.chalkboardTeacher,
          value: '${data?.totalClassrooms ?? 0}',
          label: 'Classrooms',
          iconColor: Colors.green,
        ),
        StatCard(
          icon: PhosphorIconsRegular.calendarCheck,
          value: '${data?.attendanceRate ?? 0}%',
          label: 'Attendance',
          iconColor: Colors.orange,
        ),
        StatCard(
          icon: PhosphorIconsRegular.currencyDollar,
          value: '${data?.pendingFees ?? 0}',
          label: 'Pending Fees',
          iconColor: Colors.red,
        ),
      ],
    );
  }

  String _getRoleName(String role) {
    switch (role) {
      case 'admin':
        return 'Administrator';
      case 'branch':
        return 'Branch Director';
      case 'professor':
        return 'Professor';
      case 'parent':
        return 'Parent';
      case 'student':
        return 'Student';
      default:
        return role.isNotEmpty ? role : 'User';
    }
  }
}
