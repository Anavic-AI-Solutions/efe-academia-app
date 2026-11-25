import 'package:efe_mobile/core/api/api_provider.dart';
import 'package:efe_mobile/core/storage/secure_storage.dart';
import 'package:efe_mobile/features/auth/data/auth_repository.dart';
import 'package:efe_mobile/features/auth/domain/user_model.dart';
import 'package:efe_mobile/features/auth/providers/auth_provider.dart';
import 'package:efe_mobile/features/profile/screens/profile_screen.dart';
import 'package:efe_mobile/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

class _FakeSecureStorage implements SecureStorage {
  final Map<String, String> values = {};

  @override
  Future<void> saveToken(String token) async => values['auth_token'] = token;

  @override
  Future<String?> getToken() async => values['auth_token'];

  @override
  Future<void> deleteToken() async => values.remove('auth_token');

  @override
  Future<void> clearAll() async => values.clear();

  @override
  Future<void> saveThemeMode(String mode) async => values['theme_mode'] = mode;

  @override
  Future<String?> getThemeMode() async => values['theme_mode'];

  @override
  Future<void> saveLanguageCode(String code) async =>
      values['language_code'] = code;

  @override
  Future<String?> getLanguageCode() async => values['language_code'];

  @override
  Future<void> saveFcmToken(String token) async {}

  @override
  Future<String?> getFcmToken() async => null;

  @override
  Future<void> deleteFcmToken() async {}

  @override
  Future<String> getOrCreateDeviceId() async => 'test-device';

  @override
  Future<bool> hasSeenPushPrimer() async => false;

  @override
  Future<void> savePushPrimerSeen() async {}
}

class _FakeAuthRepository implements AuthRepository {
  @override
  Future<bool> hasToken() async => true;

  @override
  Future<UserModel> getCurrentUser() async => const UserModel(
        id: 'user-1',
        name: 'Ada Lovelace',
        email: 'ada@example.com',
        role: 'admin',
      );

  @override
  Future<UserModel> login({
    required String email,
    required String password,
  }) =>
      Future.error(UnimplementedError());

  @override
  Future<UserModel> register({
    required String name,
    required String email,
    required String password,
    required String passwordConfirmation,
  }) =>
      Future.error(UnimplementedError());

  @override
  Future<void> logout() => Future.error(UnimplementedError());

  @override
  Future<void> forgotPassword(String email) =>
      Future.error(UnimplementedError());

  @override
  Future<void> loadTokenIntoClient() async {}
}

void main() {
  Future<GoRouter> pumpProfile(
    WidgetTester tester, {
    Size size = const Size(400, 900),
    Future<bool> Function(Uri)? openUrl,
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(
          path: '/',
          builder: (_, __) => ProfileScreen(openUrl: openUrl),
        ),
        GoRoute(
          path: '/faqs',
          builder: (_, __) =>
              const Scaffold(body: Center(child: Text('FAQs screen'))),
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(_FakeAuthRepository()),
          secureStorageProvider.overrideWithValue(_FakeSecureStorage()),
        ],
        child: MaterialApp.router(
          routerConfig: router,
          locale: const Locale('es', 'AR'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
        ),
      ),
    );
    await tester.pumpAndSettle();
    return router;
  }

  testWidgets('about sheet shows app name, version and description',
      (tester) async {
    await pumpProfile(tester);

    final about = find.byKey(const ValueKey('profile-about-tile'));
    await tester.ensureVisible(about);
    await tester.tap(about);
    await tester.pumpAndSettle();

    expect(find.text('EFE Mobile'), findsOneWidget);
    expect(find.textContaining('1.0.1'), findsOneWidget);
    expect(
      find.text(
        'EFE Mobile es la aplicación de gestión académica de EFE Academia de Inglés.',
      ),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('help sheet offers FAQs and support email', (tester) async {
    await pumpProfile(tester);

    final help = find.byKey(const ValueKey('profile-help-tile'));
    await tester.ensureVisible(help);
    await tester.tap(help);
    await tester.pumpAndSettle();

    expect(find.text('Preguntas frecuentes'), findsOneWidget);
    expect(find.text('Escribir a soporte'), findsOneWidget);
    expect(find.text('equipo@anavic-ai.com'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('profile-help-faq-tile')));
    await tester.pumpAndSettle();

    expect(find.text('FAQs screen'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('about and help sheets scroll on small screens', (tester) async {
    await pumpProfile(tester, size: const Size(320, 568));

    final about = find.byKey(const ValueKey('profile-about-tile'));
    await tester.scrollUntilVisible(about, 200);
    await tester.tap(about);
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(
      find.text(
        '© 2026 EFE Academia de Inglés. Todos los derechos reservados.',
      ),
      findsOneWidget,
    );

    await tester.tapAt(const Offset(8, 8));
    await tester.pumpAndSettle();

    final help = find.byKey(const ValueKey('profile-help-tile'));
    await tester.scrollUntilVisible(help, 200);
    await tester.tap(help);
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Escribir a soporte'), findsOneWidget);
  });

  testWidgets('email support opens a localized mailto and reports failure',
      (tester) async {
    Uri? launched;

    await pumpProfile(
      tester,
      openUrl: (uri) async {
        launched = uri;
        return false;
      },
    );

    final help = find.byKey(const ValueKey('profile-help-tile'));
    await tester.ensureVisible(help);
    await tester.tap(help);
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('profile-help-email-tile')));
    await tester.pumpAndSettle();

    expect(launched, isNotNull);
    expect(launched!.scheme, 'mailto');
    expect(launched!.path, 'equipo@anavic-ai.com');
    expect(
      Uri.decodeQueryComponent(launched!.query),
      contains('Soporte - EFE Mobile'),
    );
    expect(
      find.text('No se pudo abrir la aplicación de correo'),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });
}
