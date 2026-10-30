import '../../core/notifications/notification_router.dart';

class DesktopToast {
  final String title;
  final String body;
  final String route;

  const DesktopToast(
      {required this.title, required this.body, required this.route});

  factory DesktopToast.fromPayload(Map<String, dynamic> payload) =>
      DesktopToast(
        title: payload['title'] as String? ?? '',
        body: payload['message'] as String? ?? '',
        route: routeForPush(payload['url'] as String?),
      );
}
