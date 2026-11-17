import 'dart:async';
import 'dart:typed_data';

import 'package:efe_mobile/core/api/api_exception.dart';
import 'package:efe_mobile/features/auth/data/auth_repository.dart';
import 'package:efe_mobile/features/auth/domain/user_model.dart';
import 'package:efe_mobile/features/auth/providers/auth_provider.dart';
import 'package:efe_mobile/features/profile/data/profile_repository.dart';
import 'package:efe_mobile/features/profile/providers/profile_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

const _currentUser = UserModel(
  id: '1',
  name: 'Old',
  email: 'old@example.com',
  role: 'professor',
  avatarUrl: 'https://cdn/a.png',
  branchName: 'Sede Centro',
);

// ---------------------------------------------------------------------------
// Fakes
// ---------------------------------------------------------------------------

/// Repository that never resolves: keeps the real [AuthNotifier] constructor
/// from transitioning away from the state the test sets by hand.
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
  Completer<UserModel>? updateGate;

  String? avatarResult;
  Object? avatarError;

  Object? passwordError;

  Map<String, dynamic>? lastUpdate;
  Map<String, dynamic>? lastUpload;
  Map<String, dynamic>? lastPassword;

  @override
  Future<UserModel> updateProfile({
    required String name,
    required String email,
  }) async {
    lastUpdate = {'name': name, 'email': email};
    if (updateGate != null) return updateGate!.future;
    if (updateError != null) throw updateError!;
    return updateResult!;
  }

  @override
  Future<String> uploadAvatar({
    required Uint8List bytes,
    required String filename,
  }) async {
    lastUpload = {'filename': filename, 'length': bytes.length};
    if (avatarError != null) throw avatarError!;
    return avatarResult!;
  }

  @override
  Future<void> changePassword({
    required String currentPassword,
    required String password,
    required String passwordConfirmation,
  }) async {
    lastPassword = {
      'current_password': currentPassword,
      'password': password,
      'password_confirmation': passwordConfirmation,
    };
    if (passwordError != null) throw passwordError!;
  }
}

ProviderContainer _containerFor(
  _TestAuthNotifier auth,
  _FakeProfileRepository repo,
) {
  final container = ProviderContainer(
    overrides: [
      authProvider.overrideWith((ref) => auth),
      profileRepositoryProvider.overrideWithValue(repo),
    ],
  );
  addTearDown(container.dispose);
  return container;
}

void main() {
  group('ProfileEditNotifier.saveProfile', () {
    test('updates the auth user and keeps the avatar and branch', () async {
      final auth = _TestAuthNotifier()..seed(_currentUser);
      final repo = _FakeProfileRepository()
        ..updateResult = const UserModel(
          id: '1',
          name: 'New',
          email: 'new@example.com',
          role: 'admin',
        );
      final container = _containerFor(auth, repo);

      final ok = await container
          .read(profileEditProvider.notifier)
          .saveProfile(name: 'New', email: 'new@example.com');

      expect(ok, isTrue);
      expect(repo.lastUpdate, {'name': 'New', 'email': 'new@example.com'});
      final user = container.read(authProvider).user;
      expect(user?.name, 'New');
      expect(user?.email, 'new@example.com');
      expect(user?.role, 'admin');
      expect(user?.avatarUrl, 'https://cdn/a.png');
      expect(user?.branchName, 'Sede Centro');
      expect(container.read(authProvider).status, AuthStatus.authenticated);
    });

    test('stores fieldErrors on ValidationException and returns false',
        () async {
      final auth = _TestAuthNotifier()..seed(_currentUser);
      final repo = _FakeProfileRepository()
        ..updateError = ValidationException(
          fieldErrors: {'email': 'El email ya está en uso'},
        );
      final container = _containerFor(auth, repo);

      final ok = await container
          .read(profileEditProvider.notifier)
          .saveProfile(name: 'New', email: 'dup@example.com');

      expect(ok, isFalse);
      expect(
        container.read(profileEditProvider).fieldErrors,
        {'email': 'El email ya está en uso'},
      );
      expect(container.read(authProvider).user?.email, 'old@example.com');
    });

    test('returns false on generic errors without changing the user', () async {
      final auth = _TestAuthNotifier()..seed(_currentUser);
      final repo = _FakeProfileRepository()
        ..updateError = ApiException(message: 'boom');
      final container = _containerFor(auth, repo);

      final ok = await container
          .read(profileEditProvider.notifier)
          .saveProfile(name: 'New', email: 'new@example.com');

      expect(ok, isFalse);
      expect(container.read(profileEditProvider).fieldErrors, isEmpty);
      expect(container.read(authProvider).user, _currentUser);
    });

    test('toggles savingProfile while the request is in flight', () async {
      final auth = _TestAuthNotifier()..seed(_currentUser);
      final repo = _FakeProfileRepository()
        ..updateGate = Completer<UserModel>();
      final container = _containerFor(auth, repo);

      final future = container
          .read(profileEditProvider.notifier)
          .saveProfile(name: 'New', email: 'new@example.com');

      expect(container.read(profileEditProvider).savingProfile, isTrue);

      repo.updateGate!.complete(_currentUser);
      await future;

      expect(container.read(profileEditProvider).savingProfile, isFalse);
    });
  });

  group('ProfileEditNotifier.uploadAvatar', () {
    test('applies the new avatarUrl and returns the URL', () async {
      final auth = _TestAuthNotifier()..seed(_currentUser);
      final repo = _FakeProfileRepository()
        ..avatarResult = 'https://cdn/new.png';
      final container = _containerFor(auth, repo);

      final url =
          await container.read(profileEditProvider.notifier).uploadAvatar(
                bytes: Uint8List.fromList([1, 2, 3]),
                filename: 'photo.png',
              );

      expect(url, 'https://cdn/new.png');
      expect(repo.lastUpload, {'filename': 'photo.png', 'length': 3});
      final user = container.read(authProvider).user;
      expect(user?.avatarUrl, 'https://cdn/new.png');
      expect(user?.name, 'Old');
      expect(user?.branchName, 'Sede Centro');
    });

    test('returns null on errors without changing the user', () async {
      final auth = _TestAuthNotifier()..seed(_currentUser);
      final repo = _FakeProfileRepository()
        ..avatarError = ApiException(message: 'boom');
      final container = _containerFor(auth, repo);

      final url =
          await container.read(profileEditProvider.notifier).uploadAvatar(
                bytes: Uint8List.fromList([1]),
                filename: 'photo.png',
              );

      expect(url, isNull);
      expect(container.read(authProvider).user, _currentUser);
    });
  });

  group('ProfileEditNotifier.changePassword', () {
    test('returns true and leaves the user untouched', () async {
      final auth = _TestAuthNotifier()..seed(_currentUser);
      final repo = _FakeProfileRepository();
      final container = _containerFor(auth, repo);

      final ok =
          await container.read(profileEditProvider.notifier).changePassword(
                currentPassword: 'old-secret',
                newPassword: 'new-secret',
                confirmation: 'new-secret',
              );

      expect(ok, isTrue);
      expect(repo.lastPassword, {
        'current_password': 'old-secret',
        'password': 'new-secret',
        'password_confirmation': 'new-secret',
      });
      expect(container.read(authProvider).user, _currentUser);
    });

    test('stores fieldErrors on ValidationException and returns false',
        () async {
      final auth = _TestAuthNotifier()..seed(_currentUser);
      final repo = _FakeProfileRepository()
        ..passwordError = ValidationException(
          fieldErrors: {'current_password': 'La contraseña actual no coincide'},
        );
      final container = _containerFor(auth, repo);

      final ok =
          await container.read(profileEditProvider.notifier).changePassword(
                currentPassword: 'wrong',
                newPassword: 'new-secret',
                confirmation: 'new-secret',
              );

      expect(ok, isFalse);
      expect(
        container.read(profileEditProvider).fieldErrors,
        {'current_password': 'La contraseña actual no coincide'},
      );
    });

    test('returns false on generic errors without changing the user', () async {
      final auth = _TestAuthNotifier()..seed(_currentUser);
      final repo = _FakeProfileRepository()
        ..passwordError = ApiException(message: 'boom');
      final container = _containerFor(auth, repo);

      final ok =
          await container.read(profileEditProvider.notifier).changePassword(
                currentPassword: 'old-secret',
                newPassword: 'new-secret',
                confirmation: 'new-secret',
              );

      expect(ok, isFalse);
      expect(container.read(profileEditProvider).fieldErrors, isEmpty);
      expect(container.read(authProvider).user, _currentUser);
    });

    test('toggles savingPassword while the request is in flight', () async {
      final auth = _TestAuthNotifier()..seed(_currentUser);
      final repo = _FakeProfileRepository();
      final container = _containerFor(auth, repo);

      final future =
          container.read(profileEditProvider.notifier).changePassword(
                currentPassword: 'old-secret',
                newPassword: 'new-secret',
                confirmation: 'new-secret',
              );

      expect(container.read(profileEditProvider).savingPassword, isTrue);
      await future;
      expect(container.read(profileEditProvider).savingPassword, isFalse);
    });
  });

  group('ProfileEditNotifier.clearFieldErrors', () {
    test('resets the field errors map', () async {
      final auth = _TestAuthNotifier()..seed(_currentUser);
      final repo = _FakeProfileRepository()
        ..updateError = ValidationException(
          fieldErrors: {'email': 'El email ya está en uso'},
        );
      final container = _containerFor(auth, repo);

      await container
          .read(profileEditProvider.notifier)
          .saveProfile(name: 'New', email: 'dup@example.com');
      expect(container.read(profileEditProvider).fieldErrors, isNotEmpty);

      container.read(profileEditProvider.notifier).clearFieldErrors();

      expect(container.read(profileEditProvider).fieldErrors, isEmpty);
    });
  });
}
