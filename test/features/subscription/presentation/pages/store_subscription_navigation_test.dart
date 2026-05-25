import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quan_oi/config/router_config.dart';
import 'package:quan_oi/features/auth/domain/entities/account_type.dart';
import 'package:quan_oi/features/auth/presentation/controllers/auth_notifier.dart';
import 'package:quan_oi/features/auth/presentation/controllers/auth_state.dart';
import 'package:quan_oi/features/auth/presentation/providers/auth_providers.dart';
import 'package:quan_oi/features/subscription/domain/entities/service_package.dart';
import 'package:quan_oi/features/subscription/domain/repositories/subscription_repository.dart';
import 'package:quan_oi/features/subscription/domain/usecases/load_subscription_plans_use_case.dart';
import 'package:quan_oi/features/subscription/presentation/providers/subscription_providers.dart';

void main() {
  testWidgets('StoreUser can open subscription route', (tester) async {
    final container = _buildContainer(AccountType.storeUser);
    addTearDown(container.dispose);

    final router = container.read(routerProvider);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(routerConfig: router),
      ),
    );

    router.go('/store-subscription');
    await tester.pumpAndSettle();

    expect(find.text('Gói dịch vụ của tôi'), findsOneWidget);
    expect(find.text('Gói dịch vụ hệ thống'), findsOneWidget);
    expect(
      find.byKey(const Key('subscription_plan_page_view')),
      findsOneWidget,
    );
    expect(find.text('Pro'), findsOneWidget);
    expect(find.text('Khuyên dùng'), findsOneWidget);
    expect(find.textContaining('299.000'), findsOneWidget);
    expect(find.text('5 cửa hàng'), findsOneWidget);
    expect(find.text('50 người dùng'), findsOneWidget);
    expect(find.text('Dashboard nâng cao'), findsOneWidget);
    expect(find.text('Quản lý kho'), findsNothing);

    await tester.ensureVisible(find.text('Xem thêm'));
    await tester.tap(find.text('Xem thêm'));
    await tester.pumpAndSettle();

    expect(find.text('Quản lý kho'), findsOneWidget);
    expect(find.text('Thu gọn'), findsOneWidget);

    await tester.ensureVisible(find.text('Thu gọn'));
    await tester.tap(find.text('Thu gọn'));
    await tester.pumpAndSettle();

    expect(find.text('Quản lý kho'), findsNothing);

    await tester.ensureVisible(find.text('MUA GÓI'));
    await tester.tap(find.text('MUA GÓI'));
    await tester.pump();

    expect(
      find.text('Tính năng mua gói sẽ được triển khai sau'),
      findsOneWidget,
    );
  });

  testWidgets('SystemAdmin is redirected away from subscription route', (
    tester,
  ) async {
    final container = _buildContainer(AccountType.systemAdmin);
    addTearDown(container.dispose);

    final router = container.read(routerProvider);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(routerConfig: router),
      ),
    );

    router.go('/store-subscription');
    await tester.pumpAndSettle();

    expect(find.text('SystemAdmin Workspace'), findsOneWidget);
    expect(find.text('Gói dịch vụ của tôi'), findsNothing);
  });
}

ProviderContainer _buildContainer(AccountType accountType) {
  final repository = _FakeSubscriptionRepository();

  return ProviderContainer(
    overrides: [
      authNotifierProvider.overrideWith(
        () => _FixedAuthNotifier(
          AuthState(
            status: AuthStatus.authenticated,
            accountType: accountType,
            fullName: 'Test User',
            email: 'user@quanoi.test',
          ),
        ),
      ),
      loadSubscriptionPlansUseCaseProvider.overrideWithValue(
        LoadSubscriptionPlansUseCase(repository),
      ),
    ],
  );
}

class _FixedAuthNotifier extends AuthNotifier {
  final AuthState fixedState;

  _FixedAuthNotifier(this.fixedState);

  @override
  AuthState build() {
    return fixedState;
  }
}

class _FakeSubscriptionRepository implements SubscriptionRepository {
  @override
  Future<List<ServicePackage>> loadPlans() async {
    return const [
      ServicePackage(
        id: '2',
        name: 'Pro',
        priceAmount: 299000,
        durationDays: 30,
        maxStores: 5,
        maxUsers: 50,
        features: [
          'Dashboard nâng cao',
          'Quản lý menu đầy đủ',
          'Quản lý đơn hàng',
          'Báo cáo chi tiết',
          'Quản lý kho',
        ],
        isActive: true,
      ),
    ];
  }
}
