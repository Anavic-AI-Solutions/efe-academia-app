import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:tray_manager/tray_manager.dart' as tray;
import 'package:window_manager/window_manager.dart';

/// Claves de los ítems del menú de la bandeja.
const String trayMenuOpenKey = 'open';
const String trayMenuAutostartKey = 'autostart';
const String trayMenuQuitKey = 'quit';

/// Icono de la bandeja como asset empaquetado.
///
/// `tray_manager` (0.5.3) resuelve `setIcon` contra
/// `<ejecutable>/data/flutter_assets/<iconPath>`, así que se pasa la ruta
/// del asset tal cual (sin extraer a temporal).
const String trayIconAssetPath = 'assets/images/efe_logo_white.png';

/// Menú de la bandeja sin callbacks: cada ítem lleva su `key` (`'open'`,
/// `'autostart'`, `'quit'`); el clic se despacha con [handleTrayMenuClick].
///
/// Orden: abrir, separador, autostart con sufijo `' ✓'` si activo,
/// separador, salir.
tray.Menu buildTrayMenu(
    {required String openLabel,
    required String autostartLabel,
    required String quitLabel,
    required bool autostartEnabled}) {
  return tray.Menu(items: [
    tray.MenuItem(key: trayMenuOpenKey, label: openLabel),
    tray.MenuItem.separator(),
    tray.MenuItem(
        key: trayMenuAutostartKey,
        label: autostartEnabled ? '$autostartLabel ✓' : autostartLabel),
    tray.MenuItem.separator(),
    tray.MenuItem(key: trayMenuQuitKey, label: quitLabel),
  ]);
}

/// Despacha el clic de un ítem del menú por su `key`; clave desconocida →
/// no-op. El listener de `tray_manager` la llama con `menuItem.key`, y así
/// el despacho queda unit-testeable sin plataforma.
void handleTrayMenuClick(String key,
    {required void Function() onOpen,
    required void Function() onToggleAutostart,
    required void Function() onQuit}) {
  switch (key) {
    case trayMenuOpenKey:
      onOpen();
    case trayMenuAutostartKey:
      onToggleAutostart();
    case trayMenuQuitKey:
      onQuit();
  }
}

/// Residencia en la bandeja del sistema (vía `tray_manager`).
///
/// Orden nativo en Linux (0.5.3): `setIcon` crea el indicador con un menú
/// vacío y lo activa, y `setContextMenu` instala después el menú real
/// (`new → set_menu → set_status`).
///
/// - clic izquierdo → muestra y enfoca la ventana.
/// - clic derecho → abre el menú contextual (en Linux el menú del
///   indicador es nativo; `popUpContextMenu` solo existe en Windows).
/// - el menú se reconstruye tras cada cambio de autostart para reflejar el
///   estado vivo.
/// - Salir → `destroy()` (cierre real; `close()` solo ocultaría por el
///   `setPreventClose` de [DesktopSession]).
class TrayManager with tray.TrayListener {
  String _openLabel = '';
  String _autostartLabel = '';
  String _quitLabel = '';
  Future<bool> Function() _isAutostartEnabled = () async => false;
  Future<void> Function() _onToggleAutostart = () async {};

  Future<void> init({
    required String openLabel,
    required String autostartLabel,
    required String quitLabel,
    required Future<bool> Function() isAutostartEnabled,
    required Future<void> Function() onToggleAutostart,
  }) async {
    _openLabel = openLabel;
    _autostartLabel = autostartLabel;
    _quitLabel = quitLabel;
    _isAutostartEnabled = isAutostartEnabled;
    _onToggleAutostart = onToggleAutostart;

    tray.trayManager.addListener(this);
    await tray.trayManager.setIcon(trayIconAssetPath);
    // `setToolTip` no está implementado en el plugin Linux de 0.5.3:
    // best-effort (en Windows sí aplica).
    try {
      await tray.trayManager.setToolTip('EFE');
    } catch (e) {
      debugPrint('[Desktop] setToolTip no soportado: $e');
    }
    await refreshMenu();
  }

  Future<void> refreshMenu() async {
    await tray.trayManager.setContextMenu(
      buildTrayMenu(
        openLabel: _openLabel,
        autostartLabel: _autostartLabel,
        quitLabel: _quitLabel,
        autostartEnabled: await _isAutostartEnabled(),
      ),
    );
  }

  Future<void> dispose() async {
    tray.trayManager.removeListener(this);
  }

  @override
  void onTrayIconMouseDown() {
    unawaited(_showWindow());
  }

  @override
  void onTrayIconRightMouseDown() {
    unawaited(_popUpMenu());
  }

  @override
  void onTrayMenuItemClick(tray.MenuItem menuItem) {
    handleTrayMenuClick(
      menuItem.key ?? '',
      onOpen: () => unawaited(_showWindow()),
      onToggleAutostart: () => unawaited(_toggleAutostart()),
      onQuit: () => unawaited(windowManager.destroy()),
    );
  }

  Future<void> _toggleAutostart() async {
    await _onToggleAutostart();
    await refreshMenu();
  }

  static Future<void> _popUpMenu() async {
    // Solo Windows lo implementa en 0.5.3; en Linux el menú del indicador
    // aparece solo con el clic derecho.
    try {
      await tray.trayManager.popUpContextMenu();
    } catch (e) {
      debugPrint('[Desktop] popUpContextMenu no soportado: $e');
    }
  }

  static Future<void> _showWindow() async {
    await windowManager.show();
    await windowManager.focus();
  }
}
