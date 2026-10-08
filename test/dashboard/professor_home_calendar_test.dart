import 'package:efe_mobile/features/dashboard/screens/widgets/home_calendar_section.dart';
import 'package:efe_mobile/features/events/domain/event_model.dart';
import 'package:efe_mobile/features/events/providers/event_provider.dart';
import 'package:efe_mobile/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

List<EventModel> _events(int count) => List<EventModel>.generate(
      count,
      (i) => EventModel(
        id: 'e$i',
        title: 'Evento $i',
        start: DateTime(2026, 10, 9 + i, 9),
      ),
    );

GoRouter _router() => GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(
          path: '/',
          builder: (_, __) => const Scaffold(
            body: SingleChildScrollView(child: HomeCalendarSection()),
          ),
        ),
        GoRoute(
          path: '/events',
          builder: (_, __) =>
              const Scaffold(body: Center(child: Text('Events screen'))),
        ),
      ],
    );

Future<void> _pumpSection(
  WidgetTester tester,
  GoRouter router,
  Future<List<EventModel>> Function(Ref ref) calendar,
) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [homeCalendarProvider.overrideWith(calendar)],
      child: MaterialApp.router(
        routerConfig: router,
        locale: const Locale('es'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  group('HomeCalendarSection', () {
    testWidgets('sección muestra 5 y link a eventos', (tester) async {
      final router = _router();
      addTearDown(router.dispose);

      await _pumpSection(tester, router, (ref) async => _events(6));

      for (var i = 0; i < 5; i++) {
        expect(find.text('Evento $i'), findsOneWidget);
      }
      expect(find.text('Evento 5'), findsNothing);

      await tester.tap(find.text('Ver todo'));
      await tester.pumpAndSettle();

      expect(find.text('Events screen'), findsOneWidget);
    });

    testWidgets('muestra estado de error con reintento', (tester) async {
      final router = _router();
      addTearDown(router.dispose);

      await _pumpSection(
        tester,
        router,
        (ref) => Future<List<EventModel>>.error(Exception('boom')),
      );

      // Comparte el título de error de eventos sin tapar el resto del home.
      expect(find.text('No se pudieron cargar los eventos'), findsOneWidget);
      expect(find.text('Reintentar'), findsOneWidget);
    });
  });
}
