import 'dart:async';

import 'package:efe_mobile/core/api/cursor_pagination.dart';
import 'package:efe_mobile/core/widgets/large_title_bar.dart';
import 'package:efe_mobile/core/widgets/loading_shimmer.dart';
import 'package:efe_mobile/features/events/data/event_repository.dart';
import 'package:efe_mobile/features/events/domain/event_model.dart';
import 'package:efe_mobile/features/events/providers/event_provider.dart';
import 'package:efe_mobile/features/events/screens/event_list_screen.dart';
import 'package:efe_mobile/features/news/data/news_repository.dart';
import 'package:efe_mobile/features/news/domain/news_model.dart';
import 'package:efe_mobile/features/news/providers/news_provider.dart';
import 'package:efe_mobile/features/news/screens/news_list_screen.dart';
import 'package:efe_mobile/features/notifications/data/notification_repository.dart';
import 'package:efe_mobile/features/notifications/domain/notification_model.dart';
import 'package:efe_mobile/features/notifications/providers/notification_provider.dart';
import 'package:efe_mobile/features/notifications/screens/notification_list_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/localized_app.dart';

class _NeverNewsRepository implements NewsRepository {
  @override
  Future<CursorPagination<NewsModel>> getNews({String? cursor}) =>
      Completer<CursorPagination<NewsModel>>().future;
}

class _NeverEventRepository implements EventRepository {
  @override
  Future<CursorPagination<EventModel>> getEvents({String? cursor}) =>
      Completer<CursorPagination<EventModel>>().future;
}

class _NeverNotificationRepository implements NotificationRepository {
  @override
  Future<CursorPagination<NotificationModel>> getNotifications({
    String? cursor,
  }) =>
      Completer<CursorPagination<NotificationModel>>().future;

  @override
  Future<int> getUnreadCount() async => 0;

  @override
  Future<void> markAllRead() async {}

  @override
  Future<void> markRead(String id) async {}
}

Future<void> _pumpNewsLoading(WidgetTester tester) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        newsRepositoryProvider.overrideWithValue(_NeverNewsRepository()),
      ],
      child: localizedApp(home: const NewsListScreen()),
    ),
  );
  await tester.pump();
}

Future<void> _pumpEventsLoading(WidgetTester tester) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        eventRepositoryProvider.overrideWithValue(_NeverEventRepository()),
      ],
      child: localizedApp(home: const EventListScreen()),
    ),
  );
  await tester.pump();
}

Future<void> _pumpNotificationsLoading(WidgetTester tester) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        notificationRepositoryProvider
            .overrideWithValue(_NeverNotificationRepository()),
      ],
      child: localizedApp(home: const NotificationListScreen()),
    ),
  );
  await tester.pump();
}

void main() {
  testWidgets('news list uses gradient header and shimmer while loading',
      (tester) async {
    await _pumpNewsLoading(tester);
    expect(find.byType(LargeTitleBar), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.byType(LoadingShimmer), findsWidgets);
  });

  testWidgets('events list uses gradient header and shimmer while loading',
      (tester) async {
    await _pumpEventsLoading(tester);
    expect(find.byType(LargeTitleBar), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.byType(LoadingShimmer), findsWidgets);
  });

  testWidgets(
      'notifications list uses gradient header and shimmer while loading',
      (tester) async {
    await _pumpNotificationsLoading(tester);
    expect(find.byType(LargeTitleBar), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.byType(LoadingShimmer), findsWidgets);
  });
}
