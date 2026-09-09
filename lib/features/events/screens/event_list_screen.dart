import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:intl/intl.dart';

import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/error_view.dart';
import '../providers/event_provider.dart';
import '../domain/event_model.dart';

class EventListScreen extends ConsumerWidget {
  const EventListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(eventListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Events'),
      ),
      body: state.isLoading && state.events.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : state.error != null && state.events.isEmpty
              ? ErrorView(
                  message: 'Failed to load events',
                  detail: state.error,
                  onRetry: () => ref.read(eventListProvider.notifier).refresh(),
                )
              : state.events.isEmpty
                  ? const EmptyState(
                      icon: PhosphorIconsRegular.calendarBlank,
                      title: 'No events',
                      subtitle: 'No upcoming events scheduled',
                    )
                  : RefreshIndicator(
                      onRefresh: () => ref.read(eventListProvider.notifier).refresh(),
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: state.events.length,
                        itemBuilder: (context, index) => _EventCard(
                          event: state.events[index],
                        ),
                      ),
                    ),
    );
  }
}

class _EventCard extends StatelessWidget {
  final EventModel event;

  const _EventCard({required this.event});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final eventColor = Color(event.color);

    return AppCard(
      margin: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 56,
            decoration: BoxDecoration(
              color: eventColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  event.title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (event.description.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    event.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.textTheme.bodySmall?.color?.withOpacity(0.7),
                    ),
                  ),
                ],
                if (event.start != null) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        PhosphorIconsRegular.clock,
                        size: 12,
                        color: eventColor,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _formatDate(event.start!, event.end),
                        style: theme.textTheme.labelSmall?.copyWith(
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
