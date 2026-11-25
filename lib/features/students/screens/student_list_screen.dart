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
import '../../../core/widgets/pagination_bar.dart';
import '../../../core/widgets/search_bar.dart';
import '../../../l10n/l10n.dart';
import '../../auth/domain/user_model.dart';
import '../../auth/providers/auth_provider.dart';
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
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _scrollToTop() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(0);
      }
    });
  }

  Future<void> _goToPage(int page) async {
    await ref.read(studentListProvider.notifier).goToPage(page);
    _scrollToTop();
  }

  Future<void> _openCreate() async {
    await context.push<bool>('/students/new');
    if (!mounted) return;
    await ref.read(studentListProvider.notifier).refresh();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final listState = ref.watch(studentListProvider);
    final notifier = ref.read(studentListProvider.notifier);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final canManageStudents =
        ref.watch(authProvider).user?.canManageStudents ?? false;

    return Scaffold(
      backgroundColor: AppColors.backgroundFor(isDark),
      floatingActionButton: canManageStudents
          ? FloatingActionButton(
              key: const Key('student-list-fab'),
              tooltip: l10n.commonCreate,
              onPressed: _openCreate,
              backgroundColor: AppColors.primary,
              child: const Icon(
                PhosphorIconsRegular.plus,
                color: Colors.white,
              ),
            )
          : null,
      body: Column(
        children: [
          LargeTitleBar(
            title: l10n.studentsTitle,
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: AppSearchBar(
              controller: _searchController,
              hintText: l10n.studentsSearchHint,
              onChanged: (value) => notifier.search(value),
            ),
          ),
          SizedBox(
            height: 36,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                _FilterChip(
                  label: l10n.studentsFilterAll,
                  selected: listState.status == StudentListState.statusAll,
                  onTap: () => notifier.setStatus(StudentListState.statusAll),
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: l10n.studentsFilterActive,
                  selected: listState.status == StudentListState.statusActive,
                  onTap: () =>
                      notifier.setStatus(StudentListState.statusActive),
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: l10n.studentsFilterInactive,
                  selected: listState.status == StudentListState.statusInactive,
                  onTap: () =>
                      notifier.setStatus(StudentListState.statusInactive),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Row(
              children: [
                Expanded(
                  child: _DropdownFilter(
                    label: l10n.studentsFilterYear,
                    value: listState.year,
                    options: listState.yearOptions,
                    onChanged: (value) => notifier.setYear(value),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _DropdownFilter(
                    label: l10n.studentsFilterBranch,
                    value: listState.branch,
                    options: listState.branchOptions,
                    onChanged: (value) => notifier.setBranch(value),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _buildBody(listState),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(StudentListState state) {
    final l10n = context.l10n;

    if (state.isLoading && state.page.data.isEmpty) {
      return const ListShimmer();
    }

    if (state.error != null && state.page.data.isEmpty) {
      return ErrorView(
        message: l10n.studentsLoadError,
        detail: state.error,
        onRetry: () => ref.read(studentListProvider.notifier).refresh(),
      );
    }

    if (state.page.data.isEmpty) {
      return EmptyState(
        icon: Icons.people_outline,
        title: l10n.studentsEmptyTitle,
        subtitle: state.search.isNotEmpty
            ? l10n.studentsEmptySearch
            : l10n.studentsEmptyFilters,
      );
    }

    return Column(
      children: [
        if (state.isLoading) const LinearProgressIndicator(minHeight: 2),
        Expanded(
          child: RefreshIndicator(
            onRefresh: () => ref.read(studentListProvider.notifier).refresh(),
            child: ListView.builder(
              controller: _scrollController,
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
              itemCount: state.page.data.length,
              itemBuilder: (context, index) {
                final student = state.page.data[index];
                return StudentCard(
                  student: student,
                  onTap: () => context.push('/students/${student.id}'),
                );
              },
            ),
          ),
        ),
        PaginationBar(
          page: state.page.page,
          totalPages: state.page.totalPages,
          from: state.page.firstItem,
          to: state.page.lastItem,
          total: state.page.total,
          enabled: !state.isLoading,
          onPageChanged: _goToPage,
        ),
      ],
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
    final selectedColor = AppColors.accentFor(isDark);

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
    final l10n = context.l10n;
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
          dropdownColor:
              isDark ? AppColors.darkSurface : AppColors.lightSurface,
          icon: Icon(
            PhosphorIconsRegular.caretDown,
            size: 14,
            color: isDark
                ? AppColors.darkTextTertiary
                : AppColors.lightTextTertiary,
          ),
          style: AppTypography.labelLarge.copyWith(
            color:
                isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
          ),
          items: [
            DropdownMenuItem<String>(
              value: _allValue,
              child: Text(l10n.studentsFilterOptionAll(label)),
            ),
            ...allOptions.map(
              (option) => DropdownMenuItem<String>(
                value: option,
                child: Text(l10n.studentsFilterOption(label, option)),
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
