import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/app_colors.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/error_view.dart';
import '../../../core/widgets/large_title_bar.dart';
import '../../../core/widgets/loading_shimmer.dart';
import '../../../core/widgets/search_bar.dart';
import '../../../l10n/app_localizations.dart';
import '../../../l10n/l10n.dart';
import '../providers/qualification_provider.dart';
import 'widgets/qualification_card.dart';

class QualificationListScreen extends ConsumerStatefulWidget {
  const QualificationListScreen({super.key});

  @override
  ConsumerState<QualificationListScreen> createState() =>
      _QualificationListScreenState();
}

class _QualificationListScreenState
    extends ConsumerState<QualificationListScreen> {
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
      ref.read(qualificationListProvider.notifier).loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final listState = ref.watch(qualificationListProvider);
    final l10n = context.l10n;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: AppColors.backgroundFor(isDark),
      body: Column(
        children: [
          LargeTitleBar(title: l10n.qualificationsTitle),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: AppSearchBar(
              controller: _searchController,
              hintText: l10n.qualificationsSearchHint,
              onChanged: (value) =>
                  ref.read(qualificationListProvider.notifier).search(value),
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () =>
                  ref.read(qualificationListProvider.notifier).refresh(),
              child: _buildBody(listState, l10n),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(QualificationListState state, AppLocalizations l10n) {
    if (state.isLoading && state.pagination.data.isEmpty) {
      return const ListShimmer();
    }

    if (state.error != null && state.pagination.data.isEmpty) {
      return ErrorView(
        message: l10n.qualificationsLoadError,
        detail: state.error,
        onRetry: () => ref.read(qualificationListProvider.notifier).refresh(),
      );
    }

    if (state.pagination.data.isEmpty) {
      return EmptyState(
        icon: Icons.grade_outlined,
        title: l10n.qualificationsEmptyTitle,
        subtitle: state.search.isNotEmpty
            ? l10n.qualificationsEmptySearchSubtitle
            : l10n.qualificationsEmptySubtitle,
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: state.pagination.data.length,
      itemBuilder: (context, index) {
        final qualification = state.pagination.data[index];
        return QualificationCard(qualification: qualification);
      },
    );
  }
}
