import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/error_view.dart';
import '../../../core/widgets/large_title_bar.dart';
import '../../../core/widgets/loading_shimmer.dart';
import '../../../l10n/l10n.dart';
import '../domain/event_model.dart';
import '../providers/event_provider.dart';

/// Vista mensual del calendario: grilla del mes con punto en los días con
/// eventos y lista del día seleccionado debajo.
///
/// Lee `EventApi.getCalendar` (primer → último día) vía
/// [calendarMonthProvider]. La app bar muestra el mes con flechas para
/// cambiarlo y la acción "Ver lista" hacia `/events`.
class CalendarScreen extends ConsumerStatefulWidget {
  /// Mes inicial (solo el año y el mes importan). Por defecto, el actual.
  /// Expuesto para tests.
  final DateTime? initialMonth;

  const CalendarScreen({super.key, this.initialMonth});

  @override
  ConsumerState<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends ConsumerState<CalendarScreen> {
  late DateTime _month;
  late DateTime _selectedDay;

  @override
  void initState() {
    super.initState();
    final base = widget.initialMonth ?? DateTime.now();
    _month = DateTime(base.year, base.month);
    final now = DateTime.now();
    _selectedDay = now.year == _month.year && now.month == _month.month
        ? DateTime(now.year, now.month, now.day)
        : DateTime(_month.year, _month.month, 1);
  }

  void _changeMonth(int delta) {
    setState(() {
      _month = DateTime(_month.year, _month.month + delta);
      _selectedDay = DateTime(_month.year, _month.month, 1);
    });
  }

  Widget _monthArrow({
    required Key key,
    required IconData icon,
    required int delta,
  }) {
    return IconButton(
      key: key,
      onPressed: () => _changeMonth(delta),
      icon: Icon(icon, color: Colors.white, size: 20),
    );
  }

  bool _isSameDay(DateTime? a, DateTime b) =>
      a != null && a.year == b.year && a.month == b.month && a.day == b.day;

  bool _hasEventOnDay(List<EventModel> events, DateTime day) =>
      events.any((e) => e.start != null && _isSameDay(e.start, day));

  List<EventModel> _eventsOnDay(List<EventModel> events, DateTime day) =>
      events.where((e) => _isSameDay(e.start, day)).toList();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final monthEvents = ref.watch(calendarMonthProvider(_month));
    final daysInMonth = DateTime(_month.year, _month.month + 1, 0).day;
    final leadingBlanks = DateTime(_month.year, _month.month, 1).weekday - 1;
    final compact =
        MediaQuery.sizeOf(context).width - 32 < LargeTitleBar.compactBreakpoint;
    final monthLabel =
        DateFormat(compact ? 'MMM yyyy' : 'MMMM yyyy').format(_month);

    return Scaffold(
      backgroundColor: AppColors.backgroundFor(isDark),
      body: Column(
        children: [
          LargeTitleBar(
            title: monthLabel,
            actions: [
              _monthArrow(
                key: const ValueKey('calendar-prev-month'),
                icon: PhosphorIconsRegular.caretLeft,
                delta: -1,
              ),
              _monthArrow(
                key: const ValueKey('calendar-next-month'),
                icon: PhosphorIconsRegular.caretRight,
                delta: 1,
              ),
              TextButton(
                onPressed: () => context.push('/events'),
                child: Text(
                  l10n.calendarViewList,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
            compactActions: [
              _monthArrow(
                key: const ValueKey('calendar-prev-month'),
                icon: PhosphorIconsRegular.caretLeft,
                delta: -1,
              ),
              _monthArrow(
                key: const ValueKey('calendar-next-month'),
                icon: PhosphorIconsRegular.caretRight,
                delta: 1,
              ),
              IconButton(
                key: const ValueKey('calendar-view-list'),
                tooltip: l10n.calendarViewList,
                onPressed: () => context.push('/events'),
                icon: const Icon(
                  PhosphorIconsRegular.listBullets,
                  color: Colors.white,
                  size: 22,
                ),
              ),
            ],
          ),
          Expanded(
            child: monthEvents.when(
              loading: () => const ListShimmer(),
              error: (error, _) => ErrorView(
                message: l10n.eventsErrorTitle,
                detail: error.toString(),
                onRetry: () => ref.invalidate(calendarMonthProvider(_month)),
              ),
              data: (events) {
                final selected = _eventsOnDay(events, _selectedDay);
                return ListView(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
                  children: [
                    const _WeekdayHeader(),
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 7,
                      ),
                      itemCount: leadingBlanks + daysInMonth,
                      itemBuilder: (context, index) {
                        if (index < leadingBlanks) {
                          return const SizedBox.shrink();
                        }
                        final day = DateTime(
                          _month.year,
                          _month.month,
                          index - leadingBlanks + 1,
                        );
                        final isSelected = _isSameDay(_selectedDay, day);
                        final hasEvent = _hasEventOnDay(events, day);
                        return GestureDetector(
                          onTap: () => setState(() => _selectedDay = day),
                          behavior: HitTestBehavior.opaque,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                width: 34,
                                height: 34,
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? AppColors.primary
                                      : Colors.transparent,
                                  shape: BoxShape.circle,
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  '${day.day}',
                                  style: AppTypography.bodySmall.copyWith(
                                    color: isSelected
                                        ? Colors.white
                                        : (isDark
                                            ? AppColors.darkTextPrimary
                                            : AppColors.lightTextPrimary),
                                    fontWeight: isSelected
                                        ? FontWeight.w800
                                        : FontWeight.w600,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 2),
                              if (hasEvent)
                                Container(
                                  key: ValueKey(
                                    'event-dot-${day.year}-${day.month}-${day.day}',
                                  ),
                                  width: 6,
                                  height: 6,
                                  decoration: const BoxDecoration(
                                    color: AppColors.primary,
                                    shape: BoxShape.circle,
                                  ),
                                )
                              else
                                const SizedBox(width: 6, height: 6),
                            ],
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 12),
                    if (selected.isEmpty)
                      EmptyState(
                        icon: PhosphorIconsRegular.calendarBlank,
                        title: l10n.eventsEmptyTitle,
                        subtitle: l10n.eventsEmptySubtitle,
                      )
                    else
                      for (final event in selected)
                        _CalendarEventTile(event: event),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// Encabezado Lun–Dom con el locale actual (nombres estrechos, sin claves).
class _WeekdayHeader extends StatelessWidget {
  const _WeekdayHeader();
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    // Semana que arranca un lunes conocido (2026-10-05).
    final monday = DateTime(2026, 10, 5);
    return Row(
      children: [
        for (var i = 0; i < 7; i++)
          Expanded(
            child: Center(
              child: Text(
                DateFormat('EEEEE').format(monday.add(Duration(days: i))),
                style: AppTypography.labelSmall.copyWith(
                  color: AppColors.mutedFor(isDark),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// Mismo lenguaje visual que la tarjeta de `event_list_screen.dart`.
class _CalendarEventTile extends StatelessWidget {
  final EventModel event;

  const _CalendarEventTile({required this.event});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final eventColor = Color(event.color);

    return AppCard(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
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
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  event.title,
                  style: AppTypography.titleSmall.copyWith(
                    color: isDark
                        ? AppColors.darkTextPrimary
                        : AppColors.lightTextPrimary,
                  ),
                ),
                if (event.description.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(
                    event.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.bodySmall.copyWith(
                      color: isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.lightTextSecondary,
                    ),
                  ),
                ],
                if (event.start != null) ...[
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(
                        PhosphorIconsRegular.clock,
                        size: 13,
                        color: eventColor,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        DateFormat('MMM d, yyyy • HH:mm').format(event.start!),
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
