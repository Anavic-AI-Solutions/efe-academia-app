import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/app_colors.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/error_view.dart';
import '../../../core/widgets/large_title_bar.dart';
import '../../../core/widgets/loading_shimmer.dart';
import '../../../core/widgets/search_bar.dart';
import '../../../l10n/app_localizations.dart';
import '../../../l10n/l10n.dart';
import '../providers/fee_provider.dart';
import 'widgets/fee_card.dart';

class FeeListScreen extends ConsumerStatefulWidget {
  const FeeListScreen({super.key});

  @override
  ConsumerState<FeeListScreen> createState() => _FeeListScreenState();
}

class _FeeListScreenState extends ConsumerState<FeeListScreen> {
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
      ref.read(feeListProvider.notifier).loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final listState = ref.watch(feeListProvider);
    final l10n = context.l10n;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: AppColors.backgroundFor(isDark),
      body: Column(
        children: [
          LargeTitleBar(title: l10n.feesTitle),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: AppSearchBar(
              controller: _searchController,
              hintText: l10n.feesSearchHint,
              onChanged: (value) =>
                  ref.read(feeListProvider.notifier).search(value),
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => ref.read(feeListProvider.notifier).refresh(),
              child: _buildBody(listState, l10n),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(FeeListState state, AppLocalizations l10n) {
    if (state.isLoading && state.pagination.data.isEmpty) {
      return const ListShimmer();
    }

    if (state.error != null && state.pagination.data.isEmpty) {
      return ErrorView(
        message: l10n.feesLoadError,
        detail: state.error,
        onRetry: () => ref.read(feeListProvider.notifier).refresh(),
      );
    }

    if (state.pagination.data.isEmpty) {
      return EmptyState(
        icon: Icons.receipt_long_outlined,
        title: l10n.feesEmptyTitle,
        subtitle: state.search.isNotEmpty
            ? l10n.feesEmptySearchSubtitle
            : l10n.feesEmptySubtitle,
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: state.pagination.data.length,
      itemBuilder: (context, index) {
        final fee = state.pagination.data[index];
        return FeeCard(
          fee: fee,
          onTap: () => context.push('/fees/${fee.id}'),
        );
      },
    );
  }
}
