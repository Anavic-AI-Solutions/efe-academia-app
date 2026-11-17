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

const _currentKey = ValueKey('profile-current-password');
const _newKey = ValueKey('profile-new-password');
const _confirmKey = ValueKey('profile-confirm-password');
const _currentToggleKey = ValueKey('profile-current-password-toggle');
const _saveLabel = 'Cambiar contraseña';

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
  int changeCalls = 0;
  String? lastCurrent;
  String? lastNew;
  String? lastConfirmation;
  Object? changeError;

  @override
  Future<UserModel> updateProfile({
    required String name,
    required String email,
  }) =>
      Future.error(UnimplementedError());

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
  }) async {
    changeCalls++;
    lastCurrent = currentPassword;
    lastNew = password;
    lastConfirmation = passwordConfirmation;
    if (changeError != null) throw changeError!;
  }
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

Future<_TestAuthNotifier> _pumpScreen(
  WidgetTester tester,
  _FakeProfileRepository repo,
) async {
  // Tall enough that the whole list is laid out and every field is hittable.
  tester.view.physicalSize = const Size(400 * 3, 1400 * 3);
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

Future<void> _fillPasswords(
  WidgetTester tester, {
  required String current,
  required String newPassword,
  required String confirmation,
}) async {
  await tester.enterText(find.byKey(_currentKey), current);
  await tester.enterText(find.byKey(_newKey), newPassword);
  await tester.enterText(find.byKey(_confirmKey), confirmation);
}

Future<void> _tapChangePassword(WidgetTester tester) async {
  final button = find.text(_saveLabel);
  await tester.ensureVisible(button);
  await tester.pump();
  await tester.tap(button);
  await tester.pumpAndSettle();
}

String _fieldText(WidgetTester tester, Key key) {
  return tester.widget<TextFormField>(find.byKey(key)).controller!.text;
}

bool _isObscured(WidgetTester tester, Key key) {
  final editable = find.descendant(
    of: find.byKey(key),
    matching: find.byType(EditableText),
  );
  return tester.widget<EditableText>(editable).obscureText;
}

Finder _snackBarWith(String message) {
  return find.descendant(
    of: find.byType(SnackBar),
    matching: find.text(message),
  );
}

void main() {
  testWidgets('a short new password shows validationPasswordLength',
      (tester) async {
    final repo = _FakeProfileRepository();
    await _pumpScreen(tester, repo);

    await _fillPasswords(
      tester,
      current: 'current-pass',
      newPassword: 'short',
      confirmation: 'short',
    );
    await _tapChangePassword(tester);

    expect(
      find.text('La contraseña debe tener al menos 8 caracteres'),
      findsOneWidget,
    );
    expect(repo.changeCalls, 0);
  });

  testWidgets('a mismatched confirmation shows validationPasswordsDoNotMatch',
      (tester) async {
    final repo = _FakeProfileRepository();
    await _pumpScreen(tester, repo);

    await _fillPasswords(
      tester,
      current: 'current-pass',
      newPassword: 'new-password',
      confirmation: 'other-password',
    );
    await _tapChangePassword(tester);

    expect(find.text('Las contraseñas no coinciden'), findsOneWidget);
    expect(repo.changeCalls, 0);
  });

  testWidgets(
      'a valid change calls changePassword, clears the fields and shows '
      'profileEditPasswordSaved', (tester) async {
    final repo = _FakeProfileRepository();
    await _pumpScreen(tester, repo);

    await _fillPasswords(
      tester,
      current: 'current-pass',
      newPassword: 'new-password',
      confirmation: 'new-password',
    );
    await _tapChangePassword(tester);

    expect(repo.changeCalls, 1);
    expect(repo.lastCurrent, 'current-pass');
    expect(repo.lastNew, 'new-password');
    expect(repo.lastConfirmation, 'new-password');
    expect(_fieldText(tester, _currentKey), isEmpty);
    expect(_fieldText(tester, _newKey), isEmpty);
    expect(_fieldText(tester, _confirmKey), isEmpty);
    expect(_snackBarWith('Contraseña actualizada.'), findsOneWidget);
  });

  testWidgets(
      'a current_password 422 shows profileEditCurrentPasswordIncorrect',
      (tester) async {
    final repo = _FakeProfileRepository()
      ..changeError = ValidationException(
        fieldErrors: {
          'current_password': 'La contraseña actual no es correcta'
        },
      );
    await _pumpScreen(tester, repo);

    await _fillPasswords(
      tester,
      current: 'wrong-pass',
      newPassword: 'new-password',
      confirmation: 'new-password',
    );
    await _tapChangePassword(tester);

    expect(
      find.text('La contraseña actual no es correcta.'),
      findsOneWidget,
    );
    expect(_fieldText(tester, _currentKey), 'wrong-pass');
  });

  testWidgets('a password 422 shows profileEditPasswordInvalid',
      (tester) async {
    final repo = _FakeProfileRepository()
      ..changeError = ValidationException(
        fieldErrors: {'password': 'La contraseña no es válida'},
      );
    await _pumpScreen(tester, repo);

    await _fillPasswords(
      tester,
      current: 'current-pass',
      newPassword: 'new-password',
      confirmation: 'new-password',
    );
    await _tapChangePassword(tester);

    expect(find.text('La contraseña no es válida.'), findsOneWidget);
  });

  testWidgets('a generic failure shows profileEditPasswordError',
      (tester) async {
    final repo = _FakeProfileRepository()..changeError = Exception('boom');
    await _pumpScreen(tester, repo);

    await _fillPasswords(
      tester,
      current: 'current-pass',
      newPassword: 'new-password',
      confirmation: 'new-password',
    );
    await _tapChangePassword(tester);

    expect(find.text('No se pudo cambiar la contraseña.'), findsOneWidget);
    expect(_fieldText(tester, _currentKey), 'current-pass');
  });

  testWidgets('the current password can be revealed with its eye toggle',
      (tester) async {
    final repo = _FakeProfileRepository();
    await _pumpScreen(tester, repo);

    expect(_isObscured(tester, _currentKey), isTrue);

    await tester.tap(find.byKey(_currentToggleKey));
    await tester.pump();

    expect(_isObscured(tester, _currentKey), isFalse);
  });
}
