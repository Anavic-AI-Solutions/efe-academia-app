import 'package:efe_mobile/app/theme/app_colors.dart';
import 'package:efe_mobile/features/auth/data/auth_repository.dart';
import 'package:efe_mobile/features/auth/domain/user_model.dart';
import 'package:efe_mobile/features/auth/providers/auth_provider.dart';
import 'package:efe_mobile/features/auth/screens/login_screen.dart';
import 'package:efe_mobile/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

const _logoAsset = 'assets/images/efe_logo_white.png';

class _FakeAuthRepository implements AuthRepository {
  @override
  Future<bool> hasToken() async => false;

  @override
  Future<UserModel> getCurrentUser() => Future.error(UnimplementedError());

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
  Future<void> loadTokenIntoClient() => Future.error(UnimplementedError());
}

Future<void> _pumpLoginScreen(WidgetTester tester,
    {bool isDark = false}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        authRepositoryProvider.overrideWithValue(_FakeAuthRepository()),
      ],
      child: MaterialApp(
        locale: const Locale('es'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        theme: isDark ? ThemeData.dark() : ThemeData.light(),
        home: const LoginScreen(),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('renders the efe-app wordmark in the header', (tester) async {
    await _pumpLoginScreen(tester);

    final logo = tester.widget<Image>(
      find.byWidgetPredicate(
        (widget) =>
            widget is Image &&
            widget.image is AssetImage &&
            (widget.image as AssetImage).assetName == _logoAsset,
      ),
    );

    expect(logo.semanticLabel, 'EFE');
  });

  testWidgets('drops the ERP subtitle and the duplicate EFE text',
      (tester) async {
    await _pumpLoginScreen(tester);

    expect(find.text('Educational ERP for Nursing Schools'), findsNothing);
    expect(find.text('EFE'), findsNothing);
  });

  test('bundles the efe-app wordmark asset', () async {
    final data = await rootBundle.load(_logoAsset);

    expect(data.lengthInBytes, greaterThan(0));
  });

  group('dark mode support', () {
    testWidgets('uses AppColors.backgroundFor(true) as Scaffold background',
        (tester) async {
      await _pumpLoginScreen(tester, isDark: true);

      final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
      expect(scaffold.backgroundColor, AppColors.backgroundFor(true));
    });

    testWidgets('uses dark-aware text colors (inkFor/mutedFor) in form',
        (tester) async {
      await _pumpLoginScreen(tester, isDark: true);

      // Verify no hardcoded light colors in form text
      expect(find.byWidgetPredicate((w) =>
          w is Text && w.style?.color == AppColors.lightTextPrimary),
          findsNothing);
      expect(find.byWidgetPredicate((w) =>
          w is Text && w.style?.color == AppColors.lightTextSecondary),
          findsNothing);
    });
  });
}
