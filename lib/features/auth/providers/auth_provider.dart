import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_provider.dart';
import '../data/auth_api.dart';
import '../data/auth_repository.dart';
import '../domain/user_model.dart';

// ---------------------------------------------------------------------------
// Providers
// ---------------------------------------------------------------------------

final authApiProvider = Provider<AuthApi>((ref) {
  return AuthApi(ref.watch(apiClientProvider));
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(
    ref.watch(authApiProvider),
    ref.watch(secureStorageProvider),
    ref.watch(apiClientProvider),
  );
});

// ---------------------------------------------------------------------------
// State
// ---------------------------------------------------------------------------

enum AuthStatus { initial, loading, authenticated, unauthenticated, error }

class AuthState {
  final AuthStatus status;
  final UserModel? user;
  final String? error;

  const AuthState({
    this.status = AuthStatus.initial,
    this.user,
    this.error,
  });

  AuthState copyWith({
    AuthStatus? status,
    UserModel? user,
    String? error,
    bool clearUser = false,
  }) {
    return AuthState(
      status: status ?? this.status,
      user: clearUser ? null : (user ?? this.user),
      error: error,
    );
  }
}

// ---------------------------------------------------------------------------
// Notifier
// ---------------------------------------------------------------------------

class AuthNotifier extends StateNotifier<AuthState> {
  final AuthRepository _repository;

  AuthNotifier(this._repository) : super(const AuthState()) {
    _init();
  }

  Future<void> _init() async {
    try {
      final hasToken = await _repository.hasToken();
      debugPrint('[Auth] _init: hasToken=$hasToken');
      if (!hasToken) {
        state = state.copyWith(status: AuthStatus.unauthenticated);
        return;
      }
      await _repository.loadTokenIntoClient();
      final user = await _repository.getCurrentUser();
      debugPrint('[Auth] _init: user=${user.email} name=${user.name}');
      state = state.copyWith(
        status: AuthStatus.authenticated,
        user: user,
      );
    } catch (e) {
      debugPrint('[Auth] _init ERROR: $e');
      state = state.copyWith(status: AuthStatus.unauthenticated);
    }
  }

  Future<void> login(String email, String password) async {
    debugPrint('[Auth] login() email=$email');
    state = state.copyWith(status: AuthStatus.loading, error: null);
    try {
      final user = await _repository.login(email: email, password: password);
      debugPrint('[Auth] login SUCCESS user=${user.email} role=${user.role}');
      state = state.copyWith(
        status: AuthStatus.authenticated,
        user: user,
      );
    } catch (e) {
      debugPrint('[Auth] login ERROR: $e');
      state = state.copyWith(
        status: AuthStatus.error,
        error: e.toString(),
      );
    }
  }

  Future<void> register({
    required String name,
    required String email,
    required String password,
    required String passwordConfirmation,
  }) async {
    debugPrint('[Auth] register() email=$email');
    state = state.copyWith(status: AuthStatus.loading, error: null);
    try {
      final user = await _repository.register(
        name: name,
        email: email,
        password: password,
        passwordConfirmation: passwordConfirmation,
      );
      debugPrint('[Auth] register SUCCESS user=${user.email}');
      state = state.copyWith(
        status: AuthStatus.authenticated,
        user: user,
      );
    } catch (e) {
      debugPrint('[Auth] register ERROR: $e');
      state = state.copyWith(
        status: AuthStatus.error,
        error: e.toString(),
      );
    }
  }

  Future<void> logout() async {
    debugPrint('[Auth] logout()');
    await _repository.logout();
    state = const AuthState(status: AuthStatus.unauthenticated);
  }

  Future<void> forgotPassword(String email) async {
    debugPrint('[Auth] forgotPassword() email=$email');
    state = state.copyWith(status: AuthStatus.loading, error: null);
    try {
      await _repository.forgotPassword(email);
      debugPrint('[Auth] forgotPassword SUCCESS');
      state = state.copyWith(status: AuthStatus.unauthenticated);
    } catch (e) {
      debugPrint('[Auth] forgotPassword ERROR: $e');
      state = state.copyWith(
        status: AuthStatus.error,
        error: e.toString(),
      );
    }
  }

  void clearError() {
    state = state.copyWith(error: null, status: AuthStatus.unauthenticated);
  }
}

final authProvider =
    StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(ref.watch(authRepositoryProvider));
});
