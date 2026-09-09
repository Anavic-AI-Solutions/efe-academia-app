import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/error_view.dart';
import '../../../core/widgets/loading_shimmer.dart';
import '../providers/classroom_provider.dart';
import 'widgets/classroom_card.dart';

class ClassroomListScreen extends ConsumerStatefulWidget {
  const ClassroomListScreen({super.key});

  @override
  ConsumerState<ClassroomListScreen> createState() => _ClassroomListScreenState();
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

  @override
  Widget build(BuildContext context) {
    final listState = ref.watch(classroomListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Classrooms'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                hintText: 'Search classrooms...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
                isDense: true,
                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              onChanged: (value) =>
                  ref.read(classroomListProvider.notifier).search(value),
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
    if (state.isLoading && state.pagination.data.isEmpty) {
      return const ListShimmer();
    }

    if (state.error != null && state.pagination.data.isEmpty) {
      return ErrorView(
        message: 'Failed to load classrooms',
        detail: state.error,
        onRetry: () => ref.read(classroomListProvider.notifier).refresh(),
      );
    }

    if (state.pagination.data.isEmpty) {
      return EmptyState(
        icon: Icons.class_outlined,
        title: 'No classrooms found',
        subtitle: state.search.isNotEmpty
            ? 'Try a different search term'
            : 'No classrooms available',
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: state.pagination.data.length + (state.pagination.hasMore ? 1 : 0),
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
