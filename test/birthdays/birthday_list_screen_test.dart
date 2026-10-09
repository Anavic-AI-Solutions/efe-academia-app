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
        todayBirthdaysProvider.overrideWith(
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
  group('BirthdayListScreen', () {
    testWidgets('lista de hoy renderiza nombres y edades', (tester) async {
      await _pumpBirthdays(
        tester,
        birthdays: (ref) async => const [
          BirthdayModel(
            id: 'b1',
            name: 'Ana Ruiz',
            ageTurning: 8,
            studentAppId: 's1',
          ),
          BirthdayModel(id: 'b2', name: 'Luis Paz', ageTurning: 9),
        ],
      );

      expect(find.text('Ana Ruiz'), findsOneWidget);
      expect(find.text('Luis Paz'), findsOneWidget);
      expect(find.text('8'), findsOneWidget);
      expect(find.text('9'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('tap navega al detalle del alumno', (tester) async {
      await _pumpBirthdays(
        tester,
        birthdays: (ref) async => const [
          BirthdayModel(
            id: 'b1',
            name: 'Ana Ruiz',
            ageTurning: 8,
            studentAppId: 's1',
          ),
        ],
      );

      await tester.tap(find.text('Ana Ruiz'));
      await tester.pumpAndSettle();
      expect(find.text('Student s1'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('backend ausente muestra fallback próximamente', (
      tester,
    ) async {
      await _pumpBirthdays(tester, birthdaysAvailable: false);

      expect(find.text('Disponible próximamente'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('sin cumpleaños muestra vacío normal', (tester) async {
      await _pumpBirthdays(tester);

      expect(find.text('No hay cumpleaños hoy'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('error con reintento', (tester) async {
      var calls = 0;
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            todayBirthdaysProvider.overrideWith((ref) async {
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
  });
}
