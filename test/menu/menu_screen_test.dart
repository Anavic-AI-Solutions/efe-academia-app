import 'package:efe_mobile/features/auth/data/auth_repository.dart';
import 'package:efe_mobile/features/auth/domain/user_model.dart';
import 'package:efe_mobile/features/auth/providers/auth_provider.dart';
import 'package:efe_mobile/features/menu/screens/menu_screen.dart';
import 'package:efe_mobile/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeAuthRepository implements AuthRepository {
  _FakeAuthRepository(this.role);

  final String role;

  @override
  Future<UserModel> getCurrentUser() async => UserModel(
        id: '1',
        name: 'Test User',
        email: 'test@example.com',
        role: role,
      );

  @override
  Future<bool> hasToken() async => true;

  @override
  Future<void> loadTokenIntoClient() async {}

  @override
  Future<UserModel> login({required String email, required String password}) =>
      getCurrentUser();

  @override
  Future<UserModel> register({
    required String name,
    required String email,
    required String password,
    required String passwordConfirmation,
  }) =>
      getCurrentUser();

  @override
  Future<void> logout() async {}

  @override
  Future<void> forgotPassword(String email) async {}
}

Future<ProviderContainer> _pumpMenu(WidgetTester tester, String role) async {
  final container = ProviderContainer(
    overrides: [
      authRepositoryProvider.overrideWithValue(_FakeAuthRepository(role)),
    ],
  );
  addTearDown(container.dispose);

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        locale: const Locale('es', 'AR'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const MenuScreen(),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return container;
}

void main() {
  testWidgets('admin menu lists the twelve sections grouped by area',
      (tester) async {
    await _pumpMenu(tester, 'admin');

    expect(find.text('Académico'), findsOneWidget);

    const labels = [
      'Calendario',
      'Cursos',
      'Historial',
      'Biblioteca',
      'Documentos',
      'Estadísticas',
      'Comunicación',
      'Perfil',
      'Cumpleaños',
      'FAQ',
    ];

    for (final label in labels) {
      await tester.scrollUntilVisible(
        find.text(label),
        120,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text(label), findsOneWidget, reason: 'missing $label');
    }

    // Admin must not see student-only sections.
    expect(find.text('Notificaciones'), findsNothing);
    expect(find.text('Cuotas'), findsNothing);
  });

  testWidgets('student menu shows notifications and fees, not birthdays',
      (tester) async {
    await _pumpMenu(tester, 'student');

    await tester.scrollUntilVisible(
      find.text('Notificaciones'),
      120,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Notificaciones'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('Cuotas'),
      120,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Cuotas'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('FAQ'),
      120,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Cumpleaños'), findsNothing);
  });
}
