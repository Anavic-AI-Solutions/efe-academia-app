import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../core/widgets/pill_button.dart';
import '../../domain/classroom_filters.dart';
import '../../providers/classroom_provider.dart';

class ClassroomFilterSelection {
  final String? branch;
  final String? level;
  final String? year;
  final String? status;

  const ClassroomFilterSelection({
    this.branch,
    this.level,
    this.year,
    this.status,
  });

  bool get isEmpty =>
      branch == null && level == null && year == null && status == null;

  int get count =>
      [branch, level, year, status].where((value) => value != null).length;

  ClassroomFilterSelection copyWith({
    String? branch,
    bool clearBranch = false,
    String? level,
    bool clearLevel = false,
    String? year,
    bool clearYear = false,
    String? status,
    bool clearStatus = false,
  }) {
    return ClassroomFilterSelection(
      branch: clearBranch ? null : (branch ?? this.branch),
      level: clearLevel ? null : (level ?? this.level),
      year: clearYear ? null : (year ?? this.year),
      status: clearStatus ? null : (status ?? this.status),
    );
  }
}

String classroomStatusLabel(String status) {
  switch (status) {
    case 'active':
      return 'Active';
    case 'archived':
      return 'Archived';
    default:
      return status;
  }
}

Future<ClassroomFilterSelection?> showClassroomFilterSheet(
  BuildContext context, {
  required ClassroomFilterSelection initial,
}) {
  return showModalBottomSheet<ClassroomFilterSelection>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => ClassroomFilterSheet(initial: initial),
  );
}

class ClassroomFilterSheet extends ConsumerStatefulWidget {
  final ClassroomFilterSelection initial;

  const ClassroomFilterSheet({super.key, required this.initial});

  @override
  ConsumerState<ClassroomFilterSheet> createState() =>
      _ClassroomFilterSheetState();
}

class _ClassroomFilterSheetState extends ConsumerState<ClassroomFilterSheet> {
  late ClassroomFilterSelection _selection = widget.initial;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final optionsAsync = ref.watch(classroomFiltersProvider);

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.8,
      ),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 10),
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 12, 4),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Filters',
                      style: AppTypography.titleLarge.copyWith(
                        color: isDark
                            ? AppColors.darkTextPrimary
                            : AppColors.lightTextPrimary,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: _selection.isEmpty
                        ? null
                        : () => setState(
                              () => _selection =
                                  const ClassroomFilterSelection(),
                            ),
                    style: TextButton.styleFrom(
                      foregroundColor:
                          isDark ? const Color(0xFF6366F1) : AppColors.primary,
                      disabledForegroundColor: isDark
                          ? AppColors.darkTextTertiary
                          : AppColors.lightTextTertiary,
                      textStyle: AppTypography.labelLarge,
                    ),
                    child: const Text('Clear all'),
                  ),
                ],
              ),
            ),
            Flexible(
              child: optionsAsync.when(
                loading: () => const Padding(
                  padding: EdgeInsets.symmetric(vertical: 56),
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (_, __) => _ErrorBody(
                  onRetry: () => ref.invalidate(classroomFiltersProvider),
                ),
                data: (options) => _OptionsBody(
                  options: options,
                  selection: _selection,
                  onChanged: (selection) =>
                      setState(() => _selection = selection),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
              child: PillButton(
                label: 'Apply filters',
                height: 48,
                onPressed: () => Navigator.of(context).pop(_selection),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OptionsBody extends StatelessWidget {
  final ClassroomFilters options;
  final ClassroomFilterSelection selection;
  final ValueChanged<ClassroomFilterSelection> onChanged;

  const _OptionsBody({
    required this.options,
    required this.selection,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (options.branches.isNotEmpty)
            _FilterSection(
              label: 'Branch',
              values: options.branches,
              selected: selection.branch,
              onSelected: (value) => onChanged(
                value == null
                    ? selection.copyWith(clearBranch: true)
                    : selection.copyWith(branch: value),
              ),
            ),
          if (options.levels.isNotEmpty)
            _FilterSection(
              label: 'Level',
              values: options.levels,
              selected: selection.level,
              onSelected: (value) => onChanged(
                value == null
                    ? selection.copyWith(clearLevel: true)
                    : selection.copyWith(level: value),
              ),
            ),
          if (options.years.isNotEmpty)
            _FilterSection(
              label: 'Year',
              values: options.years,
              selected: selection.year,
              onSelected: (value) => onChanged(
                value == null
                    ? selection.copyWith(clearYear: true)
                    : selection.copyWith(year: value),
              ),
            ),
          if (options.statuses.isNotEmpty)
            _FilterSection(
              label: 'Status',
              values: options.statuses,
              selected: selection.status,
              labelFor: classroomStatusLabel,
              onSelected: (value) => onChanged(
                value == null
                    ? selection.copyWith(clearStatus: true)
                    : selection.copyWith(status: value),
              ),
            ),
        ],
      ),
    );
  }
}

class _FilterSection extends StatelessWidget {
  final String label;
  final List<String> values;
  final String? selected;
  final String Function(String value)? labelFor;
  final ValueChanged<String?> onSelected;

  const _FilterSection({
    required this.label,
    required this.values,
    required this.selected,
    required this.onSelected,
    this.labelFor,
  });

  static String _identity(String value) => value;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AppTypography.titleSmall.copyWith(
              color:
                  isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final value in values)
                _FilterChip(
                  label: (labelFor ?? _identity)(value),
                  selected: value == selected,
                  onTap: () => onSelected(value == selected ? null : value),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = isDark ? const Color(0xFF6366F1) : AppColors.primary;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected
              ? accent
              : (isDark ? AppColors.darkSearchFill : AppColors.lightSearchFill),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected
                ? accent
                : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
          ),
        ),
        child: Text(
          label,
          style: AppTypography.labelLarge.copyWith(
            color: selected
                ? Colors.white
                : (isDark
                    ? AppColors.darkTextPrimary
                    : AppColors.lightTextPrimary),
          ),
        ),
      ),
    );
  }
}

class _ErrorBody extends StatelessWidget {
  final VoidCallback onRetry;

  const _ErrorBody({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 32),
      child: Column(
        children: [
          const Icon(
            PhosphorIconsRegular.warningCircle,
            size: 32,
            color: AppColors.error,
          ),
          const SizedBox(height: 12),
          Text(
            'Could not load filters',
            style: AppTypography.titleSmall.copyWith(
              color:
                  isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Check your connection and try again.',
            textAlign: TextAlign.center,
            style: AppTypography.bodySmall.copyWith(
              color: isDark
                  ? AppColors.darkTextSecondary
                  : AppColors.lightTextSecondary,
            ),
          ),
          const SizedBox(height: 16),
          OutlinedButton(
            onPressed: onRetry,
            style: OutlinedButton.styleFrom(
              foregroundColor:
                  isDark ? const Color(0xFF6366F1) : AppColors.primary,
              side: BorderSide(
                color:
                    isDark ? AppColors.darkBorder : AppColors.lightBorder,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}
