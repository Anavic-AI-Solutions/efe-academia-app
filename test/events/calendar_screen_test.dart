import 'package:efe_mobile/features/events/domain/event_model.dart';
import 'package:efe_mobile/features/events/providers/event_provider.dart';
import 'package:efe_mobile/features/events/screens/calendar_screen.dart';
import 'package:efe_mobile/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

/// Octubre 2026: el 1° es jueves. Eventos el 5 y el 12.
List<EventModel> _octoberEvents() => [
      EventModel(
        id: 'e1',
        title: 'Acto escolar',
        description: 'Patio central',
        start: DateTime(2026, 10, 5, 10),
      ),
      EventModel(
        id: 'e2',
        title: 'Reunión de padres',
        start: DateTime(2026, 10, 12, 18),
      ),
    ];

/// Monta [CalendarScreen] en octubre 2026 con el provider de mes stubbeado.
Future<void> _pumpCalendar(
  WidgetTester tester, {
  required Future<List<EventModel>> Function(DateTime month) load,
  DateTime? initialMonth,
}) async {
  final router = GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        builder: (_, __) => CalendarScreen(
          initialMonth: initialMonth ?? DateTime(2026, 10),
        ),
      ),
      GoRoute(
        path: '/events',
        builder: (_, __) =>
            const Scaffold(body: Center(child: Text('Events screen'))),
      ),
    ],
  );
  addTearDown(router.dispose);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        calendarMonthProvider.overrideWith((ref, month) => load(month)),
      ],
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
  group('CalendarScreen', () {
    testWidgets('grilla marca días con eventos', (tester) async {
      await _pumpCalendar(tester, load: (_) async => _octoberEvents());

      // Dots solo en los días con eventos.
      expect(find.byKey(const ValueKey('event-dot-2026-10-5')), findsOneWidget);
      expect(
        find.byKey(const ValueKey('event-dot-2026-10-12')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('event-dot-2026-10-6')),
        findsNothing,
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('evento sin fecha nunca aparece en la lista del día', (
      tester,
    ) async {
      await _pumpCalendar(
        tester,
        load: (_) async => [
          ..._octoberEvents(),
          const EventModel(id: 'e3', title: 'Evento sin fecha'),
        ],
      );

      // Día con evento: solo el evento de ese día, sin el dateless.
      await tester.tap(find.text('5'));
      await tester.pumpAndSettle();
      expect(find.text('Acto escolar', skipOffstage: false), findsOneWidget);
      expect(
        find.text('Evento sin fecha', skipOffstage: false),
        findsNothing,
      );

      // Día vacío: vacío real, sin el dateless colado.
      await tester.tap(find.text('6'));
      await tester.pumpAndSettle();
      expect(
        find.text('No hay eventos', skipOffstage: false),
        findsOneWidget,
      );
      expect(
        find.text('Evento sin fecha', skipOffstage: false),
        findsNothing,
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('tap en un día filtra la lista', (tester) async {
      await _pumpCalendar(tester, load: (_) async => _octoberEvents());

      await tester.tap(find.text('12'));
      await tester.pumpAndSettle();

      // La lista del día vive debajo de la grilla: puede estar offstage.
      expect(
        find.text('Reunión de padres', skipOffstage: false),
        findsOneWidget,
      );
      expect(
        find.text('Acto escolar', skipOffstage: false),
        findsNothing,
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('flechas de mes recargan', (tester) async {
      final requested = <DateTime>[];
      await _pumpCalendar(
        tester,
        load: (month) async {
          requested.add(month);
          return _octoberEvents();
        },
      );

      expect(requested, isNotEmpty);
      requested.clear();

      await tester.tap(find.byKey(const ValueKey('calendar-next-month')));
      await tester.pumpAndSettle();

      expect(
        requested.any((m) => m.year == 2026 && m.month == 11),
        isTrue,
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('estado vacío', (tester) async {
      await _pumpCalendar(tester, load: (_) async => <EventModel>[]);

      // El estado vacío vive debajo de la grilla: puede estar offstage.
      expect(
        find.text('No hay eventos', skipOffstage: false),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('estado de error con reintento', (tester) async {
      var calls = 0;
      await _pumpCalendar(
        tester,
        load: (_) async {
          calls++;
          throw Exception('red caída');
        },
      );

      expect(find.text('No se pudieron cargar los eventos'), findsOneWidget);
      expect(find.text('Reintentar'), findsOneWidget);
      expect(calls, 1);

      await tester.tap(find.text('Reintentar'));
      await tester.pumpAndSettle();
      expect(calls, 2);
      expect(tester.takeException(), isNull);
    });

    testWidgets('acción ver lista navega a /events', (tester) async {
      await _pumpCalendar(tester, load: (_) async => _octoberEvents());

      expect(
        find.text(DateFormat('MMMM yyyy').format(DateTime(2026, 10))),
        findsOneWidget,
      );
      await tester.tap(find.text('Ver lista'));
      await tester.pumpAndSettle();
      expect(find.text('Events screen'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('header usa acciones compactas en pantalla angosta',
        (tester) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await _pumpCalendar(tester, load: (_) async => _octoberEvents());

      expect(
        find.text(DateFormat('MMM yyyy').format(DateTime(2026, 10))),
        findsOneWidget,
      );
      final monthTitle = tester.widget<Text>(find.textContaining('2026').first);
      expect(monthTitle.maxLines, 1);
      expect(monthTitle.style?.fontSize, 20);
      expect(find.text('Ver lista'), findsNothing);
      expect(find.byKey(const ValueKey('calendar-view-list')), findsOneWidget);

      final previous = tester.widget<IconButton>(
        find.byKey(const ValueKey('calendar-prev-month')),
      );
      final next = tester.widget<IconButton>(
        find.byKey(const ValueKey('calendar-next-month')),
      );
      expect(previous.tooltip, isNotNull);
      expect(next.tooltip, isNotNull);
      expect(tester.takeException(), isNull);

      await tester.tap(find.byKey(const ValueKey('calendar-view-list')));
      await tester.pumpAndSettle();
      expect(find.text('Events screen'), findsOneWidget);
    });
  });
}
