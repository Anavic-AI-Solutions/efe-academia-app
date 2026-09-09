import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:firebase_core/firebase_core.dart';

import 'app/app.dart';
import 'shared/services/push_notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load();
  await Firebase.initializeApp();

  final container = ProviderContainer();
  final pushService = container.read(pushNotificationServiceProvider);
  await pushService.initialize();
  await pushService.registerToken();

  runApp(const ProviderScope(child: EfeApp()));
}
