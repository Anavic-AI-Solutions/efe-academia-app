import 'dart:io';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:path/path.dart' as p;

class EnvHelper {
  static const _fallbackApiBaseUrl = 'http://localhost:8000/api/v1';
  static const _repeatedKeys = [
    'REVERB_HOST',
    'REVERB_PORT',
    'REVERB_APP_KEY',
    'REVERB_SCHEME',
  ];

  /// Contenido para el `.env` que se crea junto al ejecutable: usa el
  /// `API_BASE_URL` del build (asset embebido) y solo `localhost` de fallback,
  /// y replica las claves `REVERB_*` presentes y no vacías.
  static String buildDefaultEnvContent(Map<String, String> buildValues) {
    final apiBaseUrl = buildValues['API_BASE_URL'];
    final resolved = (apiBaseUrl == null || apiBaseUrl.isEmpty)
        ? _fallbackApiBaseUrl
        : apiBaseUrl;
    final buffer = StringBuffer('API_BASE_URL=$resolved\n');
    for (final key in _repeatedKeys) {
      final value = buildValues[key];
      if (value != null && value.isNotEmpty) {
        buffer.writeln('$key=$value');
      }
    }
    return buffer.toString();
  }

  /// Parsea un archivo `.env`: soporta CRLF, ignora líneas vacías y comentarios,
  /// corta en el primer `=`, recorta espacios y permite `=` dentro del valor.
  static Map<String, String> parseEnvContent(String content) {
    final result = <String, String>{};
    for (final line in content.split('\n')) {
      final trimmed = line.trim();
      if (trimmed.isEmpty || trimmed.startsWith('#')) continue;
      final eq = trimmed.indexOf('=');
      if (eq <= 0) continue;
      final key = trimmed.substring(0, eq).trim();
      if (key.isEmpty) continue;
      final value = trimmed.substring(eq + 1).trim();
      result[key] = value;
    }
    return result;
  }

  /// Finds or creates the .env file next to the executable and loads it.
  static Future<void> load() async {
    // Initialize dotenv (required before accessing dotenv.env)
    await dotenv.load(isOptional: true);

    try {
      final envFile = _envFileNextToExecutable();
      if (envFile == null) {
        // ignore: avoid_print
        print('[ENV] No se pudo resolver el directorio del ejecutable');
      } else {
        if (!envFile.existsSync()) {
          envFile.writeAsStringSync(buildDefaultEnvContent(dotenv.env));
          // ignore: avoid_print
          print('');
          // ignore: avoid_print
          print('========================================');
          // ignore: avoid_print
          print('.env file created at:');
          // ignore: avoid_print
          print('  ${envFile.path}');
          // ignore: avoid_print
          print('');
          // ignore: avoid_print
          print('Edit this file to configure your API URL.');
          // ignore: avoid_print
          print('========================================');
          // ignore: avoid_print
          print('');
        }

        // Read and parse .env manually
        final parsed = parseEnvContent(envFile.readAsStringSync());
        for (final entry in parsed.entries) {
          dotenv.env[entry.key] = entry.value;
        }
        // ignore: avoid_print
        print('[ENV] Loaded from: ${envFile.path}');
      }
    } catch (e) {
      // ignore: avoid_print
      print('[ENV] No se pudo usar el .env del filesystem: $e');
    }

    // ignore: avoid_print
    print('[ENV] API_BASE_URL: ${dotenv.env['API_BASE_URL']}');
  }

  static File? _envFileNextToExecutable() {
    try {
      final envDir = p.dirname(Platform.resolvedExecutable);
      return File(p.join(envDir, '.env'));
    } catch (_) {
      return null;
    }
  }
}
