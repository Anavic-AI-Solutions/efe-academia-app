import 'package:flutter/material.dart';
import 'theme/app_theme.dart';

class EfeApp extends StatelessWidget {
  const EfeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'EFE',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.system,
      home: const Scaffold(body: Center(child: Text('EFE App'))),
    );
  }
}
