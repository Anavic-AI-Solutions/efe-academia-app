import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'app/app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Load .env file if it exists, otherwise use defaults
  try {
    await dotenv.load();
  } catch (e) {
    // .env file not found - will use default values
    debugPrint('Note: .env file not found, using default configuration');
  }
  
  runApp(const ProviderScope(child: EfeApp()));
}
