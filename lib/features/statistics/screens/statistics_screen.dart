import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../app/theme/app_colors.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/error_view.dart';
import '../../../core/widgets/loading_shimmer.dart';
import '../../../core/widgets/pagination_bar.dart';
import '../../../l10n/l10n.dart';
import '../../auth/providers/auth_provider.dart';
import 'providers/statistics_provider.dart';

class StatisticsScreen extends ConsumerStatefulWidget {
  const StatisticsScreen({super.key});

  @override
  ConsumerState<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends ConsumerState<StatisticsScreen> {
  @override
  void initState() {
    super.initState();
    // Load statistics on screen init
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(statisticsDashboardProvider.notifier).load(
            role: ref.watch(authProvider).user?.role,
          );
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final statistics = ref.watch(statisticsDashboardProvider);
    final role = ref.watch(authProvider).user?.role ?? 'student';

    return Scaffold(
      backgroundColor: AppColors.backgroundFor(isDark),
      appBar: AppBar(
        title: Text(l10n.statisticsTitle),
      ),
      body: statistics.isLoading
          ? const LoadingShimmer(
              rowCount: 3,
              columnCount: 2,
              height: 300,
            )
          : statistics.error != null
              ? ErrorView(
                  message: l10n.statisticsLoadError,
                  detail: statistics.error!,
                  onRetry: () =>
                      ref.read(statisticsDashboardProvider.notifier).load(
                        role: role,
                      ),
                )
              : _buildContent(statistics, role);
  }

  Widget _buildContent(StatisticsModel stats, String role) {
    final metrics = stats.metrics;
    final details = stats.details;

    // Build KPI cards based on role
    final kpiCards = _buildKpiCards(role, metrics);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // KPI Grid
          if (kpiCards.isNotEmpty) ...kpiCards,
          const SizedBox(height: 24),
          // Details list
          if (details.isNotEmpty) ...[
            Text(
              l10n.statisticsDetails,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.darkTextPrimary,
              ),
            ),
            const SizedBox(height: 12),
            ..._buildDetailsList(details),
          ] else ...[
            EmptyState(
              icon: PhosphorIconsRegular.chart,
              title: l10n.noData,
              subtitle: l10n.noDataSubtitle,
            ),
          ],
        ],
      ),
    );
  }

  List<Widget> _buildKpiCards(String role, Map<String, dynamic> metrics) {
    final List<Widget> cards = [];

    // Role-specific KPIs
    switch (role) {
      case 'admin':
      case 'sede':
        cards.add(_kpiCard(
          context,
          label: l10n.totalStudents,
          value: metrics['totalStudents']?.toString() ?? '0',
          icon: PhosphorIconsRegular.users,
          color: AppColors.primary,
        ));
        cards.add(_kpiCard(
          context,
          label: l10n.totalClassrooms,
          value: metrics['totalClassrooms']?.toString() ?? '0',
          icon: PhosphorIconsRegular.chalkboardTeacher,
          color: AppColors.primary,
        ));
        cards.add(_kpiCard(
          context,
          label: l10n.totalProfessors,
          value: metrics['totalProfessors']?.toString() ?? '0',
          icon: PhosphorIconsRegular.userTie,
          color: AppColors.primary,
        ));
        break;
      case 'professor':
        cards.add(_kpiCard(
          context,
          label: l10n.myClassrooms,
          value: metrics['myClassrooms']?.toString() ?? '0',
          icon: PhosphorIconsRegular.chalkboardTeacher,
          color: AppColors.primary,
        ));
        cards.add(_kpiCard(
          context,
          label: l10n.totalStudents,
          value: metrics['totalStudents']?.toString() ?? '0',
          icon: PhosphorIconsRegular.users,
          color: AppColors.primary,
        ));
        break;
      case 'parent':
        cards.add(_kpiCard(
          context,
          label: l10n.pendingFees,
          value: metrics['pendingFees']?.toString() ?? '0',
          icon: PhosphorIconsRegular.wallet,
          color: AppColors.primary,
        ));
        cards.add(_kpiCard(
          context,
          label: l10n.totalClassrooms,
          value: metrics['totalClassrooms']?.toString() ?? '0',
          icon: PhosphorIconsRegular.chalkboardTeacher,
          color: AppColors.primary,
        ));
        break;
      case 'student':
        cards.add(_kpiCard(
          context,
          label: l10n.myClassrooms,
          value: metrics['myClassrooms']?.toString() ?? '0',
          icon: PhosphorIconsRegular.chalkboardTeacher,
          color: AppColors.primary,
        ));
        break;
    }

    return if (kpiCards.isNotEmpty) ...[
      Text(
        l10n.kpiSummary,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: AppColors.darkTextPrimary,
        ),
      ),
      const SizedBox(height: 12),
      Wrap(
        spacing: 12,
        runSpacing: 12,
        children: kpiCards,
      ),
    ] else ...[];
  }

  Widget _kpiCard(
      BuildContext context, {
      required String label,
      required String value,
      required IconData icon,
      required Color color,
      }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildDetailsList(List<dynamic> details) {
    final List<Widget> widgets = [];

    for (var detail in details) {
      if (detail is Map<String, dynamic>) {
        widgets.add(_detailRow(
          title: detail['label'] ?? '',
          subtitle: detail['value'] ?? '',
        ));
      }
    }

    return widgets;
  }

  Widget _detailRow({
    required String title,
    required String subtitle,
    }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              subtitle,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: textColor,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}