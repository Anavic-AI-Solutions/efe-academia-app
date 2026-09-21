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
import '../../../l10n/l10n.dart';
import '../providers/classroom_provider.dart';
import 'widgets/classroom_card.dart';
import 'widgets/classroom_filter_chips.dart';
import 'widgets/classroom_filter_sheet.dart';

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
      ref.read(classroomListProvider.notifier).loadMore();
    }
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

    return Scaffold(
      body: Column(
        children: [
          LargeTitleBar(
            title: l10n.classroomsTitle,
            showBackButton: false,
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
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
                _FilterButton(
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
            child: RefreshIndicator(
              onRefresh: () =>
                  ref.read(classroomListProvider.notifier).refresh(),
              child: _buildBody(listState),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(ClassroomListState state) {
    final l10n = context.l10n;

    if (state.isLoading && state.pagination.data.isEmpty) {
      return const ListShimmer();
    }

    if (state.error != null && state.pagination.data.isEmpty) {
      return ErrorView(
        message: l10n.classroomsLoadError,
        detail: state.error,
        onRetry: () => ref.read(classroomListProvider.notifier).refresh(),
      );
    }

    if (state.pagination.data.isEmpty) {
      final filtered = state.hasActiveFilters;
      return EmptyState(
        icon: Icons.class_outlined,
        title: l10n.classroomsEmptyTitle,
        subtitle: filtered
            ? l10n.classroomsEmptyFiltered
            : state.search.isNotEmpty
                ? l10n.classroomsEmptySearch
                : l10n.classroomsEmptySubtitle,
        actionLabel: filtered ? l10n.classroomsClearFilters : null,
        onAction: filtered
            ? () => _applySelection(const ClassroomFilterSelection())
            : null,
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      itemCount:
          state.pagination.data.length + (state.pagination.hasMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == state.pagination.data.length) {
          return const Padding(
            padding: EdgeInsets.all(16),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        final classroom = state.pagination.data[index];
        return ClassroomCard(
          classroom: classroom,
          onTap: () => context.push('/classrooms/${classroom.id}'),
        );
      },
    );
  }
}

class _FilterButton extends StatelessWidget {
  final int activeCount;
  final VoidCallback onTap;

  const _FilterButton({required this.activeCount, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final active = activeCount > 0;
    final accent = isDark ? const Color(0xFF6366F1) : AppColors.primary;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: active
                  ? accent
                  : (isDark
                      ? AppColors.darkSearchFill
                      : AppColors.lightSearchFill),
              shape: BoxShape.circle,
            ),
            child: Icon(
              PhosphorIconsRegular.faders,
              size: 20,
              color: active
                  ? Colors.white
                  : (isDark
                      ? AppColors.darkTextSecondary
                      : AppColors.lightTextSecondary),
            ),
          ),
          if (active)
            Positioned(
              top: -2,
              right: -2,
              child: Container(
                width: 18,
                height: 18,
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.darkSurface
                      : AppColors.lightSurface,
                  shape: BoxShape.circle,
                  border: Border.all(color: accent, width: 1.5),
                ),
                child: Center(
                  child: Text(
                    '$activeCount',
                    style: AppTypography.labelSmall.copyWith(
                      color: accent,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
