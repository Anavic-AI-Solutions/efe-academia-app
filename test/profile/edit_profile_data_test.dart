import 'dart:async';
import 'dart:typed_data';

import 'package:efe_mobile/core/api/api_exception.dart';
import 'package:efe_mobile/features/auth/data/auth_repository.dart';
import 'package:efe_mobile/features/auth/domain/user_model.dart';
import 'package:efe_mobile/features/auth/providers/auth_provider.dart';
import 'package:efe_mobile/features/profile/data/profile_repository.dart';
import 'package:efe_mobile/features/profile/providers/profile_provider.dart';
import 'package:efe_mobile/features/profile/screens/edit_profile_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/localized_app.dart';

const _currentUser = UserModel(
  id: '1',
  name: 'Old Name',
  email: 'old@example.com',
  role: 'professor',
  avatarUrl: 'https://cdn/a.png',
  branchName: 'Sede Centro',
);

// ---------------------------------------------------------------------------
// Fakes
// ---------------------------------------------------------------------------

/// Repository that never resolves: keeps the real [AuthNotifier] constructor
/// from transitioning away from the state seeded by the test.
class _NeverAuthRepository implements AuthRepository {
  @override
  Future<bool> hasToken() => Completer<bool>().future;

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
  Future<void> logout() async {}

  @override
  Future<void> forgotPassword(String email) =>
      Future.error(UnimplementedError());

  @override
  Future<void> loadTokenIntoClient() async {}
}

class _TestAuthNotifier extends AuthNotifier {
  _TestAuthNotifier() : super(_NeverAuthRepository());

  void seed(UserModel user) {
    state = AuthState(status: AuthStatus.authenticated, user: user);
  }
}

class _FakeProfileRepository implements ProfileRepository {
  UserModel? updateResult;
  Object? updateError;

  Map<String, dynamic>? lastUpdate;

  @override
  Future<UserModel> updateProfile({
    required String name,
    required String email,
  }) async {
    lastUpdate = {'name': name, 'email': email};
    if (updateError != null) throw updateError!;
    return updateResult!;
  }

  @override
  Future<String> uploadAvatar({
    required Uint8List bytes,
    required String filename,
  }) =>
      Future.error(UnimplementedError());

  @override
  Future<void> changePassword({
    required String currentPassword,
    required String password,
    required String passwordConfirmation,
  }) =>
      Future.error(UnimplementedError());
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

Future<_TestAuthNotifier> _pumpScreen(
  WidgetTester tester,
  _FakeProfileRepository repo,
) async {
  tester.view.physicalSize = const Size(400 * 3, 900 * 3);
  tester.view.devicePixelRatio = 3.0;
  addTearDown(tester.view.reset);

  final auth = _TestAuthNotifier()..seed(_currentUser);
  final container = ProviderContainer(
    overrides: [
      authProvider.overrideWith((ref) => auth),
      profileRepositoryProvider.overrideWithValue(repo),
    ],
  );
  addTearDown(container.dispose);

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: localizedApp(home: const EditProfileScreen()),
    ),
  );
  await tester.pump();
  return auth;
}

Future<void> _tapSave(WidgetTester tester) async {
  final saveButton = find.text('Guardar cambios');
  await tester.ensureVisible(saveButton);
  await tester.pump();
  await tester.tap(saveButton);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('renders the current name and email', (tester) async {
    await _pumpScreen(tester, _FakeProfileRepository());

    expect(find.text('Old Name'), findsOneWidget);
    expect(find.text('old@example.com'), findsOneWidget);
    expect(find.text('Editar perfil'), findsOneWidget);
    expect(find.text('DATOS PERSONALES'), findsOneWidget);
  });

  testWidgets('saving with an empty name shows validationRequired',
      (tester) async {
    final repo = _FakeProfileRepository();
    await _pumpScreen(tester, repo);

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Old Name'),
      '',
    );
    await _tapSave(tester);

    expect(find.text('Obligatorio'), findsOneWidget);
    expect(repo.lastUpdate, isNull);
  });

  testWidgets('saving with an invalid email shows validationInvalidEmail',
      (tester) async {
    final repo = _FakeProfileRepository();
    await _pumpScreen(tester, repo);

    await tester.enterText(
      find.widgetWithText(TextFormField, 'old@example.com'),
      'not-an-email',
    );
    await _tapSave(tester);

    expect(find.text('Correo electrónico inválido'), findsOneWidget);
    expect(repo.lastUpdate, isNull);
  });

  testWidgets('saving valid data calls saveProfile and shows profileEditSaved',
      (tester) async {
    final repo = _FakeProfileRepository()
      ..updateResult = const UserModel(
        id: '1',
        name: 'New Name',
        email: 'new@example.com',
        role: 'professor',
      );
    final auth = await _pumpScreen(tester, repo);

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Old Name'),
      'New Name',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'old@example.com'),
      'new@example.com',
    );
    await _tapSave(tester);

    expect(repo.lastUpdate, {
      'name': 'New Name',
      'email': 'new@example.com',
    });
    expect(find.text('Perfil actualizado.'), findsOneWidget);
    expect(auth.state.user?.email, 'new@example.com');
  });

  testWidgets('an email 422 shows profileEditEmailInUse and keeps the text',
      (tester) async {
    final repo = _FakeProfileRepository()
      ..updateError = ValidationException(
        fieldErrors: {'email': 'El email ya está en uso'},
      );
    await _pumpScreen(tester, repo);

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Old Name'),
      'New Name',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'old@example.com'),
      'dup@example.com',
    );
    await _tapSave(tester);

    expect(find.text('Ese email ya está en uso.'), findsOneWidget);
    expect(find.text('dup@example.com'), findsOneWidget);
    expect(find.text('New Name'), findsOneWidget);
  });

  testWidgets('an email 422 that is not a conflict shows profileEditSaveError',
      (tester) async {
    final repo = _FakeProfileRepository()
      ..updateError = ValidationException(
        fieldErrors: {'email': 'El email no es válido'},
      );
    await _pumpScreen(tester, repo);

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Old Name'),
      'New Name',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'old@example.com'),
      'bad@example.com',
    );
    await _tapSave(tester);

    expect(find.text('No se pudo actualizar el perfil.'), findsOneWidget);
    expect(find.text('Ese email ya está en uso.'), findsNothing);
  });

  testWidgets('sends the email trimmed and lowercased', (tester) async {
    final repo = _FakeProfileRepository()
      ..updateResult = const UserModel(
        id: '1',
        name: 'New Name',
        email: 'new@example.com',
        role: 'professor',
      );
    await _pumpScreen(tester, repo);

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Old Name'),
      'New Name',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'old@example.com'),
      'New@Example.COM',
    );
    await _tapSave(tester);

    expect(repo.lastUpdate, {
      'name': 'New Name',
      'email': 'new@example.com',
    });
  });
}
