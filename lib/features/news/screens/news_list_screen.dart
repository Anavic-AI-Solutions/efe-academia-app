import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:intl/intl.dart';

import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/error_view.dart';
import '../../../core/widgets/large_title_bar.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../providers/news_provider.dart';
import '../domain/news_model.dart';

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

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(newsListProvider);
    final news = state.pagination.data;

    return Scaffold(
      body: Column(
        children: [
          const LargeTitleBar(title: 'News'),
          Expanded(
            child: state.isLoading && news.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : state.error != null && news.isEmpty
                    ? ErrorView(
                        message: 'Failed to load news',
                        detail: state.error,
                        onRetry: () =>
                            ref.read(newsListProvider.notifier).refresh(),
                      )
                    : news.isEmpty
                        ? const EmptyState(
                            icon: PhosphorIconsRegular.article,
                            title: 'No news',
                            subtitle: 'Check back later for updates',
                          )
                        : RefreshIndicator(
                            onRefresh: () =>
                                ref.read(newsListProvider.notifier).refresh(),
                            child: ListView.builder(
                              controller: _scrollController,
                              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                              itemCount:
                                  news.length + (state.pagination.hasMore ? 1 : 0),
                              itemBuilder: (context, index) {
                                if (index == news.length) {
                                  return const Padding(
                                    padding: EdgeInsets.all(16),
                                    child: Center(
                                      child: CircularProgressIndicator(),
                                    ),
                                  );
                                }
                                return _NewsCard(news: news[index]);
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

  const _NewsCard({required this.news});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AppCard(
      margin: const EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image placeholder
          Container(
            width: double.infinity,
            height: 140,
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurfaceElevated : AppColors.lightSearchFill,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Icon(
              PhosphorIconsRegular.newspaper,
              size: 40,
              color: isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  news.title,
                  style: AppTypography.titleMedium.copyWith(
                    color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                  ),
                ),
                if (news.eventDate != null) ...[
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(
                        PhosphorIconsRegular.calendar,
                        size: 13,
                        color: isDark ? const Color(0xFF6366F1) : AppColors.primary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        DateFormat('MMM d, yyyy').format(news.eventDate!),
                        style: AppTypography.labelSmall.copyWith(
                          color: isDark ? const Color(0xFF6366F1) : AppColors.primary,
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
                    color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                  ),
                ),
                if (news.createdAt != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    DateFormat('MMM d, yyyy').format(news.createdAt!),
                    style: AppTypography.labelSmall.copyWith(
                      color: isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary,
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
}
