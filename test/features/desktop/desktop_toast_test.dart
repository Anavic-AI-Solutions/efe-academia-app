import 'package:efe_mobile/features/desktop/desktop_toast.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('fromPayload mapea shape del backend y fallback', () {
    final t = DesktopToast.fromPayload({
      'id': 9,
      'title': 'Aviso',
      'message': 'Cuerpo',
      'type': 'general',
      'url': '/platform/chat/7',
      'created_at': '2026-01-01T00:00:00Z',
    });
    expect(t.title, 'Aviso');
    expect(t.body, 'Cuerpo');
    expect(t.route, '/chat/7');
    final unknown =
        DesktopToast.fromPayload({'title': 'X', 'url': '/platform/nada'});
    expect(unknown.route, '/notifications');
    expect(unknown.body, '');
    expect(DesktopToast.fromPayload({}).route, '/notifications');
  });
}
