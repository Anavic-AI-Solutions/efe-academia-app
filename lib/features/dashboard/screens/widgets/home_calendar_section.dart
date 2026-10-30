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
import '../../../events/domain/event_model.dart';
import '../../../events/providers/event_provider.dart';

/// Calendario del home del profesor: próximos 5 eventos con link a `/events`.
class HomeCalendarSection extends ConsumerWidget {
  const HomeCalendarSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final calendar = ref.watch(homeCalendarProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: l10n.homeCalendar,
          actionLabel: l10n.homeSeeAll,
          onAction: () => context.push('/events'),
          padding: EdgeInsets.zero,
        ),
        const SizedBox(height: 11),
        calendar.when(
          loading: () => const Column(
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
          ),
          error: (error, _) => ErrorView(
            message: l10n.eventsErrorTitle,
            detail: error.toString(),
            onRetry: () => ref.invalidate(homeCalendarProvider),
          ),
          data: (events) => events.isEmpty
              ? EmptyState(
                  icon: PhosphorIconsRegular.calendarBlank,
                  title: l10n.homeCalendarEmpty,
                )
              : Column(
                  children: [
                    // Tope de visualización: el provider ya recorta a 5,
                    // pero un override en tests puede traer más.
                    for (final event in events.take(5))
                      _HomeCalendarTile(event: event),
                  ],
                ),
        ),
      ],
    );
  }
}

class _HomeCalendarTile extends StatelessWidget {
  final EventModel event;

  const _HomeCalendarTile({required this.event});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final eventColor = Color(event.color);

    return AppCard(
      margin: const EdgeInsets.only(bottom: 10),
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
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  PhosphorIconsRegular.calendarBlank,
                  color: eventColor,
                  size: 16,
                ),
                if (event.start != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    DateFormat('MMM d').format(event.start!),
                    style: AppTypography.labelSmall.copyWith(
                      color: eventColor,
                      fontSize: 9,
                    ),
                  ),
                ],
              ],
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
                  Row(
                    children: [
                      Icon(
                        PhosphorIconsRegular.clock,
                        size: 13,
                        color: eventColor,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        DateFormat('HH:mm').format(event.start!),
                        style: AppTypography.labelSmall.copyWith(
                          color: eventColor,
                        ),
                      ),
                    ],
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
