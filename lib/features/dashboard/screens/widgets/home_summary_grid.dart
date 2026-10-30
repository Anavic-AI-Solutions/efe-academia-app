import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/loading_shimmer.dart';
import '../../../../l10n/l10n.dart';
import '../../../birthdays/domain/birthday_model.dart';
import '../../../birthdays/providers/birthday_provider.dart';
import '../../../documents/providers/document_provider.dart';
import '../../../events/providers/event_provider.dart';
import '../../../news/providers/news_provider.dart';

/// Grilla resumen 2x2 del home del profesor: Calendario, Cumpleaños,
/// Novedades y Documentos.
///
/// Cada tarjeta maneja su propio loading/empty/error de forma compacta: una
/// fuente caída muestra su fallback sin romper el resto del grid. El tap
/// navega a la vista dedicada (`/calendar`, `/birthdays`, `/news`,
/// `/documents`).
class HomeSummaryGrid extends StatelessWidget {
  const HomeSummaryGrid({super.key});

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        Row(
          children: [
            Expanded(child: _CalendarCard()),
            SizedBox(width: 8),
            Expanded(child: _BirthdaysCard()),
          ],
        ),
        SizedBox(height: 8),
        Row(
          children: [
            Expanded(child: _NewsCard()),
            SizedBox(width: 8),
            Expanded(child: _DocumentsCard()),
          ],
        ),
      ],
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final IconData icon;
  final Color accent;
  final String title;
  final String summary;
  final bool loading;
  final VoidCallback onTap;

  const _SummaryCard({
    required this.icon,
    required this.accent,
    required this.title,
    required this.summary,
    required this.onTap,
    this.loading = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AppCard(
      margin: EdgeInsets.zero,
      padding: const EdgeInsets.all(12),
      onTap: onTap,
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: accent.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: accent, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                    color: AppColors.sectionLabel,
                  ),
                ),
                const SizedBox(height: 2),
                if (loading)
                  const LoadingShimmer(
                    width: double.infinity,
                    height: 12,
                    borderRadius: 6,
                  )
                else
                  Text(
                    summary,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.bodySmall.copyWith(
                      color: isDark
                          ? AppColors.darkTextPrimary
                          : AppColors.lightTextPrimary,
                      fontWeight: FontWeight.w600,
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

class _CalendarCard extends ConsumerWidget {
  const _CalendarCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final calendar = ref.watch(homeCalendarProvider);
    const accent = AppColors.primary;

    return calendar.when(
      loading: () => _SummaryCard(
        icon: PhosphorIconsRegular.calendarBlank,
        accent: accent,
        title: l10n.homeCalendar.toUpperCase(),
        summary: '',
        loading: true,
        onTap: () => context.push('/calendar'),
      ),
      // Fallback compacto: nunca rompe el grid.
      error: (_, __) => _SummaryCard(
        icon: PhosphorIconsRegular.calendarBlank,
        accent: accent,
        title: l10n.homeCalendar.toUpperCase(),
        summary: l10n.homeCalendarEmpty,
        onTap: () => context.push('/calendar'),
      ),
      data: (events) {
        if (events.isEmpty) {
          return _SummaryCard(
            icon: PhosphorIconsRegular.calendarBlank,
            accent: accent,
            title: l10n.homeCalendar.toUpperCase(),
            summary: l10n.homeCalendarEmpty,
            onTap: () => context.push('/calendar'),
          );
        }
        final next = events.first;
        final date = next.start == null
            ? ''
            : ' · ${DateFormat('MMM d').format(next.start!)}';
        return _SummaryCard(
          icon: PhosphorIconsRegular.calendarBlank,
          accent: accent,
          title: l10n.homeCalendar.toUpperCase(),
          summary: '${next.title}$date',
          onTap: () => context.push('/calendar'),
        );
      },
    );
  }
}

class _BirthdaysCard extends ConsumerWidget {
  const _BirthdaysCard();

  static const _accent = Color(0xFFE8A0BF);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final birthdays = ref.watch(todayBirthdaysProvider);
    final available = ref.watch(birthdaysAvailableProvider);

    String summaryFor(List<BirthdayModel> items) {
      if (!available) return l10n.homeBirthdaysSoon;
      if (items.isEmpty) return l10n.homeBirthdaysEmpty;
      if (items.length == 1) return items.first.name;
      if (items.length == 2) {
        return '${items[0].name}, ${items[1].name}';
      }
      return l10n.homeSummaryBirthdaysCount(items.length);
    }

    return birthdays.when(
      loading: () => _SummaryCard(
        icon: PhosphorIconsRegular.cake,
        accent: _accent,
        title: l10n.homeBirthdays.toUpperCase(),
        summary: '',
        loading: true,
        onTap: () => context.push('/birthdays'),
      ),
      // Fallback compacto: nunca rompe el grid.
      error: (_, __) => _SummaryCard(
        icon: PhosphorIconsRegular.cake,
        accent: _accent,
        title: l10n.homeBirthdays.toUpperCase(),
        summary: l10n.homeBirthdaysEmpty,
        onTap: () => context.push('/birthdays'),
      ),
      data: (items) => _SummaryCard(
        icon: PhosphorIconsRegular.cake,
        accent: _accent,
        title: l10n.homeBirthdays.toUpperCase(),
        summary: summaryFor(items),
        onTap: () => context.push('/birthdays'),
      ),
    );
  }
}

class _NewsCard extends ConsumerWidget {
  const _NewsCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final state = ref.watch(newsListProvider);
    final news = state.pagination.data;

    String summary;
    bool loading = false;
    if (state.isLoading && news.isEmpty) {
      summary = '';
      loading = true;
    } else if (news.isEmpty) {
      // Vacío o error aislado: fallback compacto, nunca rompe el grid.
      summary = l10n.homeNewsEmpty;
    } else {
      summary = news.first.title;
    }

    return _SummaryCard(
      icon: PhosphorIconsRegular.newspaper,
      accent: AppColors.accentFor(isDark),
      title: l10n.homeNews.toUpperCase(),
      summary: summary,
      loading: loading,
      onTap: () => context.push('/news'),
    );
  }
}

class _DocumentsCard extends ConsumerWidget {
  const _DocumentsCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final documents = ref.watch(homeDocumentsProvider);
    final accent = AppColors.accentFor(isDark);

    return documents.when(
      loading: () => _SummaryCard(
        icon: PhosphorIconsRegular.fileText,
        accent: accent,
        title: l10n.homeDocuments.toUpperCase(),
        summary: '',
        loading: true,
        onTap: () => context.push('/documents'),
      ),
      // Fallback compacto: nunca rompe el grid.
      error: (_, __) => _SummaryCard(
        icon: PhosphorIconsRegular.fileText,
        accent: accent,
        title: l10n.homeDocuments.toUpperCase(),
        summary: l10n.documentsEmpty,
        onTap: () => context.push('/documents'),
      ),
      data: (items) => _SummaryCard(
        icon: PhosphorIconsRegular.fileText,
        accent: accent,
        title: l10n.homeDocuments.toUpperCase(),
        summary: items.isEmpty
            ? l10n.documentsEmpty
            : l10n.homeSummaryDocumentsCount(items.length),
        onTap: () => context.push('/documents'),
      ),
    );
  }
}
