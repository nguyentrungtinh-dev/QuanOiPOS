import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quan_oi/features/auth/domain/entities/login_result.dart';
import 'package:quan_oi/features/auth/domain/repositories/auth_repository.dart';
import 'package:quan_oi/features/auth/domain/usecases/confirm_registration_use_case.dart';
import 'package:quan_oi/features/auth/domain/usecases/register_use_case.dart';
import 'package:quan_oi/features/auth/presentation/providers/auth_providers.dart';
import 'package:quan_oi/features/auth/presentation/widgets/register_form.dart';

void main() {
  testWidgets('register form validates required fields', (tester) async {
    await tester.pumpWidget(_buildWidget(_FakeRegisterRepository()));

    await tester.tap(find.widgetWithText(ElevatedButton, 'TẠO TÀI KHOẢN'));
    await tester.pump();

    expect(find.text('Vui lòng nhập họ và tên'), findsOneWidget);
    expect(find.text('Vui lòng nhập email'), findsOneWidget);
    expect(find.text('Vui lòng nhập mật khẩu'), findsOneWidget);
    expect(find.text('Vui lòng xác nhận mật khẩu'), findsOneWidget);
  });

  testWidgets('register form validates password confirmation', (tester) async {
    await tester.pumpWidget(_buildWidget(_FakeRegisterRepository()));

    await tester.enterText(find.byType(TextFormField).at(0), 'Quan Oi User');
    await tester.enterText(
      find.byType(TextFormField).at(1),
      'user@quanoi.test',
    );
    await tester.enterText(find.byType(TextFormField).at(2), 'password');
    await tester.enterText(find.byType(TextFormField).at(3), 'different');
    await tester.tap(find.widgetWithText(ElevatedButton, 'TẠO TÀI KHOẢN'));
    await tester.pump();

    expect(find.text('Mật khẩu xác nhận không khớp'), findsOneWidget);
  });

  testWidgets('register form shows otp step after successful details submit', (
    tester,
  ) async {
    await tester.pumpWidget(_buildWidget(_FakeRegisterRepository()));

    await tester.enterText(find.byType(TextFormField).at(0), 'Quan Oi User');
    await tester.enterText(
      find.byType(TextFormField).at(1),
      'user@quanoi.test',
    );
    await tester.enterText(find.byType(TextFormField).at(2), 'password');
    await tester.enterText(find.byType(TextFormField).at(3), 'password');
    await tester.tap(find.widgetWithText(ElevatedButton, 'TẠO TÀI KHOẢN'));
    await tester.pump();

    expect(find.text('Mã OTP'), findsOneWidget);
    expect(find.text('Nhập mã OTP'), findsOneWidget);
  });
}

Widget _buildWidget(_FakeRegisterRepository repository) {
  return ProviderScope(
    overrides: [
      registerUseCaseProvider.overrideWithValue(RegisterUseCase(repository)),
      confirmRegistrationUseCaseProvider.overrideWithValue(
        ConfirmRegistrationUseCase(repository),
      ),
    ],
    child: MaterialApp(
      home: Scaffold(
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: RegisterForm(onBackToLoginPressed: () {}),
        ),
      ),
    ),
  );
}

class _FakeRegisterRepository implements AuthRepository {
  @override
  Future<void> register({
    required String email,
    required String password,
    required String fullName,
  }) async {}

  @override
  Future<void> confirmRegistration({
    required String email,
    required String otpCode,
  }) async {}

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
