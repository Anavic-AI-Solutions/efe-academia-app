import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../app/theme/app_colors.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/error_view.dart';
import '../../../core/widgets/inline_error_banner.dart';
import '../../../core/widgets/loading_shimmer.dart';
import '../../../core/widgets/pagination_bar.dart';
import '../../../core/widgets/search_bar.dart';
import '../../../l10n/app_localizations.dart';
import '../../../l10n/l10n.dart';
import '../domain/classroom_model.dart';
import '../providers/classroom_provider.dart';
import 'widgets/professor_classroom_list_card.dart';

/// Stacked "Cursos" section for parents.
///
/// Shows every course of every child linked to the parent, without a child
/// selector. The backend request carries no `student_id`, so it returns all
/// the linked children's classrooms.
class ParentCoursesScreen extends ConsumerStatefulWidget {
  const ParentCoursesScreen({super.key});

  @override
  ConsumerState<ParentCoursesScreen> createState() =>
      _ParentCoursesScreenState();
}

class _ParentCoursesScreenState extends ConsumerState<ParentCoursesScreen> {
  final _scrollController = ScrollController();
  final _searchController = TextEditingController();
  Timer? _searchDebounce;

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 350), () {
      if (!mounted) return;
      ref.read(parentCoursesProvider.notifier).search(value);
    });
  }

  void _goToPage(int page) {
    ref.read(parentCoursesProvider.notifier).goToPage(page);
  }

  void _openCourse(ClassroomModel classroom) {
    context.push('/parent-courses/${classroom.id}');
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final state = ref.watch(parentCoursesProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundFor(isDark),
      appBar: AppBar(title: Text(l10n.menuCourses)),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: AppSearchBar(
              controller: _searchController,
              hintText: l10n.classroomsSearchHint,
              onChanged: _onSearchChanged,
            ),
          ),
          if (state.error != null && state.page.data.isNotEmpty)
            InlineErrorBanner(
              message: l10n.classroomsLoadError,
              onRetry: () => ref.read(parentCoursesProvider.notifier).retry(),
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
              onPageChanged: _goToPage,
            ),
        ],
      ),
    );
  }

  Widget _buildBody(ClassroomListState state, AppLocalizations l10n) {
    if (state.isLoading && state.page.data.isEmpty) {
      return const ListShimmer();
    }

    if (state.error != null && state.page.data.isEmpty) {
      return ErrorView(
        message: l10n.classroomsLoadError,
        detail: state.error,
        onRetry: () => ref.read(parentCoursesProvider.notifier).retry(),
      );
    }

    if (state.page.data.isEmpty) {
      return EmptyState(
        icon: PhosphorIconsRegular.chalkboardTeacher,
        title: l10n.classroomsEmptyTitle,
        subtitle: state.search.isEmpty
            ? l10n.classroomsEmptySubtitle
            : l10n.classroomsEmptySearch,
      );
    }

    return Column(
      children: [
        if (state.isLoading) const LinearProgressIndicator(minHeight: 2),
        Expanded(
          child: RefreshIndicator(
            onRefresh: () => ref.read(parentCoursesProvider.notifier).refresh(),
            child: ListView.builder(
              controller: _scrollController,
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
              itemCount: state.page.data.length,
              itemBuilder: (context, index) {
                final classroom = state.page.data[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 11),
                  child: ProfessorClassroomListCard(
                    classroom: classroom,
                    onTap: () => _openCourse(classroom),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}
