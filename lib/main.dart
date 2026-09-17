import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/app.dart';
import 'core/config/env_helper.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load .env from filesystem (creates if missing)
  await EnvHelper.load();

  runApp(const ProviderScope(child: EfeApp()));
}
