import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:efe_mobile/core/widgets/avatar.dart';
import 'package:efe_mobile/features/auth/data/auth_repository.dart';
import 'package:efe_mobile/features/auth/domain/user_model.dart';
import 'package:efe_mobile/features/auth/providers/auth_provider.dart';
import 'package:efe_mobile/features/profile/data/profile_repository.dart';
import 'package:efe_mobile/features/profile/domain/avatar_upload_file.dart';
import 'package:efe_mobile/features/profile/providers/profile_provider.dart';
import 'package:efe_mobile/features/profile/screens/edit_profile_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
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

const _previewKey = ValueKey('profile-avatar-preview');
const _avatarEditorKey = ValueKey('profile-avatar-editor');
const _changePhotoLabel = 'Cambiar foto';
const _invalidMessage = 'Elegí una imagen JPG, PNG o GIF de hasta 2 MB.';
const _uploadedMessage = 'Foto actualizada.';
const _uploadErrorMessage = 'No se pudo subir la foto.';

/// A real 1x1 transparent PNG.
final Uint8List _pngBytes = base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQDwAEhQGAhKmMIQAAAABJRU5ErkJggg==',
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
  int uploadCalls = 0;
  Uint8List? lastBytes;
  String? lastFilename;
  Object? uploadError;
  String uploadResult = 'https://cdn/new.png';

  /// When set, [uploadAvatar] waits for it instead of resolving immediately.
  Completer<String>? uploadCompleter;

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
  }) async {
    uploadCalls++;
    lastBytes = bytes;
    lastFilename = filename;
    if (uploadCompleter != null) return uploadCompleter!.future;
    if (uploadError != null) throw uploadError!;
    return uploadResult;
  }

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
  _FakeProfileRepository repo, {
  Future<AvatarUploadFile?> Function()? pickAvatar,
}) async {
  tester.view.physicalSize = const Size(400 * 3, 1000 * 3);
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
      child: localizedApp(
        home: EditProfileScreen(pickAvatar: pickAvatar),
      ),
    ),
  );
  await tester.pump();
  return auth;
}

Future<void> _tapAvatar(WidgetTester tester) async {
  await tester.tap(find.byKey(_avatarEditorKey));
  await tester.pump();
}

Finder _snackBarWith(String message) {
  return find.descendant(
    of: find.byType(SnackBar),
    matching: find.text(message),
  );
}

void main() {
  testWidgets('picking a valid image uploads it and shows the success message',
      (tester) async {
    final repo = _FakeProfileRepository();
    var picks = 0;
    final auth = await _pumpScreen(
      tester,
      repo,
      pickAvatar: () async {
        picks++;
        return AvatarUploadFile(bytes: _pngBytes, name: 'avatar.png');
      },
    );

    await _tapAvatar(tester);
    await tester.pumpAndSettle();

    expect(picks, 1);
    expect(repo.uploadCalls, 1);
    expect(repo.lastFilename, 'avatar.png');
    expect(repo.lastBytes, _pngBytes);
    expect(_snackBarWith(_uploadedMessage), findsOneWidget);
    expect(find.byKey(_previewKey), findsNothing);
    expect(auth.state.user?.avatarUrl, 'https://cdn/new.png');
  });

  testWidgets('the avatar exposes an activatable change-photo semantics action',
      (tester) async {
    final semantics = tester.ensureSemantics();
    try {
      final repo = _FakeProfileRepository();
      final auth = await _pumpScreen(
        tester,
        repo,
        pickAvatar: () async =>
            AvatarUploadFile(bytes: _pngBytes, name: 'avatar.png'),
      );

      final node =
          tester.getSemantics(find.bySemanticsLabel(_changePhotoLabel));
      final data = node.getSemanticsData();
      expect(data.label, _changePhotoLabel);
      expect(data.hasAction(SemanticsAction.tap), isTrue);

      // Activate through the semantics node, the way assistive tech does,
      // rather than through a pointer tap.
      node.owner!.performAction(node.id, SemanticsAction.tap);
      await tester.pumpAndSettle();

      expect(repo.uploadCalls, 1);
      expect(auth.state.user?.avatarUrl, 'https://cdn/new.png');
    } finally {
      semantics.dispose();
    }
  });

  testWidgets(
      'an unsupported extension shows the invalid message and '
      'does not upload', (tester) async {
    final repo = _FakeProfileRepository();
    await _pumpScreen(
      tester,
      repo,
      pickAvatar: () async =>
          AvatarUploadFile(bytes: _pngBytes, name: 'avatar.webp'),
    );

    await _tapAvatar(tester);

    expect(_snackBarWith(_invalidMessage), findsOneWidget);
    expect(repo.uploadCalls, 0);
    expect(find.byKey(_previewKey), findsNothing);
  });

  testWidgets(
      'a file one byte over 2 MB shows the invalid message and '
      'does not upload', (tester) async {
    final repo = _FakeProfileRepository();
    await _pumpScreen(
      tester,
      repo,
      pickAvatar: () async => AvatarUploadFile(
        bytes: Uint8List(2 * 1024 * 1024 + 1),
        name: 'avatar.png',
      ),
    );

    await _tapAvatar(tester);

    expect(_snackBarWith(_invalidMessage), findsOneWidget);
    expect(repo.uploadCalls, 0);
    expect(find.byKey(_previewKey), findsNothing);
  });

  testWidgets('a file of exactly 2 MB is accepted', (tester) async {
    final repo = _FakeProfileRepository();
    const twoMegabytes = 2 * 1024 * 1024;
    final padded = Uint8List(twoMegabytes)
      ..setRange(0, _pngBytes.length, _pngBytes);

    await _pumpScreen(
      tester,
      repo,
      pickAvatar: () async =>
          AvatarUploadFile(bytes: padded, name: 'avatar.PNG'),
    );

    await _tapAvatar(tester);
    await tester.pumpAndSettle();

    expect(repo.uploadCalls, 1);
    expect(repo.lastFilename, 'avatar.PNG');
    expect(_snackBarWith(_uploadedMessage), findsOneWidget);
  });

  testWidgets(
      'a repository error shows the error message, stops the spinner '
      'and keeps the previous avatar', (tester) async {
    final repo = _FakeProfileRepository();
    final completer = Completer<String>();
    repo.uploadCompleter = completer;
    final auth = await _pumpScreen(
      tester,
      repo,
      pickAvatar: () async =>
          AvatarUploadFile(bytes: _pngBytes, name: 'avatar.png'),
    );

    await _tapAvatar(tester);
    await tester.pump();

    expect(find.byKey(_previewKey), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    completer.completeError(Exception('upload failed'));
    await tester.pump();
    await tester.pumpAndSettle();

    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(_snackBarWith(_uploadErrorMessage), findsOneWidget);
    expect(find.byKey(_previewKey), findsNothing);
    expect(find.byType(AppAvatar), findsOneWidget);
    expect(
      tester.widget<AppAvatar>(find.byType(AppAvatar)).imageUrl,
      'https://cdn/a.png',
    );
    expect(auth.state.user?.avatarUrl, 'https://cdn/a.png');
  });

  testWidgets('cancelling the picker does nothing', (tester) async {
    final repo = _FakeProfileRepository();
    await _pumpScreen(tester, repo, pickAvatar: () async => null);

    await _tapAvatar(tester);
    await tester.pumpAndSettle();

    expect(repo.uploadCalls, 0);
    expect(find.byType(SnackBar), findsNothing);
    expect(find.byKey(_previewKey), findsNothing);
  });
}
