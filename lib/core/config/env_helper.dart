import 'dart:io';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:path/path.dart' as p;

class EnvHelper {
  static const _defaultContent = 'API_BASE_URL=http://localhost:8000/api/v1';

  /// Finds or creates the .env file next to the executable and loads it.
  static Future<void> load() async {
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

    // Load from the filesystem .env (overrides asset .env)
    await dotenv.load(fileName: envFile.path);

    // ignore: avoid_print
    print('[ENV] Loaded from: ${envFile.path}');
    // ignore: avoid_print
    print('[ENV] API_BASE_URL: ${dotenv.env['API_BASE_URL']}');
  }
}
