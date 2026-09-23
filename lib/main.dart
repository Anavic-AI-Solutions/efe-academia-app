import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/app.dart';
import 'app/locale/locale_provider.dart';
import 'app/theme/theme_provider.dart';
import 'core/config/env_helper.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load .env from filesystem (creates if missing)
  await EnvHelper.load();

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
