import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/error_view.dart';
import '../../../core/widgets/inline_error_banner.dart';
import '../../../core/widgets/loading_shimmer.dart';
import '../../../l10n/app_localizations.dart';
import '../../../l10n/l10n.dart';
import '../providers/statistics_provider.dart';
import 'widgets/stat_kpi_card.dart';

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
      if (!mounted) return;
      ref.read(statisticsDashboardProvider.notifier).load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final state = ref.watch(statisticsDashboardProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundFor(isDark),
      appBar: AppBar(title: Text(l10n.statisticsTitle)),
      body: _buildBody(state, l10n, isDark),
    );
  }

  Widget _buildBody(
    StatisticsState state,
    AppLocalizations l10n,
    bool isDark,
  ) {
    if (!state.hasLoaded) {
      return const ListShimmer();
    }

    if (state.error != null && state.data.isEmpty) {
      return ErrorView(
        message: l10n.statisticsLoadError,
        detail: state.error,
        onRetry: () => ref.read(statisticsDashboardProvider.notifier).load(),
      );
    }

    if (state.data.isEmpty) {
      return EmptyState(
        icon: PhosphorIconsRegular.chartBar,
        title: l10n.statisticsEmptyTitle,
        subtitle: l10n.statisticsEmptySubtitle,
      );
    }

    final metricEntries = state.data.metrics.entries.where((entry) {
      final value = entry.value;
      if (value is num || value is bool) return true;
      return value is String && value.trim().isNotEmpty;
    }).toList();

    final detailSections = <Widget>[];
    state.data.details.forEach((key, value) {
      if (_isInternalKey(key) || _isEmpty(value)) return;
      final rows = _rowsFor(value, l10n);
      if (rows.isEmpty) return;
      detailSections.add(_detailSection(key, rows, l10n, isDark));
    });

    if (metricEntries.isEmpty && detailSections.isEmpty) {
      return EmptyState(
        icon: PhosphorIconsRegular.chartBar,
        title: l10n.statisticsEmptyTitle,
        subtitle: l10n.statisticsEmptySubtitle,
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (state.error != null)
            InlineErrorBanner(
              margin: const EdgeInsets.only(bottom: 12),
              message: l10n.statisticsLoadError,
              onRetry: () =>
                  ref.read(statisticsDashboardProvider.notifier).load(),
            ),
          if (metricEntries.isNotEmpty) ...[
            _sectionTitle(l10n.kpiSummary, isDark),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: metricEntries
                  .map(
                    (entry) => StatKpiCard(
                      label: _metricLabel(entry.key, l10n),
                      value: _formatValue(entry.value, entry.key),
                      isDark: isDark,
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 24),
          ],
          if (detailSections.isNotEmpty) ...[
            _sectionTitle(l10n.statisticsDetailsTitle, isDark),
            const SizedBox(height: 12),
            ...detailSections,
          ],
        ],
      ),
    );
  }

  Widget _sectionTitle(String text, bool isDark) {
    return Text(
      text,
      style: AppTypography.titleMedium.copyWith(
        color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
        fontWeight: FontWeight.w700,
      ),
    );
  }

  Widget _detailSection(
    String key,
    List<_StatRow> rows,
    AppLocalizations l10n,
    bool isDark,
  ) {
    const maxRows = 5;
    final visible = rows.take(maxRows).toList();
    final remaining = rows.length - visible.length;
    final primary =
        isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final secondary =
        isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final accent = AppColors.accentFor(isDark);

    return AppCard(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _humanizeKey(key),
            style: AppTypography.titleSmall.copyWith(
              color: primary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          for (final row in visible)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (row.label.isNotEmpty) ...[
                    Expanded(
                      flex: 5,
                      child: Text(
                        row.label,
                        style: AppTypography.bodySmall.copyWith(
                          color: secondary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  Expanded(
                    flex: row.label.isEmpty ? 1 : 6,
                    child: Text(
                      row.value,
                      textAlign:
                          row.label.isEmpty ? TextAlign.start : TextAlign.end,
                      style: AppTypography.bodySmall.copyWith(
                        color: primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          if (remaining > 0)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                l10n.statisticsMoreItems(remaining),
                style: AppTypography.labelSmall.copyWith(color: accent),
              ),
            ),
        ],
      ),
    );
  }

  List<_StatRow> _rowsFor(dynamic value, AppLocalizations l10n) {
    final rows = <_StatRow>[];

    if (value is List) {
      for (final item in value) {
        if (item is Map) {
          final map = item.map(
            (key, entry) => MapEntry(key.toString(), entry),
          );
          final labelKey = _labelKeyFor(map);
          final label =
              labelKey == null ? '' : _formatValue(map[labelKey], labelKey);
          final pieces = <String>[];
          map.forEach((key, entry) {
            if (key == labelKey || _isInternalKey(key)) return;
            if (entry == null || entry is Map || entry is List) return;
            final formatted = _formatValue(entry, key);
            if (formatted.isEmpty || formatted == '—') return;
            pieces.add('${_fieldLabel(key, l10n)}: $formatted');
          });
          rows.add(
            _StatRow(
              label: label == '—' ? '' : label,
              value: pieces.join(' · '),
            ),
          );
        } else {
          rows.add(_StatRow(label: '', value: _formatValue(item, '')));
        }
      }
      return rows;
    }

    if (value is Map) {
      value.forEach((key, entry) {
        final name = key.toString();
        if (_isInternalKey(name) || entry == null) return;
        if (entry is List || entry is Map) return;
        rows.add(
          _StatRow(
            label: _fieldLabel(name, l10n),
            value: _formatValue(entry, name),
          ),
        );
      });
      return rows;
    }

    rows.add(_StatRow(label: '', value: _formatValue(value, '')));
    return rows;
  }

  String? _labelKeyFor(Map<String, dynamic> map) {
    const candidates = [
      'name',
      'fullname',
      'child_name',
      'student_name',
      'classroom_name',
      'subject',
      'month',
      'label',
      'type',
      'date',
      'day',
      'branch',
      'level',
      'book',
      'shift',
    ];
    for (final candidate in candidates) {
      final value = map[candidate];
      if (value != null && value.toString().trim().isNotEmpty) {
        return candidate;
      }
    }
    return null;
  }

  bool _isInternalKey(String key) {
    final lower = key.toLowerCase();
    return lower == 'filters' ||
        lower == 'id' ||
        lower.endsWith('_id') ||
        lower == 'user_id' ||
        lower == 'student_id';
  }

  bool _isEmpty(dynamic value) {
    if (value == null) return true;
    if (value is String) return value.trim().isEmpty;
    if (value is List) return value.isEmpty;
    if (value is Map) return value.isEmpty;
    return false;
  }

  String _metricLabel(String key, AppLocalizations l10n) {
    switch (key) {
      case 'total_students':
        return l10n.statisticsTotalStudents;
      case 'total_classrooms':
        return l10n.statisticsTotalClassrooms;
      case 'fees_paid_this_year':
        return l10n.statisticsFeesPaidThisYear;
      case 'fees_overdue':
        return l10n.statisticsFeesOverdue;
      case 'total_owed':
        return l10n.statisticsTotalOwed;
      case 'fees_pending_review':
        return l10n.statisticsFeesPendingReview;
      case 'open_tickets':
        return l10n.statisticsOpenTickets;
      case 'absences_this_month':
        return l10n.statisticsAbsencesThisMonth;
      case 'classrooms_count':
        return l10n.statisticsClassroomsCount;
      case 'absences_today':
        return l10n.statisticsAbsencesToday;
      case 'fees_paid':
        return l10n.statisticsFeesPaid;
      case 'fees_pending':
        return l10n.statisticsFeesPending;
      case 'children_count':
        return l10n.statisticsChildrenCount;
      default:
        return _humanizeKey(key);
    }
  }

  String _fieldLabel(String key, AppLocalizations l10n) {
    switch (key) {
      case 'total_absences':
        return l10n.statisticsTotalAbsences;
      case 'total_classes':
        return l10n.statisticsTotalClasses;
      case 'rate':
        return l10n.statisticsAbsenceRate;
      default:
        return _humanizeKey(key);
    }
  }

  String _formatValue(dynamic value, String key) {
    if (value == null) return '—';

    if (value is num) {
      final lower = key.toLowerCase();
      if (lower.contains('rate') ||
          lower.contains('percentage') ||
          lower.contains('percent')) {
        return '${_trimNumber(value)}%';
      }
      if (lower.contains('owed') ||
          lower.contains('debt') ||
          lower.contains('balance') ||
          lower.contains('collected') ||
          lower.contains('amount')) {
        return AppFormatters.formatCurrency(value.toDouble());
      }
      if (value is int || value == value.roundToDouble()) {
        return AppFormatters.formatNumber(value.toInt());
      }
      return value.toStringAsFixed(2);
    }

    if (value is bool) return value ? '✓' : '—';

    final text = value.toString().trim();
    return text.isEmpty ? '—' : text;
  }

  String _trimNumber(num value) {
    if (value is int || value == value.roundToDouble()) {
      return value.toInt().toString();
    }
    return value.toStringAsFixed(2).replaceFirst(RegExp(r'\.?0+$'), '');
  }

  String _humanizeKey(String key) {
    if (key.isEmpty) return key;
    final spaced = key
        .replaceAllMapped(
          RegExp(r'([a-z0-9])([A-Z])'),
          (match) => '${match[1]} ${match[2]}',
        )
        .replaceAll('_', ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    if (spaced.isEmpty) return key;
    return spaced[0].toUpperCase() + spaced.substring(1);
  }
}

class _StatRow {
  final String label;
  final String value;

  const _StatRow({required this.label, required this.value});
}
