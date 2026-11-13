import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/error_view.dart';
import '../../../core/widgets/inline_error_banner.dart';
import '../../../core/widgets/loading_shimmer.dart';
import '../../../core/widgets/pagination_bar.dart';
import '../../../core/widgets/search_bar.dart';
import '../../../core/widgets/status_badge.dart';
import '../../../l10n/app_localizations.dart';
import '../../../l10n/l10n.dart';
import '../../auth/providers/auth_provider.dart';
import '../../relations/providers/relations_provider.dart';
import '../../relations/providers/selected_child_provider.dart';
import '../domain/classroom_model.dart';
import '../providers/classroom_provider.dart';

/// Archived classrooms for the current role.
///
/// Parents must pick one of their children: the provider is scoped by the
/// backend to that student, so a parent can never see another child's history.
class ClassroomHistoryScreen extends ConsumerStatefulWidget {
  const ClassroomHistoryScreen({super.key});

  @override
  ConsumerState<ClassroomHistoryScreen> createState() =>
      _ClassroomHistoryScreenState();
}

class _ClassroomHistoryScreenState
    extends ConsumerState<ClassroomHistoryScreen> {
  final _scrollController = ScrollController();
  final _searchController = TextEditingController();
  Timer? _searchDebounce;
  bool _didInitialLoad = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _ensureInitialLoad();
    });
  }

  /// Runs the first request only once, and only after auth has resolved.
  /// Parents must choose a child before any history request is made.
  void _ensureInitialLoad() {
    if (!mounted || _didInitialLoad) return;
    final auth = ref.read(authProvider);
    if (auth.status != AuthStatus.authenticated) return;

    _didInitialLoad = true;
    if (auth.user?.role == 'parent') {
      final selected = ref.read(parentSelectedStudentProvider);
      if (selected != null) {
        ref.read(classroomHistoryProvider.notifier).setStudent(selected);
      }
      return;
    }
    ref.read(classroomHistoryProvider.notifier).load();
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _scrollToTop() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(0);
      }
    });
  }

  void _onSearchChanged(String value) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 350), () {
      if (!mounted) return;
      ref.read(classroomHistoryProvider.notifier).search(value);
      _scrollToTop();
    });
  }

  void _onChildChanged(String? value) {
    if (value == null) return;
    ref.read(parentSelectedStudentProvider.notifier).state = value;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final role = ref.watch(authProvider).user?.role ?? '';
    final isParent = role == 'parent';
    final state = ref.watch(classroomHistoryProvider);

    ref.listen<AuthState>(authProvider, (_, __) => _ensureInitialLoad());

    ref.listen<String?>(authProvider.select((state) => state.user?.role), (
      previous,
      next,
    ) {
      if (previous == null || previous == next) return;
      _didInitialLoad = false;
      _ensureInitialLoad();
    });

    ref.listen<String?>(parentSelectedStudentProvider, (_, next) {
      if (!mounted || !isParent || next == null) return;
      final current = ref.read(classroomHistoryProvider).studentId;
      if (current == next) return;
      ref.read(classroomHistoryProvider.notifier).setStudent(next);
      _scrollToTop();
    });

    return Scaffold(
      backgroundColor: AppColors.backgroundFor(isDark),
      appBar: AppBar(title: Text(l10n.historyTitle)),
      body: Column(
        children: [
          if (isParent) _buildChildSelector(l10n),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: AppSearchBar(
              controller: _searchController,
              hintText: l10n.historySearchHint,
              onChanged: _onSearchChanged,
            ),
          ),
          if (state.error != null && state.page.data.isNotEmpty)
            InlineErrorBanner(
              message: l10n.historyLoadError,
              onRetry: () =>
                  ref.read(classroomHistoryProvider.notifier).retry(),
            ),
          Expanded(
            child: _buildBody(state, isParent: isParent, l10n: l10n),
          ),
          if ((!isParent || state.studentId != null) &&
              state.page.data.isNotEmpty &&
              state.page.totalPages > 1)
            PaginationBar(
              page: state.page.page,
              totalPages: state.page.totalPages,
              from: state.page.firstItem,
              to: state.page.lastItem,
              total: state.page.total,
              enabled: !state.isLoading,
              onPageChanged: (page) {
                ref.read(classroomHistoryProvider.notifier).goToPage(page);
                _scrollToTop();
              },
            ),
        ],
      ),
    );
  }

  Widget _buildChildSelector(AppLocalizations l10n) {
    final relations = ref.watch(relationsProvider);
    final selected = ref.watch(parentSelectedStudentProvider);
    final children = relations.relations.where(
      (relation) => relation.role == 'student',
    );

    if (children.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: DropdownButtonFormField<String>(
        value: children.any((child) => child.userId.toString() == selected)
            ? selected
            : null,
        hint: Text(l10n.studentsTitle),
        items: children
            .map(
              (child) => DropdownMenuItem(
                value: child.userId.toString(),
                child: Text(child.fullname, overflow: TextOverflow.ellipsis),
              ),
            )
            .toList(),
        onChanged: _onChildChanged,
      ),
    );
  }

  Widget _buildBody(
    ClassroomListState state, {
    required bool isParent,
    required AppLocalizations l10n,
  }) {
    if (isParent && state.studentId == null) {
      return EmptyState(
        icon: PhosphorIconsRegular.users,
        title: l10n.historyChooseChild,
      );
    }

    if (state.isLoading && state.page.data.isEmpty) {
      return const ListShimmer();
    }

    if (state.error != null && state.page.data.isEmpty) {
      return ErrorView(
        message: l10n.historyLoadError,
        detail: state.error,
        onRetry: () => ref.read(classroomHistoryProvider.notifier).retry(),
      );
    }

    if (state.page.data.isEmpty) {
      final searching = state.search.trim().isNotEmpty;
      return EmptyState(
        icon: PhosphorIconsRegular.clockCounterClockwise,
        title: l10n.historyEmptyTitle,
        subtitle: searching
            ? l10n.historyEmptySearch
            : l10n.historyEmptySubtitle,
      );
    }

    return RefreshIndicator(
      onRefresh: () => ref.read(classroomHistoryProvider.notifier).refresh(),
      child: ListView.builder(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
        itemCount: state.page.data.length,
        itemBuilder: (context, index) {
          return _ArchivedClassroomCard(classroom: state.page.data[index]);
        },
      ),
    );
  }
}

class _ArchivedClassroomCard extends StatelessWidget {
  final ClassroomModel classroom;

  const _ArchivedClassroomCard({required this.classroom});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = AppColors.accentFor(isDark);
    final subtitle = [
      classroom.year,
      classroom.level,
      classroom.shift,
    ].where((value) => value.isNotEmpty).join(' · ');

    return AppCard(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: accent.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              PhosphorIconsRegular.clockCounterClockwise,
              color: accent,
              size: 20,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  classroom.name,
                  style: AppTypography.titleSmall.copyWith(
                    color: isDark
                        ? AppColors.darkTextPrimary
                        : AppColors.lightTextPrimary,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (classroom.description.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(
                    classroom.description,
                    style: AppTypography.bodySmall.copyWith(
                      color: isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.lightTextSecondary,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                if (subtitle.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    subtitle,
                    style: AppTypography.labelSmall.copyWith(
                      color: isDark
                          ? AppColors.darkTextTertiary
                          : AppColors.lightTextTertiary,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          StatusBadge(
            status: 'archived',
            label: l10n.historyArchivedBadge,
            color: isDark
                ? AppColors.darkTextTertiary
                : AppColors.lightTextTertiary,
          ),
        ],
      ),
    );
  }
}
