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
import '../providers/event_provider.dart';
import '../domain/event_model.dart';

class EventListScreen extends ConsumerStatefulWidget {
  const EventListScreen({super.key});

  @override
  ConsumerState<EventListScreen> createState() => _EventListScreenState();
}

class _EventListScreenState extends ConsumerState<EventListScreen> {
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
      ref.read(eventListProvider.notifier).loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(eventListProvider);
    final events = state.pagination.data;

    return Scaffold(
      body: Column(
        children: [
          const LargeTitleBar(title: 'Events'),
          Expanded(
            child: state.isLoading && events.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : state.error != null && events.isEmpty
                    ? ErrorView(
                        message: 'Failed to load events',
                        detail: state.error,
                        onRetry: () =>
                            ref.read(eventListProvider.notifier).refresh(),
                      )
                    : events.isEmpty
                        ? const EmptyState(
                            icon: PhosphorIconsRegular.calendarBlank,
                            title: 'No events',
                            subtitle: 'No upcoming events scheduled',
                          )
                        : RefreshIndicator(
                            onRefresh: () =>
                                ref.read(eventListProvider.notifier).refresh(),
                            child: ListView.builder(
                              controller: _scrollController,
                              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                              itemCount: events.length +
                                  (state.pagination.hasMore ? 1 : 0),
                              itemBuilder: (context, index) {
                                if (index == events.length) {
                                  return const Padding(
                                    padding: EdgeInsets.all(16),
                                    child: Center(
                                      child: CircularProgressIndicator(),
                                    ),
                                  );
                                }
                                return _EventCard(event: events[index]);
                              },
                            ),
                          ),
          ),
        ],
      ),
    );
  }
}

class _EventCard extends StatelessWidget {
  final EventModel event;

  const _EventCard({required this.event});

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
                    color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                  ),
                ),
                if (event.description.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(
                    event.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.bodySmall.copyWith(
                      color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
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
                        _formatDate(event.start!, event.end),
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

  String _formatDate(DateTime start, DateTime? end) {
    if (end == null || start.day == end.day) {
      return DateFormat('MMM d, yyyy • HH:mm').format(start);
    }
    return '${DateFormat('MMM d').format(start)} - ${DateFormat('MMM d, yyyy').format(end)}';
  }
}
