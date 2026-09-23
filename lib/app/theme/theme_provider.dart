import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/api_provider.dart';

const defaultAppThemeMode = ThemeMode.light;

const _themeModeNames = <ThemeMode, String>{
  ThemeMode.light: 'light',
  ThemeMode.dark: 'dark',
  ThemeMode.system: 'system',
};

ThemeMode? themeModeFromName(String name) {
  for (final entry in _themeModeNames.entries) {
    if (entry.value == name) return entry.key;
  }
  return null;
}

String themeModeToName(ThemeMode mode) =>
    _themeModeNames[mode] ?? _themeModeNames[defaultAppThemeMode]!;

final themeModeProvider = NotifierProvider<ThemeModeNotifier, ThemeMode>(
  ThemeModeNotifier.new,
);

class ThemeModeNotifier extends Notifier<ThemeMode> {
  @override
  ThemeMode build() => defaultAppThemeMode;

  Future<void> load() async {
    try {
      final stored = await ref.read(secureStorageProvider).getThemeMode();
      if (stored == null || stored.isEmpty) return;
      final mode = themeModeFromName(stored);
      if (mode != null) state = mode;
    } catch (_) {
      // Keep the default theme when storage is unavailable.
    }
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    state = mode;
    try {
      await ref
          .read(secureStorageProvider)
          .saveThemeMode(themeModeToName(mode));
    } catch (_) {
      // The UI already switched; ignore persistence failures.
    }
  }
}
