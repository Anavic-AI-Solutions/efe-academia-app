import 'package:flutter/material.dart';

import '../pagination/paged_list_notifier.dart';
import 'empty_state.dart';
import 'error_view.dart';
import 'loading_shimmer.dart';
import 'pagination_bar.dart';

class PagedTabList<T> extends StatelessWidget {
  final PagedListState<T> state;
  final ValueChanged<int> onPageChanged;
  final VoidCallback onRetry;
  final Widget Function(BuildContext context, T item) itemBuilder;
  final IconData emptyIcon;
  final String emptyTitle;
  final String errorMessage;

  const PagedTabList({
    super.key,
    required this.state,
    required this.onPageChanged,
    required this.onRetry,
    required this.itemBuilder,
    required this.emptyIcon,
    required this.emptyTitle,
    required this.errorMessage,
  });

  @override
  Widget build(BuildContext context) {
    if (state.isLoading && state.page.data.isEmpty) {
      return const ListShimmer(itemCount: 4, itemHeight: 64);
    }

    if (state.error != null && state.page.data.isEmpty) {
      return ErrorView(
        message: errorMessage,
        detail: state.error,
        onRetry: onRetry,
      );
    }

    if (state.page.data.isEmpty) {
      return EmptyState(icon: emptyIcon, title: emptyTitle);
    }

    return Column(
      children: [
        if (state.isLoading) const LinearProgressIndicator(minHeight: 2),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
            itemCount: state.page.data.length,
            itemBuilder: (context, index) =>
                itemBuilder(context, state.page.data[index]),
          ),
        ),
        PaginationBar(
          page: state.page.page,
          totalPages: state.page.totalPages,
          from: state.page.firstItem,
          to: state.page.lastItem,
          total: state.page.total,
          enabled: !state.isLoading,
          onPageChanged: onPageChanged,
        ),
      ],
    );
  }
}
