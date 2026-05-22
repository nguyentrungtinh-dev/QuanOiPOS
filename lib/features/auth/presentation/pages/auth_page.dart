import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/index.dart';
import '../controllers/auth_state.dart';
import '../controllers/forgot_password_state.dart';
import '../controllers/register_state.dart';
import '../providers/auth_providers.dart';
import '../widgets/forgot_password_form.dart';
import '../widgets/login_form.dart';
import '../widgets/register_form.dart';

enum AuthFormMode { login, register, forgotPassword }

class AuthPage extends ConsumerStatefulWidget {
  const AuthPage({super.key});

  @override
  ConsumerState<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends ConsumerState<AuthPage> {
  AuthFormMode _mode = AuthFormMode.login;

  @override
  Widget build(BuildContext context) {
    ref.listen<RegisterState>(registerNotifierProvider, (previous, next) {
      if (previous?.status == RegisterStatus.success ||
          next.status != RegisterStatus.success) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đăng ký thành công. Vui lòng đăng nhập.'),
        ),
      );

      if (mounted) {
        setState(() => _mode = AuthFormMode.login);
      }

      ref.read(registerNotifierProvider.notifier).reset();
    });

    ref.listen<ForgotPasswordState>(forgotPasswordNotifierProvider, (
      previous,
      next,
    ) {
      if (previous?.status == ForgotPasswordStatus.success ||
          next.status != ForgotPasswordStatus.success) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đặt lại mật khẩu thành công. Vui lòng đăng nhập.'),
        ),
      );

      if (mounted) {
        setState(() => _mode = AuthFormMode.login);
      }

      ref.read(forgotPasswordNotifierProvider.notifier).reset();
    });

    final authState = ref.watch(authNotifierProvider);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.primaryLight, AppColors.background],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppConstants.spacingMd),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(40),
                    side: const BorderSide(color: AppColors.border),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(AppConstants.spacingXl),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const _AuthHeader(),
                        const SizedBox(height: AppConstants.spacingXl),
                        if (_mode == AuthFormMode.login)
                          LoginForm(
                            isLoading: authState.isLoading,
                            errorMessage: authState.status == AuthStatus.failure
                                ? authState.errorMessage
                                : null,
                            onSubmit: (email, password) async {
                              await ref
                                  .read(authNotifierProvider.notifier)
                                  .login(email: email, password: password);
                            },
                            onForgotPasswordPressed: () {
                              ref
                                  .read(registerNotifierProvider.notifier)
                                  .reset();
                              ref
                                  .read(forgotPasswordNotifierProvider.notifier)
                                  .reset();
                              ref
                                  .read(authNotifierProvider.notifier)
                                  .clearError();
                              setState(
                                () => _mode = AuthFormMode.forgotPassword,
                              );
                            },
                            onRegisterPressed: () {
                              ref
                                  .read(registerNotifierProvider.notifier)
                                  .reset();
                              ref
                                  .read(forgotPasswordNotifierProvider.notifier)
                                  .reset();
                              setState(() => _mode = AuthFormMode.register);
                              ref
                                  .read(authNotifierProvider.notifier)
                                  .clearError();
                            },
                          )
                        else if (_mode == AuthFormMode.register)
                          RegisterForm(
                            onBackToLoginPressed: () {
                              setState(() => _mode = AuthFormMode.login);
                              ref
                                  .read(forgotPasswordNotifierProvider.notifier)
                                  .reset();
                              ref
                                  .read(authNotifierProvider.notifier)
                                  .clearError();
                            },
                          )
                        else
                          ForgotPasswordForm(
                            onBackToLoginPressed: () {
                              setState(() => _mode = AuthFormMode.login);
                              ref
                                  .read(authNotifierProvider.notifier)
                                  .clearError();
                            },
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AuthHeader extends StatelessWidget {
  const _AuthHeader();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.24),
                    blurRadius: 16,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              alignment: Alignment.center,
              child: const Text('🐵', style: TextStyle(fontSize: 46)),
            ),
            Positioned(
              top: 2,
              right: 2,
              child: Container(
                width: 24,
                height: 24,
                decoration: const BoxDecoration(
                  color: AppColors.surface,
                  shape: BoxShape.circle,
                ),
                padding: const EdgeInsets.all(2),
                child: Container(
                  decoration: const BoxDecoration(
                    color: AppColors.error,
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    'Ó',
                    style: AppTextStyles.labelXs.copyWith(
                      color: AppColors.surface,
                      fontSize: 10,
                      height: 1.0,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppConstants.spacingLg),
        Text(
          'QUÁN ƠI!',
          style: AppTextStyles.h2.copyWith(
            color: AppColors.primary,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: AppConstants.spacingSm),
        Text(
          'Hệ thống quản lý nhà hàng thông minh',
          style: AppTextStyles.bodySm,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
