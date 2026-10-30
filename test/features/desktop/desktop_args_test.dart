import 'package:efe_mobile/features/desktop/desktop_session.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('launchMinimized detecta el flag', () {
    expect(launchMinimized(['--minimized']), isTrue);
    expect(launchMinimized([]), isFalse);
  });
}
