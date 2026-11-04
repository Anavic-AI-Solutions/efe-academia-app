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
import '../../auth/providers/auth_provider.dart';
import '../providers/classroom_provider.dart';
import '../domain/classroom_model.dart';

class ClassroomHistoryScreen extends ConsumerStatefulWidget {
  const ClassroomHistoryScreen({super.key});

  @override
  ConsumerState<ClassroomHistoryScreen> createState() =>
      _ClassroomHistoryScreenState();
}

class _ClassroomHistoryScreenState extends ConsumerState<ClassroomHistoryScreen> {
  final _scrollController = ScrollController();
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final role = ref.watch(authProvider).user?.role;

    final listState = ref.watch(classroomListProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundFor(isDark),
      appBar: AppBar(
        title: Text(l10n.classroomsTitle),
      ),
      body: Column(
        children: [
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
              ],
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => ref.read(classroomListProvider.notifier).refresh(),
              child: ListView.builder(
                controller: _scrollController,
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                itemCount: listState.page.data.length,
                itemBuilder: (context, index) {
                  final classroom = listState.page.data[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 11),
                    child: ListTile(
                      title: Text(classroom.name),
                      subtitle: Text(classroom.description),
                      onTap: () =>
                          context.push('/classrooms/${classroom.id}'),
                    ),
                  );
                },
              ),
            ),
          ),
          PaginationBar(
            page: listState.page.page,
            totalPages: listState.page.totalPages,
            from: listState.page.firstItem,
            to: listState.page.lastItem,
            total: listState.page.total,
            enabled: !listState.isLoading,
            onPageChanged: (page) =>
                ref.read(classroomListProvider.notifier).goToPage(page),
          ),
        ],
      ),
    );
  }
}
