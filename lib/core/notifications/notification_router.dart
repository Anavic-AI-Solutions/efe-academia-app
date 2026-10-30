/// Traduce la `url` que envía el backend en el `data` del push FCM a una
/// ruta interna de la app (GoRouter).
///
/// Tabla de mapeo:
/// - `/platform/chat/{id}` y `/platform/chats/{id}` → `/chat/{id}`
/// - `/platform/notifications` → `/notifications`
/// - `/platform/fees` y `/fees` → `/fees`
/// - `/dashboard` → `/dashboard`
/// - cualquier otra cosa / null / vacío → `/notifications`
String routeForPush(String? url) {
  if (url == null || url.isEmpty) return '/notifications';
  if (url.startsWith('/platform/chat/') || url.startsWith('/platform/chats/')) {
    final id = url.split('/').last;
    if (id.isEmpty) return '/notifications';
    return '/chat/$id';
  }
  switch (url) {
    case '/platform/notifications':
      return '/notifications';
    case '/platform/fees':
    case '/fees':
      return '/fees';
    case '/dashboard':
      return '/dashboard';
    default:
      return '/notifications';
  }
}
