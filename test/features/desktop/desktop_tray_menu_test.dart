import 'package:efe_mobile/features/desktop/desktop_tray.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tray_manager/tray_manager.dart' show MenuItem;

void main() {
  test('menú en orden con toggle marcado y dispatch por key', () {
    final menu = buildTrayMenu(
      openLabel: 'Abrir EFE',
      autostartLabel: 'Iniciar con el sistema',
      quitLabel: 'Salir',
      autostartEnabled: true,
    );
    final items = menu.items!;
    expect(items.length, 5);
    expect(items[0].key, 'open');
    expect(items[0].label, 'Abrir EFE');
    expect(items[1], isA<MenuItem>());
    expect(items[1].type, 'separator');
    expect(items[2].key, 'autostart');
    expect(items[2].label, 'Iniciar con el sistema ✓');
    expect(items[3].type, 'separator');
    expect(items[4].key, 'quit');
    expect(items[4].label, 'Salir');
  });

  test('toggle sin marcar cuando autostart deshabilitado', () {
    final menu = buildTrayMenu(
      openLabel: 'Abrir EFE',
      autostartLabel: 'Iniciar con el sistema',
      quitLabel: 'Salir',
      autostartEnabled: false,
    );
    expect(menu.items![2].label, 'Iniciar con el sistema');
  });

  test('dispatch por key con unknown no-op', () {
    final calls = <String>[];
    void onOpen() => calls.add('open');
    void onToggle() => calls.add('toggle');
    void onQuit() => calls.add('quit');

    handleTrayMenuClick('open',
        onOpen: onOpen, onToggleAutostart: onToggle, onQuit: onQuit);
    handleTrayMenuClick('autostart',
        onOpen: onOpen, onToggleAutostart: onToggle, onQuit: onQuit);
    handleTrayMenuClick('quit',
        onOpen: onOpen, onToggleAutostart: onToggle, onQuit: onQuit);
    handleTrayMenuClick('unknown',
        onOpen: onOpen, onToggleAutostart: onToggle, onQuit: onQuit);
    handleTrayMenuClick('',
        onOpen: onOpen, onToggleAutostart: onToggle, onQuit: onQuit);

    expect(calls, ['open', 'toggle', 'quit']);
  });
}
