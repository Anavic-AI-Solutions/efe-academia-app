import 'package:efe_mobile/features/auth/data/auth_repository.dart';
import 'package:efe_mobile/features/auth/domain/user_model.dart';
import 'package:efe_mobile/features/auth/providers/auth_provider.dart';
import 'package:efe_mobile/features/auth/screens/forgot_password_screen.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

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

Future<void> _pumpForgotPasswordScreen(WidgetTester tester) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        authRepositoryProvider.overrideWithValue(_FakeAuthRepository()),
      ],
      child: localizedApp(
        home: const ForgotPasswordScreen(),
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

      expect(find.byIcon(PhosphorIconsRegular.lockKey), findsOneWidget);
    });

    testWidgets('shows form with email field and send button', (tester) async {
      await _pumpForgotPasswordScreen(tester);

      expect(find.text('Correo electrónico'), findsOneWidget);
      expect(find.text('Enviar enlace de restablecimiento'), findsOneWidget);
    });

    group('dark mode support', () {
      testWidgets('TODO: add dark mode test with theme provider',
          (tester) async {
        // Dark mode test requires theme provider setup; skipped for now
        expect(true, isTrue);
      });
    });
  });
}
