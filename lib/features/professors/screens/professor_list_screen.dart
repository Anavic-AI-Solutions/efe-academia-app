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
import '../../classrooms/domain/professor_model.dart';
import '../providers/professor_provider.dart';
import 'widgets/professor_card.dart';

class ProfessorListScreen extends ConsumerStatefulWidget {
  const ProfessorListScreen({super.key});

  @override
  ConsumerState<ProfessorListScreen> createState() =>
      _ProfessorListScreenState();
}

class _ProfessorListScreenState extends ConsumerState<ProfessorListScreen> {
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
    ref.read(professorListProvider.notifier).loadMore();
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(_searchDebounce, () {
      ref.read(professorListProvider.notifier).setSearch(value);
    });
  }

  Future<void> _openCreate() async {
    await context.push<bool>('/professors/new');
    if (!mounted) return;
    await ref.read(professorListProvider.notifier).refresh();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final listState = ref.watch(professorListProvider);
    final canManageProfessors =
        ref.watch(authProvider).user?.canManageProfessors ?? false;

    return Scaffold(
      backgroundColor: AppColors.backgroundFor(isDark),
      floatingActionButton: canManageProfessors
          ? FloatingActionButton(
              key: const Key('professor-list-fab'),
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
          LargeTitleBar(title: l10n.professorsTitle),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: AppSearchBar(
              controller: _searchController,
              hintText: l10n.professorsSearchHint,
              onChanged: _onSearchChanged,
            ),
          ),
          Expanded(child: _buildBody(listState)),
        ],
      ),
    );
  }

  Widget _buildBody(CursorListState<ProfessorModel> state) {
    final l10n = context.l10n;

    if (state.isLoading && state.data.isEmpty) {
      return const ListShimmer();
    }

    if (state.error != null && state.data.isEmpty) {
      return ErrorView(
        message: l10n.professorsLoadError,
        detail: state.error,
        onRetry: () => ref.read(professorListProvider.notifier).refresh(),
      );
    }

    if (state.data.isEmpty) {
      return EmptyState(
        icon: PhosphorIconsRegular.chalkboardTeacher,
        title: l10n.professorsEmptyTitle,
        subtitle: l10n.professorsEmptySubtitle,
      );
    }

    return RefreshIndicator(
      onRefresh: () => ref.read(professorListProvider.notifier).refresh(),
      child: ListView.builder(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
        itemCount: state.data.length +
            ((state.hasMore || state.error != null) ? 1 : 0),
        itemBuilder: (context, index) {
          if (index >= state.data.length) {
            if (state.error != null) {
              return Padding(
                key: const Key('professor-list-load-more-error'),
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Column(
                  children: [
                    Text(
                      l10n.professorsLoadError,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: AppColors.error),
                    ),
                    TextButton(
                      onPressed: () => state.hasMore
                          ? ref.read(professorListProvider.notifier).loadMore()
                          : ref.read(professorListProvider.notifier).refresh(),
                      child: Text(l10n.commonRetry),
                    ),
                  ],
                ),
              );
            }
            return const Padding(
              key: Key('professor-list-load-more'),
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
          final professor = state.data[index];
          return ProfessorCard(
            professor: professor,
            onTap: () => context.push('/professors/${professor.id}'),
          );
        },
      ),
    );
  }
}
