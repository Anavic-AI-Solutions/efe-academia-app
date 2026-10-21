import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/chat/providers/chat_provider.dart';
import '../features/notifications/providers/notification_provider.dart';
import '../l10n/app_localizations.dart';
import '../core/realtime/realtime_providers.dart';
import 'locale/locale_provider.dart';
import 'router.dart';
import 'theme/app_theme.dart';
import 'theme/theme_provider.dart';

class EfeApp extends ConsumerStatefulWidget {
  const EfeApp({super.key});

  @override
  ConsumerState<EfeApp> createState() => _EfeAppState();
}

class _EfeAppState extends ConsumerState<EfeApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// Al volver del segundo plano se relee el badge de no leídos y se refresca
  /// la primera página de chats: el socket pudo perderse mientras la app
  /// dormía y el REST es la red de seguridad.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state != AppLifecycleState.resumed) return;
    ref.read(chatUnreadCountControllerProvider).refresh();
    ref.read(chatListProvider.notifier).refreshFirstPage();
    ref.invalidate(unreadCountProvider);
  }

  @override
  Widget build(BuildContext context) {
    // Mounts the realtime coordinator: it owns the socket lifecycle tied to
    // the session, so without this watch the app never connects.
    ref.watch(realtimeCoordinatorProvider);
    final router = ref.watch(routerProvider);
    final locale = ref.watch(localeProvider);
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp.router(
      title: 'EFE',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeMode,
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      routerConfig: router,
    );
  }
}
