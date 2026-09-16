import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/error_view.dart';
import '../../../core/widgets/large_title_bar.dart';
import '../../../core/widgets/loading_shimmer.dart';
import '../../../core/widgets/search_bar.dart';
import '../providers/student_provider.dart';
import 'widgets/student_card.dart';

class StudentListScreen extends ConsumerStatefulWidget {
  const StudentListScreen({super.key});

  @override
  ConsumerState<StudentListScreen> createState() => _StudentListScreenState();
}

class _StudentListScreenState extends ConsumerState<StudentListScreen> {
  final _scrollController = ScrollController();
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      ref.read(studentListProvider.notifier).loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final listState = ref.watch(studentListProvider);
    final notifier = ref.read(studentListProvider.notifier);

    return Scaffold(
      body: Column(
        children: [
          const LargeTitleBar(
            title: 'Students',
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
            child: AppSearchBar(
              controller: _searchController,
              hintText: 'Search students...',
              onChanged: (value) => notifier.search(value),
            ),
          ),
          SizedBox(
            height: 36,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              children: [
                _FilterChip(
                  label: 'Todos',
                  selected: listState.status == StudentListState.statusAll,
                  onTap: () => notifier.setStatus(StudentListState.statusAll),
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: 'Activos',
                  selected: listState.status == StudentListState.statusActive,
                  onTap: () =>
                      notifier.setStatus(StudentListState.statusActive),
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: 'Inactivos',
                  selected:
                      listState.status == StudentListState.statusInactive,
                  onTap: () =>
                      notifier.setStatus(StudentListState.statusInactive),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
            child: Row(
              children: [
                Expanded(
                  child: _DropdownFilter(
                    label: 'Año',
                    value: listState.year,
                    options: listState.yearOptions,
                    onChanged: (value) => notifier.setYear(value),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _DropdownFilter(
                    label: 'Sede',
                    value: listState.branch,
                    options: listState.branchOptions,
                    onChanged: (value) => notifier.setBranch(value),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => notifier.refresh(),
              child: _buildBody(listState),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(StudentListState state) {
    if (state.isLoading && state.pagination.data.isEmpty) {
      return const ListShimmer();
    }

    if (state.error != null && state.pagination.data.isEmpty) {
      return ErrorView(
        message: 'Failed to load students',
        detail: state.error,
        onRetry: () => ref.read(studentListProvider.notifier).refresh(),
      );
    }

    if (state.pagination.data.isEmpty) {
      return EmptyState(
        icon: Icons.people_outline,
        title: 'No students found',
        subtitle: state.search.isNotEmpty
            ? 'Try a different search term'
            : 'No students match the selected filters',
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      itemCount: state.pagination.data.length + (state.pagination.hasMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == state.pagination.data.length) {
          return const Padding(
            padding: EdgeInsets.all(16),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        final student = state.pagination.data[index];
        return StudentCard(
          student: student,
          onTap: () => context.push('/students/${student.id}'),
        );
      },
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
    final selectedColor = isDark ? const Color(0xFF6366F1) : AppColors.primary;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected
              ? selectedColor.withOpacity(0.12)
              : (isDark ? AppColors.darkSearchFill : AppColors.lightSearchFill),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: selected
                ? selectedColor
                : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
            width: selected ? 1.2 : 0.5,
          ),
        ),
        child: Text(
          label,
          style: AppTypography.labelLarge.copyWith(
            color: selected
                ? selectedColor
                : (isDark
                    ? AppColors.darkTextSecondary
                    : AppColors.lightTextSecondary),
            fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

class _DropdownFilter extends StatelessWidget {
  static const _allValue = '__all__';

  final String label;
  final String? value;
  final List<String> options;
  final ValueChanged<String?> onChanged;

  const _DropdownFilter({
    required this.label,
    required this.value,
    required this.options,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final allOptions = {
      ...options,
      if (value != null) value!,
    }.toList()
      ..sort();

    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSearchFill : AppColors.lightSearchFill,
        borderRadius: BorderRadius.circular(20),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value ?? _allValue,
          isExpanded: true,
          borderRadius: BorderRadius.circular(12),
          dropdownColor: isDark ? AppColors.darkSurface : AppColors.lightSurface,
          icon: Icon(
            PhosphorIconsRegular.caretDown,
            size: 14,
            color: isDark
                ? AppColors.darkTextTertiary
                : AppColors.lightTextTertiary,
          ),
          style: AppTypography.labelLarge.copyWith(
            color: isDark
                ? AppColors.darkTextPrimary
                : AppColors.lightTextPrimary,
          ),
          items: [
            DropdownMenuItem<String>(
              value: _allValue,
              child: Text('$label: Todos'),
            ),
            ...allOptions.map(
              (option) => DropdownMenuItem<String>(
                value: option,
                child: Text('$label: $option'),
              ),
            ),
          ],
          onChanged: (selected) =>
              onChanged(selected == _allValue ? null : selected),
        ),
      ),
    );
  }
}
