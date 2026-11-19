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
import '../providers/event_provider.dart';
import '../domain/event_model.dart';
import 'widgets/event_form_sheet.dart';

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

  /// El calendario del home y el del mes visible deben reflejar el cambio.
  void _invalidateEventViews() {
    ref.invalidate(eventListProvider);
    ref.invalidate(homeCalendarProvider);
    ref.invalidate(calendarMonthProvider);
  }

  Future<void> _openForm(EventModel? event) async {
    final l10n = context.l10n;
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => EventFormSheet(event: event),
    );
    if (saved != true || !mounted) return;
    _invalidateEventViews();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(event == null ? l10n.eventCreated : l10n.eventUpdated),
      ),
    );
  }

  Future<void> _delete(EventModel event) async {
    final l10n = context.l10n;
    final confirmed = await showConfirmDialog(
      context,
      title: l10n.eventDeleteTitle,
      message: l10n.commonDeleteMessage,
      confirmLabel: l10n.commonDeleteConfirm,
      cancelLabel: l10n.commonCancel,
      destructive: true,
    );
    if (!confirmed || !mounted) return;

    try {
      await ref.read(eventRepositoryProvider).deleteEvent(event.id);
      if (!mounted) return;
      _invalidateEventViews();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.eventDeleted)),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.commonDeleteError)),
      );
    }
  }

  bool _canManageEvent(UserModel? user, EventModel event) {
    if (user == null) return false;
    if (user.isStaff) return true;
    return user.isProfessor && event.createdBy?.toString() == user.id;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final state = ref.watch(eventListProvider);
    final events = state.pagination.data;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final user = ref.watch(authProvider).user;
    final canCreate = user?.canManageEvents ?? false;

    return Scaffold(
      backgroundColor: AppColors.backgroundFor(isDark),
      floatingActionButton: canCreate
          ? FloatingActionButton(
              key: const Key('event-fab'),
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
          LargeTitleBar(title: l10n.eventsTitle),
          Expanded(
            child: state.isLoading && events.isEmpty
                ? const ListShimmer()
                : state.error != null && events.isEmpty
                    ? ErrorView(
                        message: l10n.eventsErrorTitle,
                        detail: state.error,
                        onRetry: () =>
                            ref.read(eventListProvider.notifier).refresh(),
                      )
                    : events.isEmpty
                        ? EmptyState(
                            icon: PhosphorIconsRegular.calendarBlank,
                            title: l10n.eventsEmptyTitle,
                            subtitle: l10n.eventsEmptySubtitle,
                          )
                        : RefreshIndicator(
                            onRefresh: () =>
                                ref.read(eventListProvider.notifier).refresh(),
                            child: ListView.builder(
                              controller: _scrollController,
                              padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                              itemCount: events.length +
                                  (state.pagination.hasMore ? 1 : 0),
                              itemBuilder: (context, index) {
                                if (index == events.length) {
                                  return const Padding(
                                    padding:
                                        EdgeInsets.only(top: 4, bottom: 12),
                                    child: LoadingShimmer(
                                      width: double.infinity,
                                      height: 68,
                                    ),
                                  );
                                }
                                final event = events[index];
                                final canManage = _canManageEvent(user, event);
                                return _EventCard(
                                  event: event,
                                  onEdit:
                                      canManage ? () => _openForm(event) : null,
                                  onDelete:
                                      canManage ? () => _delete(event) : null,
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

class _EventCard extends StatelessWidget {
  final EventModel event;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const _EventCard({
    required this.event,
    this.onEdit,
    this.onDelete,
  });

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
                      Flexible(
                        child: Text(
                          _formatDate(event.start!, event.end),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.labelSmall.copyWith(
                            color: eventColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          if (onEdit != null || onDelete != null)
            PopupMenuButton<String>(
              key: Key('event-menu-${event.id}'),
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
                  child: Text(context.l10n.commonEdit),
                ),
                PopupMenuItem(
                  value: 'delete',
                  child: Text(context.l10n.commonDelete),
                ),
              ],
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
