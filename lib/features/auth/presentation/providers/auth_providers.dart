import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/di/injection.dart';
import '../../data/datasources/auth_remote_data_source.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/usecases/login_use_case.dart';
import '../../domain/usecases/logout_use_case.dart';
import '../../domain/usecases/restore_session_use_case.dart';
import '../../domain/usecases/register_use_case.dart';
import '../../domain/usecases/confirm_registration_use_case.dart';
import '../../domain/usecases/forgot_password_use_case.dart';
import '../../domain/usecases/confirm_forgot_password_use_case.dart';
import '../controllers/auth_notifier.dart';
import '../controllers/auth_state.dart';
import '../controllers/forgot_password_notifier.dart';
import '../controllers/forgot_password_state.dart';
import '../controllers/register_notifier.dart';
import '../controllers/register_state.dart';

final authRemoteDataSourceProvider = Provider<AuthRemoteDataSource>((ref) {
  return locator<AuthRemoteDataSource>();
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return locator<AuthRepository>();
});

final loginUseCaseProvider = Provider<LoginUseCase>((ref) {
  return locator<LoginUseCase>();
});

final logoutUseCaseProvider = Provider<LogoutUseCase>((ref) {
  return locator<LogoutUseCase>();
});

final restoreSessionUseCaseProvider = Provider<RestoreSessionUseCase>((ref) {
  return locator<RestoreSessionUseCase>();
});

final registerUseCaseProvider = Provider<RegisterUseCase>((ref) {
  return locator<RegisterUseCase>();
});

final confirmRegistrationUseCaseProvider = Provider<ConfirmRegistrationUseCase>(
  (ref) {
    return locator<ConfirmRegistrationUseCase>();
  },
);

final forgotPasswordUseCaseProvider = Provider<ForgotPasswordUseCase>((ref) {
  return locator<ForgotPasswordUseCase>();
});

final confirmForgotPasswordUseCaseProvider =
    Provider<ConfirmForgotPasswordUseCase>((ref) {
      return locator<ConfirmForgotPasswordUseCase>();
    });

final authNotifierProvider = NotifierProvider<AuthNotifier, AuthState>(
  AuthNotifier.new,
);

final registerNotifierProvider =
    NotifierProvider<RegisterNotifier, RegisterState>(RegisterNotifier.new);

final forgotPasswordNotifierProvider =
    NotifierProvider<ForgotPasswordNotifier, ForgotPasswordState>(
      ForgotPasswordNotifier.new,
    );
