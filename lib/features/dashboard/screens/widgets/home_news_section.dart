import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../../core/widgets/loading_shimmer.dart';
import '../../../../core/widgets/section_header.dart';
import '../../../../l10n/l10n.dart';
import '../../../news/domain/news_model.dart';
import '../../../news/providers/news_provider.dart';

/// Novedades del home del profesor: últimas 3 con link a `/news`.
class HomeNewsSection extends ConsumerWidget {
  const HomeNewsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final state = ref.watch(newsListProvider);
    final news = state.pagination.data;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: l10n.homeNews,
          actionLabel: l10n.homeSeeAll,
          onAction: () => context.push('/news'),
          padding: EdgeInsets.zero,
        ),
        const SizedBox(height: 11),
        if (state.isLoading && news.isEmpty)
          const Column(
            children: [
              LoadingShimmer(
                width: double.infinity,
                height: 64,
                borderRadius: 16,
              ),
              SizedBox(height: 10),
              LoadingShimmer(
                width: double.infinity,
                height: 64,
                borderRadius: 16,
              ),
            ],
          )
        else if (state.error != null && news.isEmpty)
          ErrorView(
            message: l10n.newsErrorTitle,
            detail: state.error,
            onRetry: () => ref.read(newsListProvider.notifier).refresh(),
          )
        else if (news.isEmpty)
          EmptyState(
            icon: PhosphorIconsRegular.newspaper,
            title: l10n.homeNewsEmpty,
          )
        else
          Column(
            children: [
              // Tope de visualización: la lista completa sigue paginada
              // en `/news`, pero un override en tests puede traer más.
              for (final item in news.take(3)) _HomeNewsTile(news: item),
            ],
          ),
      ],
    );
  }
}

class _HomeNewsTile extends StatelessWidget {
  final NewsModel news;

  const _HomeNewsTile({required this.news});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = AppColors.accentFor(isDark);
    final date = news.createdAt ?? news.eventDate;

    return AppCard(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      onTap: () => context.push('/news'),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: accent.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              PhosphorIconsRegular.newspaper,
              color: accent,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  news.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.titleSmall.copyWith(
                    color: isDark
                        ? AppColors.darkTextPrimary
                        : AppColors.lightTextPrimary,
                  ),
                ),
                const SizedBox(height: 3),
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
                if (date != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    DateFormat('MMM d, yyyy').format(date),
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
}
