import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/error_view.dart';
import '../../../core/widgets/loading_shimmer.dart';
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
      ref.read(studentListProvider.notifier).loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final listState = ref.watch(studentListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Students'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                hintText: 'Search students...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
                isDense: true,
                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              onChanged: (value) =>
                  ref.read(studentListProvider.notifier).search(value),
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () =>
                  ref.read(studentListProvider.notifier).refresh(),
              child: _buildBody(listState),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(StudentListState state) {
    if (state.isLoading && state.pagination.data.isEmpty) {
      return const ListShimmer();
    }

    if (state.error != null && state.pagination.data.isEmpty) {
      return ErrorView(
        message: 'Failed to load students',
        detail: state.error,
        onRetry: () => ref.read(studentListProvider.notifier).refresh(),
      );
    }

    if (state.pagination.data.isEmpty) {
      return EmptyState(
        icon: Icons.people_outline,
        title: 'No students found',
        subtitle: state.search.isNotEmpty
            ? 'Try a different search term'
            : 'No students available',
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
        final student = state.pagination.data[index];
        return StudentCard(
          student: student,
          onTap: () => context.push('/students/${student.id}'),
        );
      },
    );
  }
}
