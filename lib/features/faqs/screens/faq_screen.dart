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
import '../data/faq_repository.dart';
import '../domain/faq_model.dart';
import '../providers/faq_provider.dart';
import 'widgets/faq_tile.dart';

class FaqScreen extends ConsumerStatefulWidget {
  const FaqScreen({super.key});

  @override
  ConsumerState<FaqScreen> createState() => _FaqScreenState();
}

class _FaqScreenState extends ConsumerState<FaqScreen> {
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
    final pagination = ref.watch(faqListProvider);

    // Trigger load on initial build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(faqListProvider.notifier).load(
            search: _searchController.text,
          );
    });

    return Scaffold(
      backgroundColor: AppColors.backgroundFor(isDark),
      appBar: AppBar(
        title: Text(l10n.faqsTitle),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Tooltip(
              message: l10n.commonSearchHint,
              child: IconButton(
                icon: Icon(
                  PhosphorIconsRegular.magnifyingGlass,
                  color: isDark
                      ? AppColors.darkTextTertiary
                      : AppColors.lightTextTertiary,
                ),
                onPressed: () {},
              ),
            ),
          ),
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
                    hintText: l10n.faqsSearchHint,
                    onChanged: (value) =>
                        ref.read(faqListProvider.notifier).load(search: value),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () =>
                  ref.read(faqListProvider.notifier).load(),
              child: ListView.builder(
                controller: _scrollController,
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                itemCount: pagination.data.length,
                itemBuilder: (context, index) {
                  final faq = pagination.data[index];
                  return FaqTile(
                    faq: faq,
                    onTap: () => context.pop(),
                  );
                },
              ),
            ),
          ),
          PaginationBar(
            page: 1,
            totalPages: pagination.total > 0 ? (pagination.total / 10).ceil() : 1,
            from: pagination.data.isEmpty ? 0 : 1,
            to: pagination.data.isEmpty ? 0 : pagination.data.length,
            total: pagination.total,
            enabled: !pagination.isLoading,
            onPageChanged: (page) =>
                ref.read(faqListProvider.notifier).load(cursor: null),
          ),
        ],
      ),
    );
  }
}