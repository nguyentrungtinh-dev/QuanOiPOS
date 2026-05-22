import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quan_oi/features/auth/domain/entities/login_result.dart';
import 'package:quan_oi/features/auth/domain/repositories/auth_repository.dart';
import 'package:quan_oi/features/auth/domain/usecases/confirm_registration_use_case.dart';
import 'package:quan_oi/features/auth/domain/usecases/register_use_case.dart';
import 'package:quan_oi/features/auth/presentation/controllers/register_state.dart';
import 'package:quan_oi/features/auth/presentation/providers/auth_providers.dart';

void main() {
  test('register success moves to otp step and keeps email', () async {
    final repository = _FakeRegisterRepository();
    final container = _buildContainer(repository);
    addTearDown(container.dispose);

    await container
        .read(registerNotifierProvider.notifier)
        .submitDetails(
          email: 'user@quanoi.test',
          password: 'password',
          fullName: 'Quan Oi User',
        );

    final state = container.read(registerNotifierProvider);
    expect(state.step, RegisterStep.otp);
    expect(state.status, RegisterStatus.awaitingOtp);
    expect(state.email, 'user@quanoi.test');
  });

  test('register failure stays on details step with error message', () async {
    final repository = _FakeRegisterRepository(
      registerError: Exception('Email exists'),
    );
    final container = _buildContainer(repository);
    addTearDown(container.dispose);

    await container
        .read(registerNotifierProvider.notifier)
        .submitDetails(
          email: 'user@quanoi.test',
          password: 'password',
          fullName: 'Quan Oi User',
        );

    final state = container.read(registerNotifierProvider);
    expect(state.step, RegisterStep.details);
    expect(state.status, RegisterStatus.failure);
    expect(state.errorMessage, 'Email exists');
  });

  test('confirm otp success moves to success status', () async {
    final repository = _FakeRegisterRepository();
    final container = _buildContainer(repository);
    addTearDown(container.dispose);

    await container
        .read(registerNotifierProvider.notifier)
        .submitDetails(
          email: 'user@quanoi.test',
          password: 'password',
          fullName: 'Quan Oi User',
        );
    await container
        .read(registerNotifierProvider.notifier)
        .confirmOtp('123456');

    final state = container.read(registerNotifierProvider);
    expect(state.step, RegisterStep.otp);
    expect(state.status, RegisterStatus.success);
  });

  test('confirm otp failure keeps otp step with error message', () async {
    final repository = _FakeRegisterRepository(
      confirmError: Exception('Invalid OTP'),
    );
    final container = _buildContainer(repository);
    addTearDown(container.dispose);

    await container
        .read(registerNotifierProvider.notifier)
        .submitDetails(
          email: 'user@quanoi.test',
          password: 'password',
          fullName: 'Quan Oi User',
        );
    await container
        .read(registerNotifierProvider.notifier)
        .confirmOtp('000000');

    final state = container.read(registerNotifierProvider);
    expect(state.step, RegisterStep.otp);
    expect(state.status, RegisterStatus.failure);
    expect(state.errorMessage, 'Invalid OTP');
  });
}

ProviderContainer _buildContainer(_FakeRegisterRepository repository) {
  return ProviderContainer(
    overrides: [
      registerUseCaseProvider.overrideWithValue(RegisterUseCase(repository)),
      confirmRegistrationUseCaseProvider.overrideWithValue(
        ConfirmRegistrationUseCase(repository),
      ),
    ],
  );
}

class _FakeRegisterRepository implements AuthRepository {
  final Object? registerError;
  final Object? confirmError;

  const _FakeRegisterRepository({this.registerError, this.confirmError});

  @override
  Future<void> register({
    required String email,
    required String password,
    required String fullName,
  }) async {
    if (registerError != null) {
      throw registerError!;
    }
  }

  @override
  Future<void> confirmRegistration({
    required String email,
    required String otpCode,
  }) async {
    if (confirmError != null) {
      throw confirmError!;
    }
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
  Future<LoginResult> login({required String email, required String password}) {
    throw UnimplementedError();
  }

  @override
  Future<void> logout() {
    throw UnimplementedError();
  }

  @override
  Future<LoginResult?> restoreSession() {
    throw UnimplementedError();
  }
}
