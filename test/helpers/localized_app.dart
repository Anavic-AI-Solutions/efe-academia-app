import 'package:efe_mobile/app/locale/locale_provider.dart';
import 'package:efe_mobile/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

const testLocale = Locale('es', 'AR');

MaterialApp localizedApp({
  required Widget home,
  Locale locale = testLocale,
}) {
  return MaterialApp(
    locale: locale,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: home,
  );
}

Widget localizedAppWithLocaleProvider({required Widget home}) {
  return Consumer(
    builder: (context, ref, _) {
      final locale = ref.watch(localeProvider);
      return localizedApp(home: home, locale: locale);
    },
  );
}
