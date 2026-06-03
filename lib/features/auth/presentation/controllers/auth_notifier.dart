import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/account_type.dart';
import '../../domain/entities/current_user_profile.dart';
import '../providers/auth_providers.dart';
import 'auth_state.dart';

class AuthNotifier extends Notifier<AuthState> {
  static const _sessionRestoreTimeout = Duration(seconds: 8);

  bool _bootstrapStarted = false;
  bool _sessionInvalidationStarted = false;

  @override
  AuthState build() {
    final sessionInvalidator = ref.read(sessionInvalidatorProvider);
    final subscription = sessionInvalidator.stream.listen((_) {
      unawaited(_handleSessionInvalidated());
    });
    ref.onDispose(subscription.cancel);

    Future.microtask(initializeSession);
    return const AuthState.bootstrapping();
  }

  Future<void> initializeSession() async {
    if (_bootstrapStarted || state.status != AuthStatus.bootstrapping) {
      return;
    }

    _bootstrapStarted = true;

    try {
      final restoreUseCase = ref.read(restoreSessionUseCaseProvider);
      final result = await restoreUseCase().timeout(_sessionRestoreTimeout);

      if (result != null) {
        state = AuthState(
          status: AuthStatus.authenticated,
          accountType: result.accountType,
          fullName: result.fullName,
          email: result.email,
          phone: result.phone,
          sessionRestored: true,
        );
        unawaited(ref.read(authRealtimeNotificationServiceProvider).start());
      } else {
        state = const AuthState.unauthenticated();
      }
    } on TimeoutException {
      state = const AuthState.unauthenticated();
    } catch (error) {
      state = const AuthState.unauthenticated();
    }
  }

  Future<void> login({required String email, required String password}) async {
    state = state.copyWith(status: AuthStatus.authenticating, clearError: true);

    try {
      final loginUseCase = ref.read(loginUseCaseProvider);
      final result = await loginUseCase(email: email, password: password);

      state = AuthState(
        status: AuthStatus.authenticated,
        accountType: result.accountType,
        fullName: result.fullName,
        email: result.email,
        phone: result.phone,
        sessionRestored: false,
      );
      unawaited(ref.read(authRealtimeNotificationServiceProvider).start());
    } catch (error) {
      state = state.copyWith(
        status: AuthStatus.failure,
        accountType: null,
        errorMessage: error.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  Future<void> logout() async {
    final logoutUseCase = ref.read(logoutUseCaseProvider);
    await logoutUseCase();
    await ref.read(authRealtimeNotificationServiceProvider).stop();
    state = const AuthState.unauthenticated();
  }

  Future<void> _handleSessionInvalidated() async {
    if (_sessionInvalidationStarted ||
        state.status == AuthStatus.unauthenticated) {
      return;
    }

    _sessionInvalidationStarted = true;

    try {
      final logoutUseCase = ref.read(logoutUseCaseProvider);
      await logoutUseCase();
      await ref.read(authRealtimeNotificationServiceProvider).stop();
    } finally {
      _sessionInvalidationStarted = false;
      state = const AuthState.unauthenticated();
    }
  }

  void clearError() {
    if (state.errorMessage != null) {
      state = state.copyWith(clearError: true);
      if (state.status == AuthStatus.failure) {
        state = state.copyWith(status: AuthStatus.unauthenticated);
      }
    }
  }

  void syncCurrentUserProfile(CurrentUserProfile profile) {
    if (!state.isAuthenticated) {
      return;
    }

    state = state.copyWith(
      accountType: profile.accountType,
      fullName: profile.fullName,
      email: profile.email,
      phone: profile.phone,
      clearError: true,
    );
  }

  bool get isSystemAdmin => state.accountType == AccountType.systemAdmin;
}
