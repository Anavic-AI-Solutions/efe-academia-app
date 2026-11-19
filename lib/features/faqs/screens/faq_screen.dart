import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../app/theme/app_colors.dart';
import '../../../core/pagination/paged_list_notifier.dart';
import '../../../core/widgets/confirm_dialog.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/error_view.dart';
import '../../../core/widgets/inline_error_banner.dart';
import '../../../core/widgets/loading_shimmer.dart';
import '../../../core/widgets/pagination_bar.dart';
import '../../../core/widgets/search_bar.dart';
import '../../../l10n/app_localizations.dart';
import '../../../l10n/l10n.dart';
import '../../auth/domain/user_model.dart';
import '../../auth/providers/auth_provider.dart';
import '../domain/faq_model.dart';
import '../providers/faq_provider.dart';
import 'widgets/faq_form_sheet.dart';
import 'widgets/faq_tile.dart';

class FaqScreen extends ConsumerStatefulWidget {
  const FaqScreen({super.key});

  @override
  ConsumerState<FaqScreen> createState() => _FaqScreenState();
}

class _FaqScreenState extends ConsumerState<FaqScreen> {
  final _searchController = TextEditingController();
  Timer? _searchDebounce;
  String _search = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(faqListProvider.notifier).load();
    });
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 350), () {
      if (!mounted) return;
      _search = value;
      ref.read(faqListProvider.notifier).setSearch(value);
    });
  }

  /// Vuelve a pedir la primera página tras crear, editar o eliminar,
  /// conservando la búsqueda activa.
  void _reloadList() {
    final search = _search.trim();
    ref.invalidate(faqListProvider);
    final notifier = ref.read(faqListProvider.notifier);
    if (search.isEmpty) {
      notifier.load();
    } else {
      notifier.setSearch(search);
    }
  }

  Future<void> _openForm(FaqModel? faq) async {
    final l10n = context.l10n;
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => FaqFormSheet(faq: faq),
    );
    if (saved != true || !mounted) return;
    _reloadList();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(faq == null ? l10n.faqCreated : l10n.faqUpdated),
      ),
    );
  }

  Future<void> _delete(FaqModel faq) async {
    final l10n = context.l10n;
    final confirmed = await showConfirmDialog(
      context,
      title: l10n.faqDeleteTitle,
      message: l10n.commonDeleteMessage,
      confirmLabel: l10n.commonDeleteConfirm,
      cancelLabel: l10n.commonCancel,
      destructive: true,
    );
    if (!confirmed || !mounted) return;

    try {
      await ref.read(faqRepositoryProvider).deleteFaq(faq.id);
      if (!mounted) return;
      _reloadList();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.faqDeleted)),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.commonDeleteError)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final state = ref.watch(faqListProvider);
    final canManage = ref.watch(authProvider).user?.canManageFaqs ?? false;
    final hasPagination =
        state.page.data.isNotEmpty && state.page.totalPages > 1;

    return Scaffold(
      backgroundColor: AppColors.backgroundFor(isDark),
      floatingActionButton: canManage
          ? FloatingActionButton(
              key: const Key('faq-fab'),
              onPressed: () => _openForm(null),
              backgroundColor: AppColors.primary,
              child: const Icon(
                PhosphorIconsRegular.plus,
                color: Colors.white,
              ),
            )
          : null,
      appBar: AppBar(title: Text(l10n.faqsTitle)),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: AppSearchBar(
              controller: _searchController,
              hintText: l10n.faqsSearchHint,
              onChanged: _onSearchChanged,
            ),
          ),
          if (state.error != null && state.page.data.isNotEmpty)
            InlineErrorBanner(
              message: l10n.faqsLoadError,
              onRetry: () => ref.read(faqListProvider.notifier).retry(),
            ),
          Expanded(
            child: _buildBody(state, l10n, canManage: canManage),
          ),
        ],
      ),
      bottomNavigationBar: hasPagination
          ? PaginationBar(
              page: state.page.page,
              totalPages: state.page.totalPages,
              from: state.page.firstItem,
              to: state.page.lastItem,
              total: state.page.total,
              enabled: !state.isLoading,
              onPageChanged: (page) =>
                  ref.read(faqListProvider.notifier).goToPage(page),
            )
          : null,
    );
  }

  Widget _buildBody(
    PagedListState<FaqModel> state,
    AppLocalizations l10n, {
    required bool canManage,
  }) {
    if (state.isLoading && state.page.data.isEmpty) {
      return const ListShimmer();
    }

    if (state.error != null && state.page.data.isEmpty) {
      return ErrorView(
        message: l10n.faqsLoadError,
        detail: state.error,
        onRetry: () => ref.read(faqListProvider.notifier).retry(),
      );
    }

    if (state.page.data.isEmpty) {
      final searching = _search.trim().isNotEmpty;
      return EmptyState(
        icon: PhosphorIconsRegular.question,
        title: l10n.faqsEmptyTitle,
        subtitle: searching ? l10n.faqsEmptySearch : l10n.faqsEmptySubtitle,
      );
    }

    return RefreshIndicator(
      onRefresh: () => ref.read(faqListProvider.notifier).refresh(),
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
        itemCount: state.page.data.length,
        itemBuilder: (context, index) {
          final faq = state.page.data[index];
          return FaqTile(
            key: ValueKey(faq.id),
            faq: faq,
            onEdit: canManage ? () => _openForm(faq) : null,
            onDelete: canManage ? () => _delete(faq) : null,
          );
        },
      ),
    );
  }
}
