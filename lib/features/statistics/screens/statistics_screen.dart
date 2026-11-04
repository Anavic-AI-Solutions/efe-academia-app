import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../app/theme/app_colors.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/error_view.dart';
import '../../../core/widgets/loading_shimmer.dart';
import '../../../l10n/l10n.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/statistics_provider.dart';
import '../domain/statistics_model.dart';

class StatisticsScreen extends ConsumerStatefulWidget {
  const StatisticsScreen({super.key});

  @override
  ConsumerState<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends ConsumerState<StatisticsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(statisticsDashboardProvider.notifier).load(
            role: ref.read(authProvider).user?.role,
          );
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final statistics = ref.watch(statisticsDashboardProvider);
    final role = ref.read(authProvider).user?.role ?? 'student';

    return Scaffold(
      backgroundColor: AppColors.backgroundFor(isDark),
      appBar: AppBar(
        title: Text(l10n.statisticsTitle),
      ),
      body: statistics.isLoading
          ? const LoadingShimmer(
              width: double.infinity,
              height: 200,
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
              : _buildContent(statistics, role, isDark);
  }

  Widget _buildContent(StatisticsState stats, String role, bool isDark) {
    final metrics = stats.data.metrics;
    final details = stats.data.details;
    final l10n = context.l10n;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (metrics.isNotEmpty) ...[
            Text(
              l10n.kpiSummary,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: isDark
                    ? AppColors.darkTextPrimary
                    : AppColors.lightTextPrimary,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: metrics.entries.map((entry) {
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          entry.value.toString(),
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: isDark
                                ? AppColors.darkTextPrimary
                                : AppColors.lightTextPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          entry.key,
                          style: TextStyle(
                            fontSize: 14,
                            color: isDark
                                ? AppColors.darkTextSecondary
                                : AppColors.lightTextSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
          const SizedBox(height: 24),
          if (details.isNotEmpty) ...[
            Text(
              l10n.noData,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: isDark
                    ? AppColors.darkTextPrimary
                    : AppColors.lightTextPrimary,
              ),
            ),
            const SizedBox(height: 12),
            ..._buildDetailsList(details, isDark),
          ] else ...[
            EmptyState(
              icon: PhosphorIconsRegular.barChart,
              title: l10n.noData,
              subtitle: l10n.noDataSubtitle,
            ),
          ],
        ],
      ),
    );
  }

  List<Widget> _buildDetailsList(List<dynamic> details, bool isDark) {
    final List<Widget> widgets = [];

    for (var detail in details) {
      if (detail is Map<String, dynamic>) {
        widgets.add(_detailRow(
          title: detail['label'] ?? '',
          subtitle: detail['value'] ?? '',
          isDark: isDark,
        ));
      }
    }

    return widgets;
  }

  Widget _detailRow({
    required String title,
    required String subtitle,
    required bool isDark,
  }) {
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
                color: isDark
                    ? AppColors.darkTextSecondary
                    : AppColors.lightTextSecondary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              subtitle,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: isDark
                    ? AppColors.darkTextPrimary
                    : AppColors.lightTextPrimary,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
