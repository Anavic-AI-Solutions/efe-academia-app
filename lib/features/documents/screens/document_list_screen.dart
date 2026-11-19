import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../app/theme/app_colors.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/error_view.dart';
import '../../../core/widgets/large_title_bar.dart';
import '../../../core/widgets/loading_shimmer.dart';
import '../../../l10n/l10n.dart';
import '../../auth/domain/user_model.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/document_provider.dart';
import 'widgets/document_form_sheet.dart';
import 'widgets/document_tile.dart';

/// Lista de documentos: shimmer / vacío / error / scroll infinito. El staff
/// ve el FAB para crear.
class DocumentListScreen extends ConsumerStatefulWidget {
  const DocumentListScreen({super.key});

  @override
  ConsumerState<DocumentListScreen> createState() => _DocumentListScreenState();
}

class _DocumentListScreenState extends ConsumerState<DocumentListScreen> {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      ref.read(documentListProvider.notifier).loadMore();
    }
  }

  Future<void> _openForm() async {
    final l10n = context.l10n;
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const DocumentFormSheet(document: null),
    );
    if (saved != true || !mounted) return;
    ref.invalidate(documentListProvider);
    ref.invalidate(homeDocumentsProvider);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.documentCreated)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final state = ref.watch(documentListProvider);
    final documents = state.pagination.data;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final canManage = ref.watch(authProvider).user?.canManageDocuments ?? false;

    return Scaffold(
      backgroundColor: AppColors.backgroundFor(isDark),
      floatingActionButton: canManage
          ? FloatingActionButton(
              key: const Key('document-fab'),
              tooltip: l10n.commonCreate,
              onPressed: _openForm,
              backgroundColor: AppColors.primary,
              child: const Icon(
                PhosphorIconsRegular.plus,
                color: Colors.white,
              ),
            )
          : null,
      body: Column(
        children: [
          LargeTitleBar(title: l10n.documentsTitle),
          Expanded(
            child: state.isLoading && documents.isEmpty
                ? const ListShimmer()
                : state.error != null && documents.isEmpty
                    ? ErrorView(
                        message: l10n.documentsTitle,
                        detail: state.error,
                        onRetry: () =>
                            ref.read(documentListProvider.notifier).refresh(),
                      )
                    : documents.isEmpty
                        ? EmptyState(
                            icon: PhosphorIconsRegular.fileText,
                            title: l10n.documentsEmpty,
                          )
                        : RefreshIndicator(
                            onRefresh: () => ref
                                .read(documentListProvider.notifier)
                                .refresh(),
                            child: ListView.builder(
                              controller: _scrollController,
                              padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                              itemCount: documents.length +
                                  (state.pagination.hasMore ? 1 : 0),
                              itemBuilder: (context, index) {
                                if (index == documents.length) {
                                  return const Padding(
                                    padding:
                                        EdgeInsets.only(top: 4, bottom: 12),
                                    child: LoadingShimmer(
                                      width: double.infinity,
                                      height: 68,
                                    ),
                                  );
                                }
                                final document = documents[index];
                                return DocumentTile(
                                  document: document,
                                  onTap: () => context.push(
                                    '/documents/${document.id}',
                                  ),
                                );
                              },
                            ),
                          ),
          ),
        ],
      ),
    );
  }
}
