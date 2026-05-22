import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/index.dart';
import '../controllers/forgot_password_state.dart';
import '../providers/auth_providers.dart';

class ForgotPasswordForm extends ConsumerStatefulWidget {
  final VoidCallback onBackToLoginPressed;

  const ForgotPasswordForm({super.key, required this.onBackToLoginPressed});

  @override
  ConsumerState<ForgotPasswordForm> createState() => _ForgotPasswordFormState();
}

class _ForgotPasswordFormState extends ConsumerState<ForgotPasswordForm> {
  final _emailFormKey = GlobalKey<FormState>();
  final _resetFormKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _otpController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscureNewPassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _otpController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleEmailSubmit() async {
    final isValid = _emailFormKey.currentState?.validate() ?? false;
    if (!isValid) return;

    await ref
        .read(forgotPasswordNotifierProvider.notifier)
        .submitEmail(_emailController.text);
  }

  Future<void> _handleResetSubmit() async {
    final isValid = _resetFormKey.currentState?.validate() ?? false;
    if (!isValid) return;

    await ref
        .read(forgotPasswordNotifierProvider.notifier)
        .confirmReset(
          otpCode: _otpController.text,
          newPassword: _newPasswordController.text,
        );
  }

  void _handleBackToLogin() {
    ref.read(forgotPasswordNotifierProvider.notifier).reset();
    widget.onBackToLoginPressed();
  }

  void _handleBackToEmail() {
    _otpController.clear();
    _newPasswordController.clear();
    _confirmPasswordController.clear();
    ref.read(forgotPasswordNotifierProvider.notifier).backToEmail();
  }

  @override
  Widget build(BuildContext context) {
    final forgotPasswordState = ref.watch(forgotPasswordNotifierProvider);

    if (forgotPasswordState.step == ForgotPasswordStep.reset) {
      return _buildResetStep(forgotPasswordState);
    }

    return _buildEmailStep(forgotPasswordState);
  }

  Widget _buildEmailStep(ForgotPasswordState forgotPasswordState) {
    return Form(
      key: _emailFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Quên mật khẩu', style: AppTextStyles.h4),
          const SizedBox(height: AppConstants.spacingSm),
          Text(
            'Nhập email tài khoản để nhận mã OTP đặt lại mật khẩu.',
            style: AppTextStyles.bodySm,
          ),
          const SizedBox(height: AppConstants.spacingLg),
          Text('Email', style: AppTextStyles.labelSm),
          const SizedBox(height: AppConstants.spacingSm),
          TextFormField(
            controller: _emailController,
            enabled: !forgotPasswordState.isLoading,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.done,
            style: AppTextStyles.input,
            decoration: const InputDecoration(hintText: 'Nhập email tài khoản'),
            onFieldSubmitted: (_) => _handleEmailSubmit(),
            validator: (value) {
              final email = value?.trim() ?? '';
              if (email.isEmpty) return 'Vui lòng nhập email';
              if (!email.contains('@')) return 'Email không hợp lệ';
              return null;
            },
          ),
          if (forgotPasswordState.errorMessage != null) ...[
            const SizedBox(height: AppConstants.spacingSm),
            Text(
              forgotPasswordState.errorMessage!,
              style: AppTextStyles.bodySm.copyWith(color: AppColors.error),
            ),
          ],
          const SizedBox(height: AppConstants.spacingLg),
          ElevatedButton(
            onPressed: forgotPasswordState.isLoading
                ? null
                : _handleEmailSubmit,
            child:
                forgotPasswordState.status ==
                    ForgotPasswordStatus.submittingEmail
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('GỬI MÃ OTP'),
          ),
          const SizedBox(height: AppConstants.spacingSm),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: forgotPasswordState.isLoading
                  ? null
                  : _handleBackToLogin,
              child: const Text('Quay lại đăng nhập'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResetStep(ForgotPasswordState forgotPasswordState) {
    return Form(
      key: _resetFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Đặt lại mật khẩu', style: AppTextStyles.h4),
          const SizedBox(height: AppConstants.spacingSm),
          Text(
            'Mã OTP đã được gửi đến ${forgotPasswordState.email ?? 'email của bạn'}.',
            style: AppTextStyles.bodySm,
          ),
          const SizedBox(height: AppConstants.spacingLg),
          Text('Mã OTP', style: AppTextStyles.labelSm),
          const SizedBox(height: AppConstants.spacingSm),
          TextFormField(
            controller: _otpController,
            enabled: !forgotPasswordState.isLoading,
            keyboardType: TextInputType.number,
            textInputAction: TextInputAction.next,
            style: AppTextStyles.input,
            decoration: const InputDecoration(hintText: 'Nhập mã OTP'),
            validator: (value) {
              if ((value ?? '').trim().isEmpty) return 'Vui lòng nhập mã OTP';
              return null;
            },
          ),
          const SizedBox(height: AppConstants.spacingMd),
          Text('Mật khẩu mới', style: AppTextStyles.labelSm),
          const SizedBox(height: AppConstants.spacingSm),
          TextFormField(
            controller: _newPasswordController,
            enabled: !forgotPasswordState.isLoading,
            obscureText: _obscureNewPassword,
            textInputAction: TextInputAction.next,
            style: AppTextStyles.input,
            decoration: InputDecoration(
              hintText: 'Nhập mật khẩu mới',
              suffixIcon: IconButton(
                onPressed: forgotPasswordState.isLoading
                    ? null
                    : () => setState(
                        () => _obscureNewPassword = !_obscureNewPassword,
                      ),
                icon: Icon(
                  _obscureNewPassword
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                ),
              ),
            ),
            validator: (value) {
              if ((value ?? '').isEmpty) return 'Vui lòng nhập mật khẩu mới';
              return null;
            },
          ),
          const SizedBox(height: AppConstants.spacingMd),
          Text('Xác nhận mật khẩu', style: AppTextStyles.labelSm),
          const SizedBox(height: AppConstants.spacingSm),
          TextFormField(
            controller: _confirmPasswordController,
            enabled: !forgotPasswordState.isLoading,
            obscureText: _obscureConfirmPassword,
            textInputAction: TextInputAction.done,
            style: AppTextStyles.input,
            decoration: InputDecoration(
              hintText: 'Nhập lại mật khẩu mới',
              suffixIcon: IconButton(
                onPressed: forgotPasswordState.isLoading
                    ? null
                    : () => setState(
                        () =>
                            _obscureConfirmPassword = !_obscureConfirmPassword,
                      ),
                icon: Icon(
                  _obscureConfirmPassword
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                ),
              ),
            ),
            onFieldSubmitted: (_) => _handleResetSubmit(),
            validator: (value) {
              if ((value ?? '').isEmpty) {
                return 'Vui lòng xác nhận mật khẩu';
              }
              if (value != _newPasswordController.text) {
                return 'Mật khẩu xác nhận không khớp';
              }
              return null;
            },
          ),
          if (forgotPasswordState.errorMessage != null) ...[
            const SizedBox(height: AppConstants.spacingSm),
            Text(
              forgotPasswordState.errorMessage!,
              style: AppTextStyles.bodySm.copyWith(color: AppColors.error),
            ),
          ],
          const SizedBox(height: AppConstants.spacingLg),
          ElevatedButton(
            onPressed: forgotPasswordState.isLoading
                ? null
                : _handleResetSubmit,
            child: forgotPasswordState.status == ForgotPasswordStatus.confirming
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('ĐẶT LẠI MẬT KHẨU'),
          ),
          const SizedBox(height: AppConstants.spacingSm),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: forgotPasswordState.isLoading
                      ? null
                      : _handleBackToEmail,
                  child: const Text('Sửa email'),
                ),
              ),
              const SizedBox(width: AppConstants.spacingSm),
              Expanded(
                child: TextButton(
                  onPressed: forgotPasswordState.isLoading
                      ? null
                      : _handleBackToLogin,
                  child: const Text('Đăng nhập'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
