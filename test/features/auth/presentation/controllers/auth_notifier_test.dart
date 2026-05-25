import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quan_oi/features/auth/domain/entities/account_type.dart';
import 'package:quan_oi/features/auth/domain/entities/login_result.dart';
import 'package:quan_oi/features/auth/domain/repositories/auth_repository.dart';
import 'package:quan_oi/features/auth/domain/usecases/logout_use_case.dart';
import 'package:quan_oi/features/auth/domain/usecases/restore_session_use_case.dart';
import 'package:quan_oi/features/auth/presentation/controllers/auth_state.dart';
import 'package:quan_oi/features/auth/presentation/providers/auth_providers.dart';
import 'package:quan_oi/core/session/session_invalidator.dart';

void main() {
  test('auth notifier restores session when provider is created', () async {
    final sessionInvalidator = SessionInvalidator();
    addTearDown(sessionInvalidator.dispose);

    final container = ProviderContainer(
      overrides: [
        sessionInvalidatorProvider.overrideWithValue(sessionInvalidator),
        restoreSessionUseCaseProvider.overrideWithValue(
          RestoreSessionUseCase(
            _FakeAuthRepository(
              restoreResult: Future.value(
                const LoginResult(
                  accountId: 1,
                  email: 'admin@quanoi.test',
                  fullName: 'Admin',
                  phone: '',
                  accountType: AccountType.systemAdmin,
                  accessToken: 'access-token',
                  refreshToken: '',
                ),
              ),
            ),
          ),
        ),
      ],
    );
    addTearDown(container.dispose);

    expect(
      container.read(authNotifierProvider).status,
      AuthStatus.bootstrapping,
    );

    await Future<void>.delayed(Duration.zero);
    await Future<void>.delayed(Duration.zero);

    final state = container.read(authNotifierProvider);
    expect(state.status, AuthStatus.authenticated);
    expect(state.accountType, AccountType.systemAdmin);
    expect(state.sessionRestored, isTrue);
  });

  test('auth notifier leaves bootstrap when no session exists', () async {
    final sessionInvalidator = SessionInvalidator();
    addTearDown(sessionInvalidator.dispose);

    final container = ProviderContainer(
      overrides: [
        sessionInvalidatorProvider.overrideWithValue(sessionInvalidator),
        restoreSessionUseCaseProvider.overrideWithValue(
          RestoreSessionUseCase(
            _FakeAuthRepository(restoreResult: Future.value()),
          ),
        ),
      ],
    );
    addTearDown(container.dispose);

    expect(
      container.read(authNotifierProvider).status,
      AuthStatus.bootstrapping,
    );

    await Future<void>.delayed(Duration.zero);
    await Future<void>.delayed(Duration.zero);

    expect(
      container.read(authNotifierProvider).status,
      AuthStatus.unauthenticated,
    );
  });

  test('auth notifier logs out when session is invalidated', () async {
    final sessionInvalidator = SessionInvalidator();
    addTearDown(sessionInvalidator.dispose);
    final repository = _FakeAuthRepository(
      restoreResult: Future.value(
        const LoginResult(
          accountId: 1,
          email: 'admin@quanoi.test',
          fullName: 'Admin',
          phone: '',
          accountType: AccountType.systemAdmin,
          accessToken: 'access-token',
          refreshToken: '',
        ),
      ),
    );

    final container = ProviderContainer(
      overrides: [
        sessionInvalidatorProvider.overrideWithValue(sessionInvalidator),
        restoreSessionUseCaseProvider.overrideWithValue(
          RestoreSessionUseCase(repository),
        ),
        logoutUseCaseProvider.overrideWithValue(LogoutUseCase(repository)),
      ],
    );
    addTearDown(container.dispose);

    container.read(authNotifierProvider);
    await Future<void>.delayed(Duration.zero);
    await Future<void>.delayed(Duration.zero);

    expect(
      container.read(authNotifierProvider).status,
      AuthStatus.authenticated,
    );

    sessionInvalidator.invalidate();
    await Future<void>.delayed(Duration.zero);
    await Future<void>.delayed(Duration.zero);

    expect(
      container.read(authNotifierProvider).status,
      AuthStatus.unauthenticated,
    );
    expect(repository.logoutCount, 1);
  });
}

class _FakeAuthRepository implements AuthRepository {
  final Future<LoginResult?> restoreResult;
  int logoutCount = 0;

  _FakeAuthRepository({required this.restoreResult});

  @override
  Future<LoginResult> login({required String email, required String password}) {
    throw UnimplementedError();
  }

  @override
  Future<void> register({
    required String email,
    required String password,
    required String fullName,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<void> confirmRegistration({
    required String email,
    required String otpCode,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<void> forgotPassword({required String email}) {
    throw UnimplementedError();
  }

  @override
  Future<void> confirmForgotPassword({
    required String email,
    required String otpCode,
    required String newPassword,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<void> logout() async {
    logoutCount += 1;
  }

  @override
  Future<LoginResult?> restoreSession() {
    return restoreResult;
  }
}
