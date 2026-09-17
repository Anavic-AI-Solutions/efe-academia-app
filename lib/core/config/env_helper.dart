import 'dart:io';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:path/path.dart' as p;

class EnvHelper {
  static const _defaultContent = 'API_BASE_URL=http://localhost:8000/api/v1';

  /// Finds or creates the .env file next to the executable and loads it.
  static Future<void> load() async {
    // Initialize dotenv (required before accessing dotenv.env)
    await dotenv.load(isOptional: true);

    // Try to find the executable directory
    String envDir;
    try {
      envDir = p.dirname(Platform.resolvedExecutable);
    } catch (_) {
      envDir = p.current;
    }

    final envFile = File(p.join(envDir, '.env'));

    if (!envFile.existsSync()) {
      envFile.writeAsStringSync(_defaultContent);
      print('');
      print('========================================');
      print('.env file created at:');
      print('  ${envFile.path}');
      print('');
      print('Edit this file to configure your API URL.');
      print('========================================');
      print('');
    }

    // Read and parse .env manually
    final content = envFile.readAsStringSync();
    for (final line in content.split('\n')) {
      final trimmed = line.trim();
      if (trimmed.isEmpty || trimmed.startsWith('#')) continue;
      final eq = trimmed.indexOf('=');
      if (eq == -1) continue;
      final key = trimmed.substring(0, eq).trim();
      final value = trimmed.substring(eq + 1).trim();
      dotenv.env[key] = value;
    }

    // ignore: avoid_print
    print('[ENV] Loaded from: ${envFile.path}');
    // ignore: avoid_print
    print('[ENV] API_BASE_URL: ${dotenv.env['API_BASE_URL']}');
  }
}
