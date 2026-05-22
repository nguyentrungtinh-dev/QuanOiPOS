import '../repositories/auth_repository.dart';

class ConfirmForgotPasswordUseCase {
  final AuthRepository _repository;

  const ConfirmForgotPasswordUseCase(this._repository);

  Future<void> call({
    required String email,
    required String otpCode,
    required String newPassword,
  }) {
    return _repository.confirmForgotPassword(
      email: email,
      otpCode: otpCode,
      newPassword: newPassword,
    );
  }
}
