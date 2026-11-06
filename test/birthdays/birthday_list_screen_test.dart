import 'package:efe_mobile/features/birthdays/domain/birthday_model.dart';
import 'package:efe_mobile/features/birthdays/providers/birthday_provider.dart';
import 'package:efe_mobile/features/birthdays/screens/birthday_list_screen.dart';
import 'package:efe_mobile/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

Future<void> _pumpBirthdays(
  WidgetTester tester, {
  Future<List<BirthdayModel>> Function(Ref ref)? birthdays,
  bool birthdaysAvailable = true,
}) async {
  final router = GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        builder: (_, __) => const BirthdayListScreen(),
      ),
      GoRoute(
        path: '/students/:id',
        builder: (_, state) => Scaffold(
          body: Center(
            child: Text('Student ${state.pathParameters['id']}'),
          ),
        ),
      ),
    ],
  );
  addTearDown(router.dispose);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        upcomingBirthdaysProvider.overrideWith(
          birthdays ?? (ref) async => <BirthdayModel>[],
        ),
        birthdaysAvailableProvider.overrideWith((ref) => birthdaysAvailable),
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
  final todayBirthday = BirthdayModel(
    id: 'b1',
    name: 'Ana Ruiz',
    ageTurning: 8,
    studentAppId: 's1',
    birthDate: DateTime(2018, 10, 8),
  );
  final tomorrowBirthday = BirthdayModel(
    id: 'b2',
    name: 'Luis Paz',
    ageTurning: 9,
    daysUntil: 1,
    birthDate: DateTime(2017, 11, 7),
  );
  final soonBirthday = BirthdayModel(
    id: 'b3',
    name: 'Marta Díaz',
    ageTurning: 10,
    daysUntil: 5,
    birthDate: DateTime(2016, 11, 11),
  );

  group('BirthdayListScreen', () {
    testWidgets('agrupa hoy y próximos con fecha, edad y días', (tester) async {
      await _pumpBirthdays(
        tester,
        birthdays: (ref) async => [
          todayBirthday,
          tomorrowBirthday,
          soonBirthday,
        ],
      );

      expect(find.text('Cumpleaños de hoy'), findsOneWidget);
      expect(find.text('Próximos 30 días'), findsOneWidget);
      expect(find.text('Ana Ruiz'), findsOneWidget);
      expect(find.text('Luis Paz'), findsOneWidget);
      expect(find.text('Marta Díaz'), findsOneWidget);
      expect(find.text('Hoy'), findsOneWidget);
      expect(find.text('Mañana'), findsOneWidget);
      expect(find.text('En 5 días'), findsOneWidget);
      expect(find.text('Cumple 8 años'), findsOneWidget);
      expect(find.text('8/10'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('tap navega al detalle del alumno', (tester) async {
      await _pumpBirthdays(
        tester,
        birthdays: (ref) async => [todayBirthday],
      );

      await tester.tap(find.text('Ana Ruiz'));
      await tester.pumpAndSettle();
      expect(find.text('Student s1'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('solo hoy muestra el vacío de próximos', (tester) async {
      await _pumpBirthdays(
        tester,
        birthdays: (ref) async => [todayBirthday],
      );

      expect(find.text('Cumpleaños de hoy'), findsOneWidget);
      expect(find.text('Próximos 30 días'), findsOneWidget);
      expect(
        find.text('No hay más cumpleaños en los próximos 30 días'),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('sin cumpleaños muestra vacío general', (tester) async {
      await _pumpBirthdays(tester);

      expect(
        find.text('No hay más cumpleaños en los próximos 30 días'),
        findsOneWidget,
      );
      expect(find.text('Cumpleaños de hoy'), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('backend ausente muestra fallback próximamente', (
      tester,
    ) async {
      await _pumpBirthdays(tester, birthdaysAvailable: false);

      expect(find.text('Disponible próximamente'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('error con reintento', (tester) async {
      var calls = 0;
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            upcomingBirthdaysProvider.overrideWith((ref) async {
              calls++;
              throw Exception('red caída');
            }),
            birthdaysAvailableProvider.overrideWith((ref) => true),
          ],
          child: MaterialApp.router(
            routerConfig: GoRouter(
              initialLocation: '/',
              routes: [
                GoRoute(
                  path: '/',
                  builder: (_, __) => const BirthdayListScreen(),
                ),
              ],
            ),
            locale: const Locale('es'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Reintentar'), findsOneWidget);
      expect(calls, 1);

      await tester.tap(find.text('Reintentar'));
      await tester.pumpAndSettle();
      expect(calls, 2);
      expect(tester.takeException(), isNull);
    });

    testWidgets('pull-to-refresh funciona en el fallback', (tester) async {
      var calls = 0;
      await _pumpBirthdays(
        tester,
        birthdaysAvailable: false,
        birthdays: (ref) async {
          calls++;
          return <BirthdayModel>[];
        },
      );
      expect(calls, 1);

      await tester.fling(
        find.byType(Scrollable),
        const Offset(0, 400),
        1000,
      );
      await tester.pumpAndSettle();

      expect(calls, 2);
      expect(tester.takeException(), isNull);
    });

    testWidgets('sin studentAppId no navega al alumno', (tester) async {
      await _pumpBirthdays(
        tester,
        birthdays: (ref) async => [
          BirthdayModel(
            id: 'b1',
            name: 'Sin App',
            ageTurning: 8,
            birthDate: DateTime(2018, 1, 1),
          ),
        ],
      );

      await tester.tap(find.text('Sin App'));
      await tester.pumpAndSettle();

      expect(find.byType(BirthdayListScreen), findsOneWidget);
      expect(find.textContaining('Student'), findsNothing);
      expect(tester.takeException(), isNull);
    });
  });
}
