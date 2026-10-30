import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/app.dart';
import 'app/locale/locale_provider.dart';
import 'app/theme/theme_provider.dart';
import 'core/config/env_helper.dart';
import 'features/desktop/desktop_session.dart';

void main(List<String> args) async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load .env from filesystem (creates if missing)
  await EnvHelper.load();

  // Residencia en bandeja + autostart (solo Windows/Linux). Nunca rompe el
  // arranque: DesktopSession.init ya captura todo, este guard es la red de
  // seguridad para que los imports desktop jamás tumben móvil.
  if (isDesktopApp) {
    try {
      await DesktopSession.init(args: args);
    } catch (e) {
      debugPrint('[Desktop] init falló: $e');
    }
  }

  // FCM solo existe en Android; si falla (sin google-services en entornos
  // de prueba) la app debe arrancar igual.
  if (Platform.isAndroid) {
    try {
      await Firebase.initializeApp();
    } catch (e) {
      debugPrint('[Push] Firebase.initializeApp falló: $e');
    }
  }

  final container = ProviderContainer();
  await container.read(localeProvider.notifier).load();
  await container.read(themeModeProvider.notifier).load();

  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const EfeApp(),
    ),
  );
}
