import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../app/theme/app_colors.dart';
import '../../../core/pagination/cursor_list_notifier.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/error_view.dart';
import '../../../core/widgets/large_title_bar.dart';
import '../../../core/widgets/loading_shimmer.dart';
import '../../../core/widgets/search_bar.dart';
import '../../../l10n/l10n.dart';
import '../../auth/domain/user_model.dart';
import '../../auth/providers/auth_provider.dart';
import '../domain/parent_model.dart';
import '../providers/parent_provider.dart';
import 'widgets/parent_card.dart';

class ParentListScreen extends ConsumerStatefulWidget {
  const ParentListScreen({super.key});

  @override
  ConsumerState<ParentListScreen> createState() => _ParentListScreenState();
}

class _ParentListScreenState extends ConsumerState<ParentListScreen> {
  static const _searchDebounce = Duration(milliseconds: 300);

  final _scrollController = ScrollController();
  final _searchController = TextEditingController();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    if (_scrollController.position.extentAfter > 280) return;
    ref.read(parentListProvider.notifier).loadMore();
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(_searchDebounce, () {
      ref.read(parentListProvider.notifier).setSearch(value);
    });
  }

  Future<void> _openCreate() async {
    await context.push<bool>('/parents/new');
    if (!mounted) return;
    await ref.read(parentListProvider.notifier).refresh();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final listState = ref.watch(parentListProvider);
    final canManageParents =
        ref.watch(authProvider).user?.canManageParents ?? false;

    return Scaffold(
      backgroundColor: AppColors.backgroundFor(isDark),
      floatingActionButton: canManageParents
          ? FloatingActionButton(
              key: const Key('parent-list-fab'),
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
          LargeTitleBar(title: l10n.parentsTitle),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: AppSearchBar(
              controller: _searchController,
              hintText: l10n.parentsSearchHint,
              onChanged: _onSearchChanged,
            ),
          ),
          Expanded(child: _buildBody(listState)),
        ],
      ),
    );
  }

  Widget _buildBody(CursorListState<ParentModel> state) {
    final l10n = context.l10n;

    if (state.isLoading && state.data.isEmpty) {
      return const ListShimmer();
    }

    if (state.error != null && state.data.isEmpty) {
      return ErrorView(
        message: l10n.parentsLoadError,
        detail: state.error,
        onRetry: () => ref.read(parentListProvider.notifier).refresh(),
      );
    }

    if (state.data.isEmpty) {
      return EmptyState(
        icon: PhosphorIconsRegular.users,
        title: l10n.parentsEmptyTitle,
        subtitle: l10n.parentsEmptySubtitle,
      );
    }

    return RefreshIndicator(
      onRefresh: () => ref.read(parentListProvider.notifier).refresh(),
      child: ListView.builder(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
        itemCount: state.data.length + (state.hasMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index >= state.data.length) {
            return const Padding(
              key: Key('parent-list-load-more'),
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Center(
                child: SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            );
          }
          final parent = state.data[index];
          return ParentCard(
            parent: parent,
            onTap: () => context.push('/parents/${parent.id}'),
          );
        },
      ),
    );
  }
}
