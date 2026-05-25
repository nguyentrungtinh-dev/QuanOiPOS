import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:quan_oi/app.dart';
import 'package:quan_oi/features/auth/presentation/controllers/auth_notifier.dart';
import 'package:quan_oi/features/auth/presentation/controllers/auth_state.dart';
import 'package:quan_oi/features/auth/presentation/providers/auth_providers.dart';

void main() {
  testWidgets('App bootstrap shows loading during auth initialization', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authNotifierProvider.overrideWith(_WidgetTestAuthNotifier.new),
        ],
        child: const MyApp(),
      ),
    );

    // Initial state should show splash/loading
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    // Pump to let async initialization complete
    await tester.pumpAndSettle();

    // After bootstrap, should show auth page
    expect(find.text('ĐĂNG NHẬP NGAY'), findsOneWidget);
    expect(find.text('Đăng ký ngay'), findsOneWidget);
  });
}

class _WidgetTestAuthNotifier extends AuthNotifier {
  @override
  AuthState build() {
    Future.microtask(() {
      state = const AuthState.unauthenticated();
    });
    return const AuthState.bootstrapping();
  }
}
