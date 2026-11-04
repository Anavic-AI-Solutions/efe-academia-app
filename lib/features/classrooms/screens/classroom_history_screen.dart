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
    final isParent = role == 'parent';
    final studentId = ref.watch(parentSelectedStudentProvider);

    // Parents can filter by selected child; students see only their own.
    String? effectiveStudentId;
    if (isParent && studentId != null) {
      effectiveStudentId = studentId;
    } else if (role == 'student') {
      final studentData = ref.watch(authProvider).user?.studentData;
      effectiveStudentId = studentData?.id.toString();
    }

    final listState = ref.watch(classroomListProvider);

    ref.listen<String?>(parentSelectedStudentProvider, (next) {
      if (!mounted) return;
      if (role != 'parent') return;
      ref.read(classroomListProvider.notifier).setStudent(next).then((_) {
        if (mounted) _scrollToTop();
      });
    });
    if (isParent) {
      final selected = ref.watch(parentSelectedStudentProvider);
      if (selected != null &&
          selected != listState.studentId &&
          !listState.isLoading) {
        Future.microtask(() {
          if (!mounted) return;
          final want = ref.read(parentSelectedStudentProvider);
          final current = ref.read(classroomListProvider).studentId;
          if (want != null && want != current) {
            ref.read(classroomListProvider.notifier).setStudent(want).then((_) {
              if (mounted) _scrollToTop();
            });
          }
        });
      }
    }

    return Scaffold(
      backgroundColor: AppColors.backgroundFor(isDark),
      appBar: AppBar(
        title: Text(l10n.classroomsTitle),
        actions: [
          if (role != 'student') ...[
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Tooltip(
                message: l10n.chooseChild,
                child: DropdownButton<String>(
                  underline: const SizedBox(),
                  hint: Text(l10n.studentsTitle),
                  value: effectiveStudentId,
                  items: _buildParentChildDropdown(context, role),
                  onChanged: (value) {
                    ref.read(parentSelectedStudentProvider.notifier).state = value;
                  },
                ),
              ),
            ),
          ],
        ],
      ),
      body: Column(
        children: [
          if (isParent && effectiveStudentId == null)
            _buildParentChildSelector(),
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
                if (!isParent) ...[
                  const SizedBox(width: 10),
                  class RoomFilterButton(
                    activeCount: listState.count,
                    onTap: () => _applyFilters(context),
                  ),
                ],
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
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 11),
                    child: ProfessorClassroomListCard(
                      classroom: classroom,
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

  Widget _buildParentChildSelector() {
    final relations = ref.watch(relationsProvider);
    final selected = ref.watch(parentSelectedStudentProvider);
    final children =
        relations.relations.where((r) => r.role == 'student').toList();

    if (children.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: DropdownButtonFormField<String>(
        value: children.any((c) => c.userId.toString() == selected)
            ? selected
            : null,
        hint: Text(context.l10n.studentsTitle),
        items: children
            .map(
              (c) => DropdownMenuItem(
                value: c.userId.toString(),
                child: Text(c.fullname, overflow: TextOverflow.ellipsis),
              ),
            )
            .toList(),
        onChanged: (value) async {
          ref.read(parentSelectedStudentProvider.notifier).state = value;
          await ref.read(classroomListProvider.notifier).setStudent(value);
          _scrollToTop();
        },
      ),
    );
  }

  Widget _buildParentChildDropdown(
      BuildContext context, String? role) {
    final relations = ref.watch(relationsProvider);
    final selected = effectiveStudentId;
    final children =
        relations.relations.where((r) => r.role == 'student').toList();

    if (children.isEmpty) return const [];

    return children.map((c) => DropdownMenuItem<String>(
      value: c.userId.toString(),
      child: Text(c.fullname, overflow: TextOverflow.ellipsis),
    )).toList();
  }

  void _scrollToTop() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(0);
      }
    });
  }

  Future<void> _applyFilters(BuildContext context) async {
    final selection = await showClassroomFilterSheet(
      context,
      initial: ClassroomFilterSelection(
        status: 'archived',
        studentId: effectiveStudentId,
      ),
    );
    if (selection == null) return;
    await _applySelection(selection);
  }

  void _applySelection(ClassroomFilterSelection selection) async {
    if (!mounted) return;
    await ref.read(classroomListProvider.notifier).applyFilters(
          branch: selection.branch,
          level: selection.level,
          year: selection.year,
          status: selection.status,
          studentId: selection.studentId,
        );
    _scrollToTop();
  }
}