import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/auth_providers.dart';
import 'forgot_password_state.dart';

class ForgotPasswordNotifier extends Notifier<ForgotPasswordState> {
  @override
  ForgotPasswordState build() {
    return const ForgotPasswordState.initial();
  }

  Future<void> submitEmail(String email) async {
    final normalizedEmail = email.trim();
    state = ForgotPasswordState(
      step: ForgotPasswordStep.email,
      status: ForgotPasswordStatus.submittingEmail,
      email: normalizedEmail,
    );

    try {
      final forgotPasswordUseCase = ref.read(forgotPasswordUseCaseProvider);
      await forgotPasswordUseCase(email: normalizedEmail);

      state = ForgotPasswordState(
        step: ForgotPasswordStep.reset,
        status: ForgotPasswordStatus.awaitingReset,
        email: normalizedEmail,
      );
    } catch (error) {
      state = ForgotPasswordState(
        step: ForgotPasswordStep.email,
        status: ForgotPasswordStatus.failure,
        email: normalizedEmail,
        errorMessage: _cleanError(error),
      );
    }
  }

  Future<void> confirmReset({
    required String otpCode,
    required String newPassword,
  }) async {
    final email = state.email;
    if (email == null || email.isEmpty) {
      state = state.copyWith(
        step: ForgotPasswordStep.email,
        status: ForgotPasswordStatus.failure,
        errorMessage: 'Email đặt lại mật khẩu không hợp lệ',
      );
      return;
    }

    state = state.copyWith(
      step: ForgotPasswordStep.reset,
      status: ForgotPasswordStatus.confirming,
      clearError: true,
    );

    try {
      final confirmUseCase = ref.read(confirmForgotPasswordUseCaseProvider);
      await confirmUseCase(
        email: email,
        otpCode: otpCode.trim(),
        newPassword: newPassword,
      );

      state = state.copyWith(
        step: ForgotPasswordStep.reset,
        status: ForgotPasswordStatus.success,
        clearError: true,
      );
    } catch (error) {
      state = state.copyWith(
        step: ForgotPasswordStep.reset,
        status: ForgotPasswordStatus.failure,
        errorMessage: _cleanError(error),
      );
    }
  }

  void backToEmail() {
    state = state.copyWith(
      step: ForgotPasswordStep.email,
      status: ForgotPasswordStatus.idle,
      clearError: true,
    );
  }

  void reset() {
    state = const ForgotPasswordState.initial();
  }

  String _cleanError(Object error) {
    return error.toString().replaceFirst('Exception: ', '');
  }
}
