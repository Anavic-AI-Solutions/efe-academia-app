import 'package:efe_mobile/core/api/cursor_pagination.dart';
import 'package:efe_mobile/features/notifications/data/notification_repository.dart';
import 'package:efe_mobile/features/notifications/domain/notification_model.dart';
import 'package:efe_mobile/features/notifications/providers/notification_provider.dart';
import 'package:efe_mobile/features/notifications/screens/notification_list_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/localized_app.dart';

class _UnreadNotificationRepository implements NotificationRepository {
  int markAllReadCalls = 0;

  @override
  Future<CursorPagination<NotificationModel>> getNotifications({
    String? cursor,
  }) async {
    return CursorPagination(
      data: [
        NotificationModel(
          id: 'n1',
          title: 'Aviso',
          body: 'Contenido',
          createdAt: DateTime(2026, 10, 1),
        ),
      ],
      hasMore: false,
    );
  }

  @override
  Future<int> getUnreadCount() async => 1;

  @override
  Future<void> markAllRead() async {
    markAllReadCalls++;
  }

  @override
  Future<void> markRead(String id) async {}
}

void main() {
  testWidgets('notifications header uses compact mark-all action',
      (tester) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final repository = _UnreadNotificationRepository();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          notificationRepositoryProvider.overrideWithValue(repository),
        ],
        child: localizedApp(home: const NotificationListScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Marcar todas como leídas'), findsNothing);
    expect(
      find.byKey(const ValueKey('notifications-mark-all-read')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);

    await tester.tap(
      find.byKey(const ValueKey('notifications-mark-all-read')),
    );
    await tester.pumpAndSettle();

    expect(repository.markAllReadCalls, 1);
  });
}
