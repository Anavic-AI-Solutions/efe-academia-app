import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/api/api_provider.dart';

const supportedAppLocales = <Locale>[
  Locale('es', 'AR'),
  Locale('en'),
];

const defaultAppLocale = Locale('es', 'AR');

Locale localeFromCode(String code) {
  final parts = code.split('_');
  if (parts.length > 1 && parts[1].isNotEmpty) {
    return Locale(parts[0], parts[1]);
  }
  return Locale(parts[0]);
}

String localeToCode(Locale locale) => locale.toString();

final localeProvider = NotifierProvider<LocaleNotifier, Locale>(
  LocaleNotifier.new,
);

class LocaleNotifier extends Notifier<Locale> {
  @override
  Locale build() {
    Intl.defaultLocale = localeToCode(defaultAppLocale);
    return defaultAppLocale;
  }

  Future<void> load() async {
    try {
      final stored = await ref.read(secureStorageProvider).getLanguageCode();
      if (stored == null || stored.isEmpty) return;
      _apply(localeFromCode(stored));
    } catch (_) {
      // Keep the default locale when storage is unavailable.
    }
  }

  Future<void> setLocale(Locale locale) async {
    _apply(locale);
    try {
      await ref
          .read(secureStorageProvider)
          .saveLanguageCode(localeToCode(locale));
    } catch (_) {
      // The UI already switched; ignore persistence failures.
    }
  }

  void _apply(Locale locale) {
    state = locale;
    Intl.defaultLocale = localeToCode(locale);
  }
}
