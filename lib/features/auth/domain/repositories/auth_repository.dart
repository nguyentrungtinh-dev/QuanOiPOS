import '../entities/login_result.dart';

abstract class AuthRepository {
  Future<LoginResult> login({required String email, required String password});

  Future<void> register({
    required String email,
    required String password,
    required String fullName,
  });

  Future<void> confirmRegistration({
    required String email,
    required String otpCode,
  });

  Future<void> forgotPassword({required String email});

  Future<void> confirmForgotPassword({
    required String email,
    required String otpCode,
    required String newPassword,
  });

  Future<void> logout();

  Future<LoginResult?> restoreSession();
}
