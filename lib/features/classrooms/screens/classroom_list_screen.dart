import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../app/theme/app_colors.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/error_view.dart';
import '../../../core/widgets/loading_shimmer.dart';
import '../../../core/widgets/pagination_bar.dart';
import '../../../core/widgets/search_bar.dart';
import '../../../l10n/l10n.dart';
import '../providers/classroom_provider.dart';
import 'widgets/classroom_filter_button.dart';
import 'widgets/classroom_filter_chips.dart';
import 'widgets/classroom_filter_sheet.dart';
import 'widgets/professor_classroom_list_card.dart';
import 'widgets/professor_classrooms_header.dart';

class ClassroomListScreen extends ConsumerStatefulWidget {
  const ClassroomListScreen({super.key});

  @override
  ConsumerState<ClassroomListScreen> createState() =>
      _ClassroomListScreenState();
}

class _ClassroomListScreenState extends ConsumerState<ClassroomListScreen> {
  final _scrollController = ScrollController();
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  ClassroomFilterSelection _selectionFrom(ClassroomListState state) {
    return ClassroomFilterSelection(
      branch: state.branch,
      level: state.level,
      year: state.year,
      status: state.status,
    );
  }

  Future<void> _applySelection(ClassroomFilterSelection selection) async {
    if (!mounted) return;
    await ref.read(classroomListProvider.notifier).applyFilters(
          branch: selection.branch,
          level: selection.level,
          year: selection.year,
          status: selection.status,
        );
    _scrollToTop();
  }

  void _scrollToTop() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(0);
      }
    });
  }

  Future<void> _goToPage(int page) async {
    await ref.read(classroomListProvider.notifier).goToPage(page);
    _scrollToTop();
  }

  Future<void> _openFilters() async {
    final state = ref.read(classroomListProvider);
    final selection = await showClassroomFilterSheet(
      context,
      initial: _selectionFrom(state),
    );
    if (selection == null) return;
    await _applySelection(selection);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final listState = ref.watch(classroomListProvider);
    final selection = _selectionFrom(listState);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: AppColors.backgroundFor(isDark),
      body: Column(
        children: [
          ProfessorClassroomsHeader(
            subtitle: listState.isLoading && listState.page.total == 0
                ? ''
                : l10n.professorClassroomsCount(listState.page.total),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: Row(
              children: [
                Expanded(
                  child: AppSearchBar(
                    controller: _searchController,
                    hintText: l10n.classroomsSearchHint,
                    onChanged: (value) =>
                        ref.read(classroomListProvider.notifier).search(value),
                  ),
                ),
                const SizedBox(width: 10),
                ClassroomFilterButton(
                  activeCount: selection.count,
                  onTap: _openFilters,
                ),
              ],
            ),
          ),
          if (!selection.isEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: ClassroomFilterChips(
                selection: selection,
                onChanged: _applySelection,
                onClearAll: () =>
                    _applySelection(const ClassroomFilterSelection()),
              ),
            ),
          Expanded(
            child: _buildBody(listState),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(ClassroomListState state) {
    final l10n = context.l10n;

    if (state.isLoading && state.page.data.isEmpty) {
      return const ListShimmer();
    }

    if (state.error != null && state.page.data.isEmpty) {
      return ErrorView(
        message: l10n.classroomsLoadError,
        detail: state.error,
        onRetry: () => ref.read(classroomListProvider.notifier).refresh(),
      );
    }

    if (state.page.data.isEmpty) {
      final filtered = state.hasActiveFilters;
      final searching = state.search.isNotEmpty;
      return EmptyState(
        icon: PhosphorIconsRegular.chalkboardTeacher,
        title: !filtered && !searching
            ? l10n.professorMyClassroomsEmpty
            : l10n.classroomsEmptyTitle,
        subtitle: filtered
            ? l10n.classroomsEmptyFiltered
            : searching
                ? l10n.classroomsEmptySearch
                : null,
        actionLabel: filtered ? l10n.classroomsClearFilters : null,
        onAction: filtered
            ? () => _applySelection(const ClassroomFilterSelection())
            : null,
      );
    }

    return Column(
      children: [
        if (state.isLoading)
          const LinearProgressIndicator(minHeight: 2),
        Expanded(
          child: RefreshIndicator(
            onRefresh: () =>
                ref.read(classroomListProvider.notifier).refresh(),
            child: ListView.builder(
              controller: _scrollController,
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
              itemCount: state.page.data.length,
              itemBuilder: (context, index) {
                final classroom = state.page.data[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 11),
                  child: ProfessorClassroomListCard(
                    classroom: classroom,
                    onTap: () =>
                        context.push('/classrooms/${classroom.id}'),
                  ),
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

