import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/error_view.dart';
import '../../../core/widgets/inline_error_banner.dart';
import '../../../core/widgets/large_title_bar.dart';
import '../../../core/widgets/loading_shimmer.dart';
import '../../../core/widgets/pagination_bar.dart';
import '../../../core/widgets/search_bar.dart';
import '../../../l10n/app_localizations.dart';
import '../../../l10n/l10n.dart';
import '../domain/request_model.dart';
import '../providers/request_provider.dart';
import 'widgets/request_tile.dart';

class RequestListScreen extends ConsumerStatefulWidget {
  const RequestListScreen({super.key});

  @override
  ConsumerState<RequestListScreen> createState() => _RequestListScreenState();
}

class _RequestListScreenState extends ConsumerState<RequestListScreen> {
  final _searchController = TextEditingController();
  Timer? _searchDebounce;

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 350), () {
      if (!mounted) return;
      ref.read(requestListProvider.notifier).setSearch(value);
    });
  }

  Future<void> _openRequest(RequestModel request) async {
    final changed = await context.push<bool>(
      '/requests/${request.kind.name}/${request.id}',
    );
    if (changed == true && mounted) {
      await ref.read(requestListProvider.notifier).refresh();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final state = ref.watch(requestListProvider);
    final notifier = ref.read(requestListProvider.notifier);

    return Scaffold(
      backgroundColor: AppColors.backgroundFor(isDark),
      body: Column(
        children: [
          LargeTitleBar(title: l10n.requestsTitle),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: AppSearchBar(
              controller: _searchController,
              hintText: l10n.requestsSearchHint,
              onChanged: _onSearchChanged,
            ),
          ),
          SizedBox(
            height: 36,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                _FilterChip(
                  label: l10n.studentsStatusPending,
                  selected: state.status == 'pending',
                  onTap: () => notifier.setStatus('pending'),
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: l10n.studentsStatusApproved,
                  selected: state.status == 'approved',
                  onTap: () => notifier.setStatus('approved'),
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: l10n.studentsStatusRejected,
                  selected: state.status == 'rejected',
                  onTap: () => notifier.setStatus('rejected'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 36,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                _FilterChip(
                  label: l10n.requestsTypeAll,
                  selected: state.type == 'all',
                  onTap: () => notifier.setType('all'),
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: l10n.requestsTypeStudents,
                  selected: state.type == 'student',
                  onTap: () => notifier.setType('student'),
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: l10n.requestsTypeParents,
                  selected: state.type == 'parent',
                  onTap: () => notifier.setType('parent'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          if (state.error != null && state.page.data.isNotEmpty)
            InlineErrorBanner(
              message: l10n.requestsLoadError,
              onRetry: notifier.retry,
            ),
          Expanded(child: _buildBody(state, l10n)),
          if (state.page.data.isNotEmpty && state.page.totalPages > 1)
            PaginationBar(
              page: state.page.page,
              totalPages: state.page.totalPages,
              from: state.page.firstItem,
              to: state.page.lastItem,
              total: state.page.total,
              enabled: !state.isLoading,
              onPageChanged: notifier.goToPage,
            ),
        ],
      ),
    );
  }

  Widget _buildBody(RequestListState state, AppLocalizations l10n) {
    if (state.isLoading && state.page.data.isEmpty) {
      return const ListShimmer();
    }

    if (state.error != null && state.page.data.isEmpty) {
      return ErrorView(
        message: l10n.requestsLoadError,
        detail: state.error,
        onRetry: () => ref.read(requestListProvider.notifier).retry(),
      );
    }

    if (state.page.data.isEmpty) {
      return EmptyState(
        icon: PhosphorIconsRegular.clipboardText,
        title: l10n.requestsEmptyTitle,
        subtitle: state.search.isNotEmpty
            ? l10n.requestsEmptySearch
            : l10n.requestsEmptySubtitle,
      );
    }

    return RefreshIndicator(
      onRefresh: () => ref.read(requestListProvider.notifier).refresh(),
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
        itemCount: state.page.data.length,
        itemBuilder: (context, index) {
          final request = state.page.data[index];
          return RequestTile(
            key: ValueKey('${request.kind.name}-${request.id}'),
            request: request,
            onTap: () => _openRequest(request),
          );
        },
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
