import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:launch_at_startup/launch_at_startup.dart';
import 'package:window_manager/window_manager.dart';

import '../../l10n/app_localizations.dart';
import 'data/desktop_settings.dart';
import 'desktop_tray.dart';

bool launchMinimized(List<String> args) => args.contains('--minimized');

bool get isDesktopApp => Platform.isWindows || Platform.isLinux;

/// La X oculta a la bandeja en lugar de cerrar (residencia).
class _DesktopWindowListener extends WindowListener {
  @override
  void onWindowClose() {
    unawaited(windowManager.hide());
  }
}

/// Sesión de escritorio: ventana, bandeja y autostart.
///
/// Se llama SOLO cuando [isDesktopApp], desde `main()`. Nunca debe romper
/// el arranque: todo el cuerpo va en un único try/catch (estilo del guard
/// de Firebase en `main.dart`).
class DesktopSession {
  DesktopSession._();

  static Future<void> init({required List<String> args}) async {
    try {
      await windowManager.ensureInitialized();
      await windowManager.waitUntilReadyToShow(
        const WindowOptions(
          size: Size(1280, 800),
          center: true,
          title: 'EFE',
        ),
        () async {
          if (launchMinimized(args)) {
            await windowManager.hide();
          } else {
            await windowManager.show();
          }
        },
      );
      await windowManager.setPreventClose(true);
      windowManager.addListener(_DesktopWindowListener());

      // setup() PRIMERO: sin esto launchAtStartup es Noop e isEnabled/enable
      // lanzan UnsupportedError, abortando todo el init (visto en Linux).
      launchAtStartup.setup(
        appName: 'EFE',
        appPath: Platform.resolvedExecutable,
        args: const ['--minimized'],
      );

      final strings = lookupAppLocalizations(_trayLocale());
      final tray = TrayManager();
      await tray.init(
        openLabel: strings.trayOpen,
        autostartLabel: strings.trayAutostart,
        quitLabel: strings.trayQuit,
        isAutostartEnabled: launchAtStartup.isEnabled,
        onToggleAutostart: () async {
          if (await launchAtStartup.isEnabled()) {
            await launchAtStartup.disable();
          } else {
            await launchAtStartup.enable();
          }
        },
      );

      final settings = DesktopSettings();
      if (!await settings.isAutostartConfigured()) {
        try {
          await launchAtStartup.enable();
          await settings.markAutostartConfigured();
        } catch (e) {
          debugPrint('[Desktop] autostart best-effort falló: $e');
        }
      }
    } catch (e) {
      debugPrint('[Desktop] DesktopSession.init falló: $e');
    }
  }

  /// `main()` corre antes de cargar el idioma guardado, así que el menú de
  /// la bandeja usa el locale del sistema (es → español, resto → inglés).
  static Locale _trayLocale() {
    final tag = Platform.localeName.toLowerCase();
    if (tag == 'es' || tag.startsWith('es_') || tag.startsWith('es-')) {
      return const Locale('es');
    }
    return const Locale('en');
  }
}
