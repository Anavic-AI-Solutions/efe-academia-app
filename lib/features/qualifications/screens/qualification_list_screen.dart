import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/error_view.dart';
import '../../../core/widgets/loading_shimmer.dart';
import '../providers/qualification_provider.dart';
import 'widgets/qualification_card.dart';

class QualificationListScreen extends ConsumerStatefulWidget {
  const QualificationListScreen({super.key});

  @override
  ConsumerState<QualificationListScreen> createState() =>
      _QualificationListScreenState();
}

class _QualificationListScreenState extends ConsumerState<QualificationListScreen> {
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

    return Scaffold(
      appBar: AppBar(
        title: const Text('Qualifications'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                hintText: 'Search qualifications...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
                isDense: true,
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              onChanged: (value) =>
                  ref.read(qualificationListProvider.notifier).search(value),
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () =>
                  ref.read(qualificationListProvider.notifier).refresh(),
              child: _buildBody(listState),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(QualificationListState state) {
    if (state.isLoading && state.pagination.data.isEmpty) {
      return const ListShimmer();
    }

    if (state.error != null && state.pagination.data.isEmpty) {
      return ErrorView(
        message: 'Failed to load qualifications',
        detail: state.error,
        onRetry: () =>
            ref.read(qualificationListProvider.notifier).refresh(),
      );
    }

    if (state.pagination.data.isEmpty) {
      return EmptyState(
        icon: Icons.grade_outlined,
        title: 'No qualifications found',
        subtitle: state.search.isNotEmpty
            ? 'Try a different search term'
            : 'No qualifications available',
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount:
          state.pagination.data.length + (state.pagination.hasMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == state.pagination.data.length) {
          return const Padding(
            padding: EdgeInsets.all(16),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        final qualification = state.pagination.data[index];
        return QualificationCard(qualification: qualification);
      },
    );
  }
}
