import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:intl/intl.dart';

import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/confirm_dialog.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/error_view.dart';
import '../../../core/widgets/large_title_bar.dart';
import '../../../core/widgets/loading_shimmer.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../l10n/l10n.dart';
import '../../auth/domain/user_model.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/news_provider.dart';
import '../domain/news_model.dart';
import 'widgets/news_form_sheet.dart';

class NewsListScreen extends ConsumerStatefulWidget {
  const NewsListScreen({super.key});

  @override
  ConsumerState<NewsListScreen> createState() => _NewsListScreenState();
}

class _NewsListScreenState extends ConsumerState<NewsListScreen> {
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
      ref.read(newsListProvider.notifier).loadMore();
    }
  }

  Future<void> _openForm(NewsModel? news) async {
    final l10n = context.l10n;
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => NewsFormSheet(news: news),
    );
    if (saved != true || !mounted) return;
    ref.invalidate(newsListProvider);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(news == null ? l10n.newsCreated : l10n.newsUpdated),
      ),
    );
  }

  Future<void> _delete(NewsModel news) async {
    final l10n = context.l10n;
    final confirmed = await showConfirmDialog(
      context,
      title: l10n.newsDeleteTitle,
      message: l10n.commonDeleteMessage,
      confirmLabel: l10n.commonDeleteConfirm,
      cancelLabel: l10n.commonCancel,
      destructive: true,
    );
    if (!confirmed || !mounted) return;

    try {
      await ref.read(newsRepositoryProvider).deleteNews(news.id);
      if (!mounted) return;
      ref.invalidate(newsListProvider);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.newsDeleted)),
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
    final state = ref.watch(newsListProvider);
    final news = state.pagination.data;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final canManage = ref.watch(authProvider).user?.canManageNews ?? false;

    return Scaffold(
      backgroundColor: AppColors.backgroundFor(isDark),
      floatingActionButton: canManage
          ? FloatingActionButton(
              key: const Key('news-fab'),
              tooltip: l10n.commonCreate,
              onPressed: () => _openForm(null),
              backgroundColor: AppColors.primary,
              child: const Icon(
                PhosphorIconsRegular.plus,
                color: Colors.white,
              ),
            )
          : null,
      body: Column(
        children: [
          LargeTitleBar(title: l10n.newsTitle),
          Expanded(
            child: state.isLoading && news.isEmpty
                ? const ListShimmer()
                : state.error != null && news.isEmpty
                    ? ErrorView(
                        message: l10n.newsErrorTitle,
                        detail: state.error,
                        onRetry: () =>
                            ref.read(newsListProvider.notifier).refresh(),
                      )
                    : news.isEmpty
                        ? EmptyState(
                            icon: PhosphorIconsRegular.article,
                            title: l10n.newsEmptyTitle,
                            subtitle: l10n.newsEmptySubtitle,
                          )
                        : RefreshIndicator(
                            onRefresh: () =>
                                ref.read(newsListProvider.notifier).refresh(),
                            child: ListView.builder(
                              controller: _scrollController,
                              padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                              itemCount: news.length +
                                  (state.pagination.hasMore ? 1 : 0),
                              itemBuilder: (context, index) {
                                if (index == news.length) {
                                  return const Padding(
                                    padding:
                                        EdgeInsets.only(top: 4, bottom: 12),
                                    child: LoadingShimmer(
                                      width: double.infinity,
                                      height: 68,
                                    ),
                                  );
                                }
                                final item = news[index];
                                return _NewsCard(
                                  news: item,
                                  canManage: canManage,
                                  onEdit:
                                      canManage ? () => _openForm(item) : null,
                                  onDelete:
                                      canManage ? () => _delete(item) : null,
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

class _NewsCard extends StatelessWidget {
  final NewsModel news;
  final bool canManage;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const _NewsCard({
    required this.news,
    this.canManage = false,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = context.l10n;
    final imageUrl = news.mediaUrls.isNotEmpty ? news.mediaUrls.first : null;

    return AppCard(
      margin: const EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            height: 140,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: isDark
                  ? AppColors.darkSurfaceElevated
                  : AppColors.lightSearchFill,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: imageUrl == null
                ? _placeholder(isDark)
                : Image.network(
                    imageUrl,
                    key: Key('news-image-${news.id}'),
                    width: double.infinity,
                    height: 140,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _placeholder(isDark),
                  ),
          ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        news.title,
                        style: AppTypography.titleMedium.copyWith(
                          color: isDark
                              ? AppColors.darkTextPrimary
                              : AppColors.lightTextPrimary,
                        ),
                      ),
                    ),
                    if (canManage)
                      PopupMenuButton<String>(
                        key: Key('news-menu-${news.id}'),
                        padding: EdgeInsets.zero,
                        icon: Icon(
                          PhosphorIconsRegular.dotsThreeVertical,
                          size: 20,
                          color: AppColors.mutedFor(isDark),
                        ),
                        onSelected: (value) {
                          if (value == 'edit') {
                            onEdit?.call();
                          } else {
                            onDelete?.call();
                          }
                        },
                        itemBuilder: (context) => [
                          PopupMenuItem(
                            value: 'edit',
                            child: Text(l10n.commonEdit),
                          ),
                          PopupMenuItem(
                            value: 'delete',
                            child: Text(l10n.commonDelete),
                          ),
                        ],
                      ),
                  ],
                ),
                if (news.description.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    news.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.bodySmall.copyWith(
                      color: isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.lightTextSecondary,
                    ),
                  ),
                ],
                if (news.eventDate != null) ...[
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(
                        PhosphorIconsRegular.calendar,
                        size: 13,
                        color: AppColors.accentFor(isDark),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        DateFormat('MMM d, yyyy').format(news.eventDate!),
                        style: AppTypography.labelSmall.copyWith(
                          color: AppColors.accentFor(isDark),
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 8),
                Text(
                  news.content,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.bodySmall.copyWith(
                    color: isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.lightTextSecondary,
                  ),
                ),
                if (news.createdAt != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    DateFormat('MMM d, yyyy').format(news.createdAt!),
                    style: AppTypography.labelSmall.copyWith(
                      color: AppColors.mutedFor(isDark),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _placeholder(bool isDark) {
    return Center(
      child: Icon(
        PhosphorIconsRegular.newspaper,
        size: 40,
        color: AppColors.mutedFor(isDark),
      ),
    );
  }
}
