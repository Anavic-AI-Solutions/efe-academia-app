import 'package:efe_mobile/core/widgets/empty_state.dart';
import 'package:efe_mobile/features/auth/data/auth_repository.dart';
import 'package:efe_mobile/features/auth/domain/user_model.dart';
import 'package:efe_mobile/features/auth/providers/auth_provider.dart';
import 'package:efe_mobile/features/management/screens/management_hub_screen.dart';
import 'package:efe_mobile/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

const _newsDestination = Key('news-destination');

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

Future<void> _pumpHub(WidgetTester tester, String role) async {
  final container = ProviderContainer(
    overrides: [
      authRepositoryProvider.overrideWithValue(_FakeAuthRepository(role)),
    ],
  );
  addTearDown(container.dispose);

  final router = GoRouter(
    initialLocation: '/management',
    routes: [
      GoRoute(
        path: '/management',
        builder: (context, state) => const ManagementHubScreen(),
      ),
      GoRoute(
        path: '/news',
        builder: (context, state) => const Scaffold(
          key: _newsDestination,
          body: SizedBox.shrink(),
        ),
      ),
    ],
  );
  addTearDown(router.dispose);

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp.router(
        routerConfig: router,
        locale: const Locale('es', 'AR'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('admin hub lists the six management links', (tester) async {
    await _pumpHub(tester, 'admin');

    expect(find.text('Personas'), findsOneWidget);
    expect(find.text('Académico'), findsOneWidget);
    expect(find.text('Contenido'), findsOneWidget);

    for (final label in [
      'Alumnos',
      'Aulas',
      'Noticias',
      'Eventos',
      'Documentos',
      'Preguntas frecuentes',
    ]) {
      await tester.scrollUntilVisible(
        find.text(label),
        120,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text(label), findsOneWidget, reason: 'missing $label');
    }

    expect(find.byType(EmptyState), findsNothing);
  });

  testWidgets('tapping Noticias opens the news screen', (tester) async {
    await _pumpHub(tester, 'admin');

    await tester.tap(find.text('Noticias'));
    await tester.pumpAndSettle();

    expect(find.byKey(_newsDestination), findsOneWidget);
  });

  testWidgets('non-staff hub shows the empty state', (tester) async {
    await _pumpHub(tester, 'parent');

    expect(find.byType(EmptyState), findsOneWidget);
    expect(find.text('Alumnos'), findsNothing);
    expect(find.text('Aulas'), findsNothing);
    expect(find.text('Noticias'), findsNothing);
    expect(find.text('Eventos'), findsNothing);
    expect(find.text('Documentos'), findsNothing);
    expect(find.text('Preguntas frecuentes'), findsNothing);
  });
}
