import 'package:efe_mobile/core/widgets/gradient_header.dart';
import 'package:efe_mobile/core/widgets/pill_button.dart';
import 'package:efe_mobile/features/auth/data/auth_repository.dart';
import 'package:efe_mobile/features/auth/domain/user_model.dart';
import 'package:efe_mobile/features/auth/providers/auth_provider.dart';
import 'package:efe_mobile/features/auth/screens/login_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/localized_app.dart';

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

Future<void> _pumpLoginScreen(WidgetTester tester) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        authRepositoryProvider.overrideWithValue(_FakeAuthRepository()),
      ],
      child: localizedApp(home: const LoginScreen()),
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

  testWidgets('header uses GradientHeader with bottom radius 24', (tester) async {
    await _pumpLoginScreen(tester);

    final container = tester.widget<Container>(
      find.descendant(of: find.byType(GradientHeader), matching: find.byType(Container)),
    );
    final boxDecoration = container.decoration as BoxDecoration?;
    expect(boxDecoration, isNotNull);
    final radius = boxDecoration!.borderRadius!.resolve(TextDirection.ltr);
    // GradientHeader uses BorderRadius.vertical(bottom: Radius.circular(24))
    expect(radius.bottomLeft, const Radius.circular(24));
    expect(radius.bottomRight, const Radius.circular(24));
  });

  testWidgets('login CTA is PillButton with height 46 and radius 13', (tester) async {
    await _pumpLoginScreen(tester);

    final pillButton = tester.widget<PillButton>(find.byType(PillButton));
    expect(pillButton.height, 46);
    // PillButton uses hardcoded BorderRadius.circular(13) internally
    // We verify by checking the button renders with correct constraints
    final buttonFinder = find.descendant(
      of: find.byType(PillButton),
      matching: find.byType(ElevatedButton),
    );
    final elevatedButton = tester.widget<ElevatedButton>(buttonFinder);
    final shape = elevatedButton.style?.shape?.resolve({}) as RoundedRectangleBorder?;
    expect(shape, isNotNull);
    final borderRadius = shape!.borderRadius.resolve(TextDirection.ltr);
    expect(borderRadius.topLeft, const Radius.circular(13));
    expect(borderRadius.topRight, const Radius.circular(13));
    expect(borderRadius.bottomLeft, const Radius.circular(13));
    expect(borderRadius.bottomRight, const Radius.circular(13));
  });
}
