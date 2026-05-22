import 'package:flutter/material.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/index.dart';

class LoginForm extends StatefulWidget {
  final bool isLoading;
  final String? errorMessage;
  final Future<void> Function(String email, String password) onSubmit;
  final VoidCallback onForgotPasswordPressed;
  final VoidCallback onRegisterPressed;

  const LoginForm({
    super.key,
    required this.isLoading,
    required this.errorMessage,
    required this.onSubmit,
    required this.onForgotPasswordPressed,
    required this.onRegisterPressed,
  });

  @override
  State<LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends State<LoginForm> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    final isValid = _formKey.currentState?.validate() ?? false;
    if (!isValid) return;

    await widget.onSubmit(
      _emailController.text.trim(),
      _passwordController.text,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Tài khoản', style: AppTextStyles.labelSm),
          const SizedBox(height: AppConstants.spacingSm),
          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.text,
            textInputAction: TextInputAction.next,
            style: AppTextStyles.input,
            decoration: const InputDecoration(
              hintText: 'Tên đăng nhập hoặc email',
            ),
            validator: (value) {
              final email = value?.trim() ?? '';
              if (email.isEmpty) return 'Vui lòng nhập tài khoản';
              return null;
            },
          ),
          const SizedBox(height: AppConstants.spacingMd),
          Text('Mật khẩu', style: AppTextStyles.labelSm),
          const SizedBox(height: AppConstants.spacingSm),
          TextFormField(
            controller: _passwordController,
            obscureText: _obscurePassword,
            textInputAction: TextInputAction.done,
            style: AppTextStyles.input,
            decoration: InputDecoration(
              hintText: 'Mật khẩu',
              suffixIcon: IconButton(
                onPressed: () =>
                    setState(() => _obscurePassword = !_obscurePassword),
                icon: Icon(
                  _obscurePassword
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                ),
              ),
            ),
            onFieldSubmitted: (_) => _handleSubmit(),
            validator: (value) {
              if ((value ?? '').isEmpty) return 'Vui lòng nhập mật khẩu';
              return null;
            },
          ),
          if (widget.errorMessage != null) ...[
            const SizedBox(height: AppConstants.spacingSm),
            Text(
              widget.errorMessage!,
              style: AppTextStyles.bodySm.copyWith(color: AppColors.error),
            ),
          ],
          const SizedBox(height: AppConstants.spacingSm),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TextButton(
                onPressed: widget.onForgotPasswordPressed,
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: const Size(0, 0),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(
                  'Quên mật khẩu?',
                  style: AppTextStyles.labelSm.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
              TextButton(
                onPressed: widget.onRegisterPressed,
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: const Size(0, 0),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(
                  'Đăng ký ngay',
                  style: AppTextStyles.labelSm.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppConstants.spacingLg),
          ElevatedButton(
            onPressed: widget.isLoading ? null : _handleSubmit,
            child: widget.isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('ĐĂNG NHẬP NGAY'),
          ),
          const SizedBox(height: AppConstants.spacingMd),
          Row(
            children: [
              const Expanded(child: Divider()),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppConstants.spacingSm,
                ),
                child: Text(
                  'Hoặc đăng nhập với',
                  style: AppTextStyles.bodyXs.copyWith(
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
              const Expanded(child: Divider()),
            ],
          ),
          const SizedBox(height: AppConstants.spacingMd),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Google login sẽ triển khai sau'),
                      ),
                    );
                  },
                  child: const Text('Google'),
                ),
              ),
              const SizedBox(width: AppConstants.spacingSm),
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Facebook login sẽ triển khai sau'),
                      ),
                    );
                  },
                  child: const Text('Facebook'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
