import 'package:flutter_test/flutter_test.dart';
import 'package:quan_oi/features/subscription/domain/entities/active_subscription.dart';
import 'package:quan_oi/features/subscription/domain/entities/pending_subscription_purchase.dart';
import 'package:quan_oi/features/subscription/domain/entities/purchase_subscription_result.dart';
import 'package:quan_oi/features/subscription/domain/entities/service_package.dart';
import 'package:quan_oi/features/subscription/domain/repositories/subscription_repository.dart';
import 'package:quan_oi/features/subscription/domain/usecases/load_active_subscription_use_case.dart';
import 'package:quan_oi/features/subscription/domain/usecases/load_subscription_plans_use_case.dart';

void main() {
  test('load subscription plans use case returns repository plans', () async {
    final repository = _FakeSubscriptionRepository();
    final useCase = LoadSubscriptionPlansUseCase(repository);

    final plans = await useCase();

    expect(plans, hasLength(1));
    expect(plans.single.name, 'Basic');
    expect(repository.loadPlansCalled, isTrue);
  });

  test('load active subscription use case returns repository result', () async {
    final repository = _FakeSubscriptionRepository();
    final useCase = LoadActiveSubscriptionUseCase(repository);

    final subscription = await useCase();

    expect(subscription, isNotNull);
    expect(subscription!.planName, 'Basic');
    expect(repository.loadActiveSubscriptionCalled, isTrue);
  });
}

class _FakeSubscriptionRepository implements SubscriptionRepository {
  bool loadPlansCalled = false;
  bool loadActiveSubscriptionCalled = false;

  @override
  Future<List<ServicePackage>> loadPlans() async {
    loadPlansCalled = true;
    return const [
      ServicePackage(
        id: '1',
        name: 'Basic',
        priceAmount: 99000,
        durationDays: 30,
        maxStores: 1,
        maxUsers: 5,
        features: ['Dashboard'],
        isActive: true,
      ),
    ];
  }

  @override
  Future<ActiveSubscription?> loadActiveSubscription() async {
    loadActiveSubscriptionCalled = true;
    return ActiveSubscription(
      id: 1,
      accountId: 8,
      planId: 1,
      planName: 'Basic',
      price: 99000,
      startDate: DateTime.utc(2026, 5, 14),
      endDate: DateTime.utc(2026, 6, 13),
      daysRemaining: 18,
      isActive: true,
      isExpired: false,
      maxStores: 1,
      maxUsers: 5,
      status: 'Active',
      autoRenew: true,
      cancelAt: null,
    );
  }

  @override
  Future<PurchaseSubscriptionResult> purchaseSubscription({
    required int planId,
    bool autoRenew = true,
    String? returnUrl,
    String? cancelUrl,
  }) async {
    return const PurchaseSubscriptionResult(
      subscriptionId: 1,
      paymentId: 7,
      orderCode: 81780473152,
      planName: 'Basic',
      amount: 99000,
      paymentLink: 'https://pay.payos.vn/web/test',
      daysValid: 30,
      maxStores: 1,
      expiresAt: null,
    );
  }

  @override
  Future<PendingSubscriptionPurchase?> loadPendingPurchase() async {
    return null;
  }

  @override
  Future<void> clearPendingPurchase() async {}
}
