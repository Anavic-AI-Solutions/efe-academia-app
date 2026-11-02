import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/loading_shimmer.dart';
import '../../../../core/widgets/section_header.dart';
import '../../../../l10n/l10n.dart';
import '../../../documents/providers/document_provider.dart';
import '../../../documents/screens/widgets/document_tile.dart';
import '../../../events/domain/event_model.dart';
import '../../../events/providers/event_provider.dart';
import '../../../news/domain/news_model.dart';
import '../../../news/providers/news_provider.dart';

/// Tres mini-secciones 1-ítem del home del padre: Documentos, Calendario y
/// Novedades, cada una con link "Ver todo" a su lista dedicada.
///
/// Cada bloque maneja su propio loading/empty/error de forma compacta: una
/// fuente caída muestra su fallback con reintento sin romper el resto.
class ParentSummarySections extends ConsumerWidget {
  const ParentSummarySections({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: l10n.documentsTitle,
          actionLabel: l10n.homeSeeAll,
          onAction: () => context.push('/documents'),
          padding: EdgeInsets.zero,
        ),
        const SizedBox(height: 8),
        const _DocumentsPreview(),
        const SizedBox(height: 16),
        SectionHeader(
          title: l10n.homeCalendar,
          actionLabel: l10n.homeSeeAll,
          onAction: () => context.push('/events'),
          padding: EdgeInsets.zero,
        ),
        const SizedBox(height: 8),
        const _EventsPreview(),
        const SizedBox(height: 16),
        SectionHeader(
          title: l10n.homeNews,
          actionLabel: l10n.homeSeeAll,
          onAction: () => context.push('/news'),
          padding: EdgeInsets.zero,
        ),
        const SizedBox(height: 8),
        const _NewsPreview(),
        const SizedBox(height: 16),
      ],
    );
  }
}

class _DocumentsPreview extends ConsumerWidget {
  const _DocumentsPreview();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final documents = ref.watch(homeDocumentsProvider);

    return documents.when(
      loading: () => const LoadingShimmer(
        width: double.infinity,
        height: 68,
        borderRadius: 16,
      ),
      error: (error, _) => _CompactError(
        message: l10n.documentsTitle,
        detail: error.toString(),
        onRetry: () => ref.invalidate(homeDocumentsProvider),
      ),
      data: (items) => items.isEmpty
          ? Text(l10n.documentsEmpty)
          : DocumentTile(
              document: items.first,
              onTap: () => context.push('/documents/${items.first.id}'),
            ),
    );
  }
}

class _EventsPreview extends ConsumerWidget {
  const _EventsPreview();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final calendar = ref.watch(homeCalendarProvider);

    return calendar.when(
      loading: () => const LoadingShimmer(
        width: double.infinity,
        height: 68,
        borderRadius: 16,
      ),
      error: (error, _) => _CompactError(
        message: l10n.eventsErrorTitle,
        detail: error.toString(),
        onRetry: () => ref.invalidate(homeCalendarProvider),
      ),
      data: (events) => events.isEmpty
          ? Text(l10n.homeCalendarEmpty)
          : _EventPreviewTile(event: events.first),
    );
  }
}

class _NewsPreview extends ConsumerWidget {
  const _NewsPreview();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final state = ref.watch(newsListProvider);
    final news = state.pagination.data;

    if (state.isLoading && news.isEmpty) {
      return const LoadingShimmer(
        width: double.infinity,
        height: 68,
        borderRadius: 16,
      );
    }
    if (news.isEmpty) {
      return Text(l10n.homeNewsEmpty);
    }
    return _NewsPreviewTile(news: news.first);
  }
}

/// Preview compacta de un evento: ícono, título y fecha. El tap va a la
/// lista (`/events`); no hay ruta de detalle.
class _EventPreviewTile extends StatelessWidget {
  final EventModel event;

  const _EventPreviewTile({required this.event});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final eventColor = Color(event.color);

    return AppCard(
      margin: EdgeInsets.zero,
      padding: const EdgeInsets.all(12),
      onTap: () => context.push('/events'),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: eventColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              PhosphorIconsRegular.calendarBlank,
              color: eventColor,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  event.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.titleSmall.copyWith(
                    color: isDark
                        ? AppColors.darkTextPrimary
                        : AppColors.lightTextPrimary,
                  ),
                ),
                if (event.start != null) ...[
                  const SizedBox(height: 3),
                  Text(
                    DateFormat('MMM d, yyyy • HH:mm').format(event.start!),
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

/// Preview compacta de una noticia: título + contenido a 2 líneas. El tap
/// va a la lista (`/news`); no hay ruta de detalle.
class _NewsPreviewTile extends StatelessWidget {
  final NewsModel news;

  const _NewsPreviewTile({required this.news});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = AppColors.accentFor(isDark);

    return AppCard(
      margin: EdgeInsets.zero,
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
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Fallback compacto de error con reintento: no rompe el resto.
class _CompactError extends StatelessWidget {
  final String message;
  final String? detail;
  final VoidCallback onRetry;

  const _CompactError({
    required this.message,
    this.detail,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Row(
      children: [
        const Icon(
          Icons.error_outline_rounded,
          color: AppColors.error,
          size: 20,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                message,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.bodySmall.copyWith(
                  color: isDark
                      ? AppColors.darkTextSecondary
                      : AppColors.lightTextSecondary,
                ),
              ),
              if (detail != null)
                Text(
                  detail!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.labelSmall.copyWith(
                    color: AppColors.mutedFor(isDark),
                  ),
                ),
            ],
          ),
        ),
        TextButton(
          onPressed: onRetry,
          child: Text(l10n.commonRetry),
        ),
      ],
    );
  }
}
