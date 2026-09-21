import 'package:efe_mobile/app/locale/locale_provider.dart';
import 'package:efe_mobile/core/api/api_provider.dart';
import 'package:efe_mobile/core/storage/secure_storage.dart';
import 'package:efe_mobile/features/auth/data/auth_repository.dart';
import 'package:efe_mobile/features/auth/domain/user_model.dart';
import 'package:efe_mobile/features/auth/providers/auth_provider.dart';
import 'package:efe_mobile/features/profile/screens/profile_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/localized_app.dart';

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
  testWidgets('switches the app to English and persists the choice',
      (tester) async {
    tester.view.physicalSize = const Size(400 * 3, 900 * 3);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);

    final storage = _FakeSecureStorage();
    final container = ProviderContainer(
      overrides: [
        authRepositoryProvider.overrideWithValue(_FakeAuthRepository()),
        secureStorageProvider.overrideWithValue(storage),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: localizedAppWithLocaleProvider(home: const ProfileScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(container.read(localeProvider), const Locale('es', 'AR'));
    expect(find.text('Idioma'), findsOneWidget);
    expect(find.text('Español'), findsOneWidget);

    await tester.tap(find.text('Idioma'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('English'));
    await tester.pumpAndSettle();

    expect(container.read(localeProvider), const Locale('en'));
    expect(storage.values['language_code'], 'en');
    expect(find.text('Language'), findsOneWidget);
    expect(find.text('Idioma'), findsNothing);
    expect(find.text('English'), findsOneWidget);
  });
}
