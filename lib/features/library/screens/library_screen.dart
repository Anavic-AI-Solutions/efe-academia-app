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
import '../../library/data/library_repository.dart';
import 'widgets/material_tile.dart';

class LibraryScreen extends ConsumerStatefulWidget {
  const LibraryScreen({super.key});

  @override
  ConsumerState<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends ConsumerState<LibraryScreen> {
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
    final role = ref.watch(authProvider).user?.role ?? 'student';
    final isParent = role == 'parent';
    final isStudent = role == 'student';

    // Students can only see their own materials, parents see their children's,
    // admins and professors see all.
    String? studentId;
    if (isStudent) {
      final sd = ref.watch(authProvider).user?.studentData;
      studentId = sd?.id.toString();
    }

    final pagination = ref.watch(libraryProvider);

    // Trigger load on initial build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(libraryProvider.notifier).load(
            search: _searchController.text,
          );
    });

    return Scaffold(
      backgroundColor: AppColors.backgroundFor(isDark),
      appBar: AppBar(
        title: Text(l10n.libraryTitle),
        actions: [
          if (!isStudent) ...[
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Tooltip(
                message: l10n.chooseChild,
                child: DropdownButton<String>(
                  underline: const SizedBox(),
                  hint: Text(l10n.studentsTitle),
                  value: isParent ? ref.watch(parentSelectedStudentProvider) : null,
                  items: isParent
                      ? _buildParentChildItems(context)
                      : const [],
                  onChanged: (value) {
                    if (isParent && value != null) {
                      ref.read(parentSelectedStudentProvider.notifier).state = value;
                    }
                  },
                ),
              ),
            ),
          ],
        ],
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
                    hintText: l10n.librarySearchHint,
                    onChanged: (value) =>
                        ref.read(libraryProvider.notifier).load(search: value),
                  ),
                ),
                if (!isStudent) ...[
                  const SizedBox(width: 10),
                  class RoomFilterButton(
                    activeCount: pagination.data.length,
                    onTap: () {},
                  ),
                ],
              ],
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () =>
                  ref.read(libraryProvider.notifier).load(),
              child: ListView.builder(
                controller: _scrollController,
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                itemCount: pagination.data.length,
                itemBuilder: (context, index) {
                  final material = pagination.data[index];
                  return MaterialTile(
                    material: material,
                    canManage: _canManage(role),
                    onOpenUrl: _onOpenUrl(material),
                  );
                },
              ),
            ),
          ),
          PaginationBar(
            page: 1,
            totalPages: pagination.total > 0 ? (pagination.total / 20).ceil() : 1,
            from: pagination.data.isEmpty ? 0 : pagination.data.first == null ? 1 : 1,
            to: pagination.data.isEmpty ? 0 : pagination.data.length,
            total: pagination.total,
            enabled: !pagination.isLoading,
            onPageChanged: (page) =>
                ref.read(libraryProvider.notifier).load(cursor: null),
          ),
        ],
      ),
    );
  }

  bool _canManage(String role) {
    return role == 'professor' || role == 'admin' || role == 'sede';
  }

  VoidCallback? _onOpenUrl(MaterialModel material) {
    if (material.publicUrl == null || material.publicUrl!.isEmpty) {
      return null;
    }
    return () => launch(material.publicUrl!);
  }

  List<DropdownMenuItem<String>> _buildParentChildItems(
      BuildContext context) {
    final relations = ref.watch(relationsProvider);
    final selected = ref.watch(parentSelectedStudentProvider);
    final children =
        relations.relations.where((r) => r.role == 'student').toList();

    if (children.isEmpty) return const [];

    return children.map((c) => DropdownMenuItem<String>(
      value: c.userId.toString(),
      child: Text(c.fullname, overflow: TextOverflow.ellipsis),
    )).toList();
  }
}