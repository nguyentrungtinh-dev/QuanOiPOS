import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quan_oi/features/auth/domain/entities/login_result.dart';
import 'package:quan_oi/features/auth/domain/repositories/auth_repository.dart';
import 'package:quan_oi/features/auth/domain/usecases/confirm_forgot_password_use_case.dart';
import 'package:quan_oi/features/auth/domain/usecases/forgot_password_use_case.dart';
import 'package:quan_oi/features/auth/presentation/controllers/forgot_password_state.dart';
import 'package:quan_oi/features/auth/presentation/providers/auth_providers.dart';

void main() {
  test('forgot password success moves to reset step and keeps email', () async {
    final repository = _FakeForgotPasswordRepository();
    final container = _buildContainer(repository);
    addTearDown(container.dispose);

    await container
        .read(forgotPasswordNotifierProvider.notifier)
        .submitEmail(' user@quanoi.test ');

    final state = container.read(forgotPasswordNotifierProvider);
    expect(state.step, ForgotPasswordStep.reset);
    expect(state.status, ForgotPasswordStatus.awaitingReset);
    expect(state.email, 'user@quanoi.test');
  });

  test(
    'forgot password failure stays on email step with error message',
    () async {
      final repository = _FakeForgotPasswordRepository(
        forgotError: Exception('Email not found'),
      );
      final container = _buildContainer(repository);
      addTearDown(container.dispose);

      await container
          .read(forgotPasswordNotifierProvider.notifier)
          .submitEmail('user@quanoi.test');

      final state = container.read(forgotPasswordNotifierProvider);
      expect(state.step, ForgotPasswordStep.email);
      expect(state.status, ForgotPasswordStatus.failure);
      expect(state.errorMessage, 'Email not found');
    },
  );

  test('confirm reset success moves to success status', () async {
    final repository = _FakeForgotPasswordRepository();
    final container = _buildContainer(repository);
    addTearDown(container.dispose);

    await container
        .read(forgotPasswordNotifierProvider.notifier)
        .submitEmail('user@quanoi.test');
    await container
        .read(forgotPasswordNotifierProvider.notifier)
        .confirmReset(otpCode: '123456', newPassword: 'password');

    final state = container.read(forgotPasswordNotifierProvider);
    expect(state.step, ForgotPasswordStep.reset);
    expect(state.status, ForgotPasswordStatus.success);
  });

  test('confirm reset failure keeps reset step with error message', () async {
    final repository = _FakeForgotPasswordRepository(
      confirmError: Exception('Invalid OTP'),
    );
    final container = _buildContainer(repository);
    addTearDown(container.dispose);

    await container
        .read(forgotPasswordNotifierProvider.notifier)
        .submitEmail('user@quanoi.test');
    await container
        .read(forgotPasswordNotifierProvider.notifier)
        .confirmReset(otpCode: '000000', newPassword: 'password');

    final state = container.read(forgotPasswordNotifierProvider);
    expect(state.step, ForgotPasswordStep.reset);
    expect(state.status, ForgotPasswordStatus.failure);
    expect(state.errorMessage, 'Invalid OTP');
  });
}

ProviderContainer _buildContainer(_FakeForgotPasswordRepository repository) {
  return ProviderContainer(
    overrides: [
      forgotPasswordUseCaseProvider.overrideWithValue(
        ForgotPasswordUseCase(repository),
      ),
      confirmForgotPasswordUseCaseProvider.overrideWithValue(
        ConfirmForgotPasswordUseCase(repository),
      ),
    ],
  );
}

class _FakeForgotPasswordRepository implements AuthRepository {
  final Object? forgotError;
  final Object? confirmError;

  const _FakeForgotPasswordRepository({this.forgotError, this.confirmError});

  @override
  Future<void> forgotPassword({required String email}) async {
    if (forgotError != null) {
      throw forgotError!;
    }
  }

  @override
  Future<void> confirmForgotPassword({
    required String email,
    required String otpCode,
    required String newPassword,
  }) async {
    if (confirmError != null) {
      throw confirmError!;
    }
  }

  @override
  Future<void> confirmRegistration({
    required String email,
    required String otpCode,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<LoginResult> login({required String email, required String password}) {
    throw UnimplementedError();
  }

  @override
  Future<void> logout() {
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
  Future<LoginResult?> restoreSession() {
    throw UnimplementedError();
  }
}
