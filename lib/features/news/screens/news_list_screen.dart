import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:intl/intl.dart';

import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/error_view.dart';
import '../providers/news_provider.dart';
import '../domain/news_model.dart';

class NewsListScreen extends ConsumerWidget {
  const NewsListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(newsListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('News'),
      ),
      body: state.isLoading && state.news.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : state.error != null && state.news.isEmpty
              ? ErrorView(
                  message: 'Failed to load news',
                  detail: state.error,
                  onRetry: () => ref.read(newsListProvider.notifier).refresh(),
                )
              : state.news.isEmpty
                  ? const EmptyState(
                      icon: PhosphorIconsRegular.article,
                      title: 'No news',
                      subtitle: 'Check back later for updates',
                    )
                  : RefreshIndicator(
                      onRefresh: () => ref.read(newsListProvider.notifier).refresh(),
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: state.news.length,
                        itemBuilder: (context, index) => _NewsCard(
                          news: state.news[index],
                        ),
                      ),
                    ),
    );
  }
}

class _NewsCard extends StatelessWidget {
  final NewsModel news;

  const _NewsCard({required this.news});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AppCard(
      margin: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            news.title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          if (news.eventDate != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  PhosphorIconsRegular.calendar,
                  size: 14,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 4),
                Text(
                  DateFormat('MMM d, yyyy').format(news.eventDate!),
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.primary,
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 8),
          Text(
            news.content,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.textTheme.bodySmall?.color,
            ),
          ),
          if (news.createdAt != null) ...[
            const SizedBox(height: 8),
            Text(
              'Published ${DateFormat('MMM d, yyyy').format(news.createdAt!)}',
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.textTheme.bodySmall?.color?.withOpacity(0.6),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
