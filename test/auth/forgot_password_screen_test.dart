import 'package:efe_mobile/app/theme/app_colors.dart';
import 'package:efe_mobile/features/auth/data/auth_repository.dart';
import 'package:efe_mobile/features/auth/domain/user_model.dart';
import 'package:efe_mobile/features/auth/providers/auth_provider.dart';
import 'package:efe_mobile/features/auth/screens/forgot_password_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/localized_app.dart';

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

Future<void> _pumpForgotPasswordScreen(WidgetTester tester,
    {bool isDark = false}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        authRepositoryProvider.overrideWithValue(_FakeAuthRepository()),
      ],
      child: localizedApp(
        home: MaterialApp(
          theme: isDark ? ThemeData.dark() : ThemeData.light(),
          home: const ForgotPasswordScreen(),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('forgot password screen', () {
    testWidgets('renders the lock-key icon in the header', (tester) async {
      await _pumpForgotPasswordScreen(tester);

      expect(find.byIcon(Icons.lock_outline), findsOneWidget);
    });

    testWidgets('shows form with email field and send button', (tester) async {
      await _pumpForgotPasswordScreen(tester);

      expect(find.text('Correo electrónico'), findsOneWidget);
      expect(find.text('Enviar enlace de restablecimiento'), findsOneWidget);
    });

    group('dark mode support', () {
      testWidgets('uses AppColors.backgroundFor(true) as Scaffold background',
          (tester) async {
        await _pumpForgotPasswordScreen(tester, isDark: true);

        final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
        expect(scaffold.backgroundColor, AppColors.backgroundFor(true));
      });

      testWidgets('uses dark-aware text colors (inkFor/mutedFor) in form',
          (tester) async {
        await _pumpForgotPasswordScreen(tester, isDark: true);

        // Verify no hardcoded light colors in form text
        expect(find.byWidgetPredicate((w) =>
            w is Text && w.style?.color == AppColors.lightTextPrimary),
            findsNothing);
        expect(find.byWidgetPredicate((w) =>
            w is Text && w.style?.color == AppColors.lightTextSecondary),
            findsNothing);
      });
    });
  });
}