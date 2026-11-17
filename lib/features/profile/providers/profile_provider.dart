import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_exception.dart';
import '../../../core/api/api_provider.dart';
import '../../auth/providers/auth_provider.dart';
import '../data/profile_api.dart';
import '../data/profile_repository.dart';

// ---------------------------------------------------------------------------
// Providers
// ---------------------------------------------------------------------------

final profileApiProvider = Provider<ProfileApi>((ref) {
  return ProfileApi(ref.watch(apiClientProvider));
});

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  return ProfileRepository(ref.watch(profileApiProvider));
});

// ---------------------------------------------------------------------------
// Edit State
// ---------------------------------------------------------------------------

class ProfileEditState {
  final bool savingProfile;
  final bool uploadingAvatar;
  final bool savingPassword;
  final Map<String, String> fieldErrors;

  const ProfileEditState({
    this.savingProfile = false,
    this.uploadingAvatar = false,
    this.savingPassword = false,
    this.fieldErrors = const {},
  });

  ProfileEditState copyWith({
    bool? savingProfile,
    bool? uploadingAvatar,
    bool? savingPassword,
    Map<String, String>? fieldErrors,
  }) {
    return ProfileEditState(
      savingProfile: savingProfile ?? this.savingProfile,
      uploadingAvatar: uploadingAvatar ?? this.uploadingAvatar,
      savingPassword: savingPassword ?? this.savingPassword,
      fieldErrors: fieldErrors ?? this.fieldErrors,
    );
  }
}

// ---------------------------------------------------------------------------
// Edit Notifier
// ---------------------------------------------------------------------------

class ProfileEditNotifier extends StateNotifier<ProfileEditState> {
  final Ref _ref;
  final ProfileRepository _repository;

  ProfileEditNotifier(this._ref, this._repository)
      : super(const ProfileEditState());

  Future<bool> saveProfile({
    required String name,
    required String email,
  }) async {
    state = state.copyWith(savingProfile: true, fieldErrors: const {});
    try {
      final updated = await _repository.updateProfile(name: name, email: email);
      if (!mounted) return false;
      final current = _ref.read(authProvider).user;
      final merged = updated.copyWith(
        avatarUrl: updated.avatarUrl ?? current?.avatarUrl,
        branchName: updated.branchName ?? current?.branchName,
      );
      _ref.read(authProvider.notifier).applyUser(merged);
      return true;
    } on ValidationException catch (e) {
      if (!mounted) return false;
      state = state.copyWith(fieldErrors: e.fieldErrors);
      return false;
    } catch (_) {
      return false;
    } finally {
      if (mounted) {
        state = state.copyWith(savingProfile: false);
      }
    }
  }

  Future<String?> uploadAvatar({
    required Uint8List bytes,
    required String filename,
  }) async {
    state = state.copyWith(uploadingAvatar: true, fieldErrors: const {});
    try {
      final url = await _repository.uploadAvatar(
        bytes: bytes,
        filename: filename,
      );
      if (!mounted) return null;
      final current = _ref.read(authProvider).user;
      if (current != null) {
        _ref
            .read(authProvider.notifier)
            .applyUser(current.copyWith(avatarUrl: url));
      }
      return url;
    } on ValidationException catch (e) {
      if (!mounted) return null;
      state = state.copyWith(fieldErrors: e.fieldErrors);
      return null;
    } catch (_) {
      return null;
    } finally {
      if (mounted) {
        state = state.copyWith(uploadingAvatar: false);
      }
    }
  }

  Future<bool> changePassword({
    required String currentPassword,
    required String newPassword,
    required String confirmation,
  }) async {
    state = state.copyWith(savingPassword: true, fieldErrors: const {});
    try {
      await _repository.changePassword(
        currentPassword: currentPassword,
        password: newPassword,
        passwordConfirmation: confirmation,
      );
      if (!mounted) return false;
      return true;
    } on ValidationException catch (e) {
      if (!mounted) return false;
      state = state.copyWith(fieldErrors: e.fieldErrors);
      return false;
    } catch (_) {
      return false;
    } finally {
      if (mounted) {
        state = state.copyWith(savingPassword: false);
      }
    }
  }

  void clearFieldErrors() {
    state = state.copyWith(fieldErrors: const {});
  }
}

final profileEditProvider =
    StateNotifierProvider.autoDispose<ProfileEditNotifier, ProfileEditState>(
  (ref) => ProfileEditNotifier(ref, ref.watch(profileRepositoryProvider)),
);
