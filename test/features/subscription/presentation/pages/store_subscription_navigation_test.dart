import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quan_oi/config/router_config.dart';
import 'package:quan_oi/core/storage/last_active_store_storage.dart';
import 'package:quan_oi/features/auth/domain/entities/account_type.dart';
import 'package:quan_oi/features/auth/presentation/controllers/auth_notifier.dart';
import 'package:quan_oi/features/auth/presentation/controllers/auth_state.dart';
import 'package:quan_oi/features/auth/presentation/providers/auth_providers.dart';
import 'package:quan_oi/features/workspace_context/domain/usecases/clear_last_active_store_use_case.dart';
import 'package:quan_oi/features/workspace_context/domain/usecases/load_last_active_store_use_case.dart';
import 'package:quan_oi/features/workspace_context/domain/usecases/save_last_active_store_use_case.dart';
import 'package:quan_oi/features/workspace_context/presentation/providers/workspace_context_providers.dart';
import 'package:quan_oi/features/subscription/domain/entities/active_subscription.dart';
import 'package:quan_oi/features/subscription/domain/entities/pending_subscription_purchase.dart';
import 'package:quan_oi/features/subscription/domain/entities/purchase_subscription_result.dart';
import 'package:quan_oi/features/subscription/domain/entities/service_package.dart';
import 'package:quan_oi/features/subscription/domain/repositories/subscription_repository.dart';
import 'package:quan_oi/features/subscription/domain/usecases/clear_pending_subscription_purchase_use_case.dart';
import 'package:quan_oi/features/subscription/domain/usecases/load_active_subscription_use_case.dart';
import 'package:quan_oi/features/subscription/domain/usecases/load_pending_subscription_purchase_use_case.dart';
import 'package:quan_oi/features/subscription/domain/usecases/load_subscription_plans_use_case.dart';
import 'package:quan_oi/features/subscription/domain/usecases/purchase_subscription_use_case.dart';
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
    expect(find.text('MUA GÓI'), findsOneWidget);
  });

  testWidgets('StoreUser sees active subscription card when subscribed', (
    tester,
  ) async {
    final container = _buildContainer(
      AccountType.storeUser,
      activeSubscription: _activeSubscription,
    );
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

    expect(find.text('GÓI ĐANG HOẠT ĐỘNG'), findsOneWidget);
    expect(find.text('Pro'), findsWidgets);
    expect(find.text('Hạn sử dụng: 13/06/2026'), findsOneWidget);
    expect(find.text('18 ngày còn lại'), findsOneWidget);
    expect(find.text('Tự động gia hạn'), findsOneWidget);
    expect(find.text('Nâng cấp gói'), findsOneWidget);

    await tester.drag(find.byType(Scrollable).first, const Offset(0, -700));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const Key('subscription_plan_page_view')),
      findsOneWidget,
    );
    expect(find.text('Gói hiện tại'), findsOneWidget);
    expect(find.text('MUA GÓI'), findsNothing);
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

ProviderContainer _buildContainer(
  AccountType accountType, {
  ActiveSubscription? activeSubscription,
}) {
  final repository = _FakeSubscriptionRepository(
    activeSubscription: activeSubscription,
  );

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
      loadActiveSubscriptionUseCaseProvider.overrideWithValue(
        LoadActiveSubscriptionUseCase(repository),
      ),
      purchaseSubscriptionUseCaseProvider.overrideWithValue(
        PurchaseSubscriptionUseCase(repository),
      ),
      loadPendingSubscriptionPurchaseUseCaseProvider.overrideWithValue(
        LoadPendingSubscriptionPurchaseUseCase(repository),
      ),
      clearPendingSubscriptionPurchaseUseCaseProvider.overrideWithValue(
        ClearPendingSubscriptionPurchaseUseCase(repository),
      ),
      ..._lastActiveStoreOverrides(_FakeLastActiveStoreStorage()),
    ],
  );
}

List<Override> _lastActiveStoreOverrides(_FakeLastActiveStoreStorage storage) {
  return [
    loadLastActiveStoreUseCaseProvider.overrideWithValue(
      LoadLastActiveStoreUseCase(storage),
    ),
    saveLastActiveStoreUseCaseProvider.overrideWithValue(
      SaveLastActiveStoreUseCase(storage),
    ),
    clearLastActiveStoreUseCaseProvider.overrideWithValue(
      ClearLastActiveStoreUseCase(storage),
    ),
  ];
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
  final ActiveSubscription? activeSubscription;
  PendingSubscriptionPurchase? pendingPurchase;

  _FakeSubscriptionRepository({this.activeSubscription});

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

  @override
  Future<ActiveSubscription?> loadActiveSubscription() async {
    return activeSubscription;
  }

  @override
  Future<PurchaseSubscriptionResult> purchaseSubscription({
    required int planId,
    bool autoRenew = true,
    String? returnUrl,
    String? cancelUrl,
  }) async {
    return const PurchaseSubscriptionResult(
      subscriptionId: 3,
      paymentId: 7,
      orderCode: 81780473152,
      planName: 'Pro',
      amount: 299000,
      paymentLink: 'https://pay.payos.vn/web/test',
      daysValid: 30,
      maxStores: 5,
      expiresAt: null,
    );
  }

  @override
  Future<PendingSubscriptionPurchase?> loadPendingPurchase() async {
    return pendingPurchase;
  }

  @override
  Future<void> clearPendingPurchase() async {
    pendingPurchase = null;
  }
}

class _FakeLastActiveStoreStorage implements LastActiveStoreStorage {
  int? lastStoreId;

  _FakeLastActiveStoreStorage({int? initialStoreId})
    : lastStoreId = initialStoreId;

  @override
  Future<int?> getLastActiveStoreId() async {
    return lastStoreId;
  }

  @override
  Future<void> saveLastActiveStoreId(int storeId) async {
    lastStoreId = storeId;
  }

  @override
  Future<void> clearLastActiveStoreId() async {
    lastStoreId = null;
  }
}

final _activeSubscription = ActiveSubscription(
  id: 2,
  accountId: 8,
  planId: 2,
  planName: 'Pro',
  price: 299000,
  startDate: DateTime.utc(2026, 5, 14),
  endDate: DateTime.utc(2026, 6, 13),
  daysRemaining: 18,
  isActive: true,
  isExpired: false,
  maxStores: 5,
  maxUsers: 50,
  status: 'Active',
  autoRenew: true,
  cancelAt: null,
);
