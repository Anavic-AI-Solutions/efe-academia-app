import 'package:efe_mobile/core/notifications/notification_router.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('mapea urls del backend a rutas de la app con fallback', () {
    expect(routeForPush('/platform/chat/7'), '/chat/7');
    expect(routeForPush('/platform/chats/7'), '/chat/7');
    expect(routeForPush('/platform/notifications'), '/notifications');
    expect(routeForPush('/platform/fees'), '/fees');
    expect(routeForPush('/fees'), '/fees');
    expect(routeForPush('/dashboard'), '/dashboard');
    expect(routeForPush('/platform/requests'), '/notifications');
    expect(routeForPush('/platform/absences'), '/notifications');
    expect(routeForPush('/platform/tickets/3'), '/notifications');
    expect(routeForPush(null), '/notifications');
    expect(routeForPush(''), '/notifications');
  });
}
