import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
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
import 'package:quan_oi/features/subscription/presentation/controllers/subscription_state.dart';
import 'package:quan_oi/features/subscription/presentation/providers/subscription_providers.dart';

void main() {
  test('subscription notifier loads plans on provider creation', () async {
    final repository = _FakeSubscriptionRepository();
    final container = _containerWithRepository(repository);
    addTearDown(container.dispose);
    final subscription = _listen(container);
    addTearDown(subscription.close);

    expect(
      container.read(subscriptionNotifierProvider).status,
      SubscriptionStatus.initial,
    );

    await _flushMicrotasks();

    final state = container.read(subscriptionNotifierProvider);
    expect(state.status, SubscriptionStatus.ready);
    expect(state.plans, hasLength(2));
    expect(state.activeSubscription, isNotNull);
    expect(state.activeSubscription!.planName, 'Pro');
    expect(state.errorMessage, isNull);
  });

  test('subscription notifier exposes error when initial load fails', () async {
    final repository = _FakeSubscriptionRepository(
      loadError: Exception('Network down'),
    );
    final container = _containerWithRepository(repository);
    addTearDown(container.dispose);
    final subscription = _listen(container);
    addTearDown(subscription.close);

    container.read(subscriptionNotifierProvider);
    await _flushMicrotasks();

    final state = container.read(subscriptionNotifierProvider);
    expect(state.status, SubscriptionStatus.error);
    expect(state.errorMessage, 'Network down');
  });

  test('subscription notifier supports empty plan list', () async {
    final repository = _FakeSubscriptionRepository(plans: const []);
    final container = _containerWithRepository(repository);
    addTearDown(container.dispose);
    final subscription = _listen(container);
    addTearDown(subscription.close);

    container.read(subscriptionNotifierProvider);
    await _flushMicrotasks();

    final state = container.read(subscriptionNotifierProvider);
    expect(state.status, SubscriptionStatus.ready);
    expect(state.plans, isEmpty);
  });

  test('subscription notifier supports no active subscription', () async {
    final repository = _FakeSubscriptionRepository(activeSubscription: null);
    final container = _containerWithRepository(repository);
    addTearDown(container.dispose);
    final subscription = _listen(container);
    addTearDown(subscription.close);

    container.read(subscriptionNotifierProvider);
    await _flushMicrotasks();

    final state = container.read(subscriptionNotifierProvider);
    expect(state.status, SubscriptionStatus.ready);
    expect(state.activeSubscription, isNull);
  });

  test('subscription notifier exposes error when active load fails', () async {
    final repository = _FakeSubscriptionRepository(
      activeLoadError: Exception('Active subscription unavailable'),
    );
    final container = _containerWithRepository(repository);
    addTearDown(container.dispose);
    final subscription = _listen(container);
    addTearDown(subscription.close);

    container.read(subscriptionNotifierProvider);
    await _flushMicrotasks();

    final state = container.read(subscriptionNotifierProvider);
    expect(state.status, SubscriptionStatus.error);
    expect(state.errorMessage, 'Active subscription unavailable');
  });

  test(
    'subscription notifier clears stale active subscription on reload',
    () async {
      final repository = _FakeSubscriptionRepository();
      final container = _containerWithRepository(repository);
      addTearDown(container.dispose);
      final subscription = _listen(container);
      addTearDown(subscription.close);

      await _flushMicrotasks();
      expect(
        container.read(subscriptionNotifierProvider).activeSubscription,
        isNotNull,
      );

      repository.activeSubscription = null;
      await container.read(subscriptionNotifierProvider.notifier).loadPlans();

      expect(
        container.read(subscriptionNotifierProvider).activeSubscription,
        isNull,
      );
    },
  );

  test('subscription notifier auto disposes between listeners', () async {
    final repository = _FakeSubscriptionRepository();
    final container = _containerWithRepository(repository);
    addTearDown(container.dispose);

    final firstSubscription = _listen(container);
    await _flushMicrotasks();
    expect(
      container.read(subscriptionNotifierProvider).activeSubscription,
      isNotNull,
    );

    firstSubscription.close();
    await container.pump();

    repository.activeSubscription = null;
    final secondSubscription = _listen(container);
    addTearDown(secondSubscription.close);
    await _flushMicrotasks();

    expect(
      container.read(subscriptionNotifierProvider).activeSubscription,
      isNull,
    );
  });
}

ProviderContainer _containerWithRepository(
  _FakeSubscriptionRepository repository,
) {
  return ProviderContainer(
    overrides: [
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
    ],
  );
}

Future<void> _flushMicrotasks() async {
  await Future<void>.delayed(Duration.zero);
  await Future<void>.delayed(Duration.zero);
}

ProviderSubscription<SubscriptionState> _listen(ProviderContainer container) {
  return container.listen<SubscriptionState>(
    subscriptionNotifierProvider,
    (previous, next) {},
  );
}

class _FakeSubscriptionRepository implements SubscriptionRepository {
  final Exception? loadError;
  final Exception? activeLoadError;
  final List<ServicePackage> plans;
  ActiveSubscription? activeSubscription;
  PendingSubscriptionPurchase? pendingPurchase;

  _FakeSubscriptionRepository({
    this.loadError,
    this.activeLoadError,
    this.plans = _defaultPlans,
    this.activeSubscription = _defaultActiveSubscription,
  });

  @override
  Future<List<ServicePackage>> loadPlans() async {
    final error = loadError;
    if (error != null) {
      throw error;
    }

    return plans;
  }

  @override
  Future<ActiveSubscription?> loadActiveSubscription() async {
    final error = activeLoadError;
    if (error != null) {
      throw error;
    }

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
    return pendingPurchase;
  }

  @override
  Future<void> clearPendingPurchase() async {
    pendingPurchase = null;
  }
}

const _defaultPlans = [
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
  ServicePackage(
    id: '2',
    name: 'Pro',
    priceAmount: 299000,
    durationDays: 30,
    maxStores: 5,
    maxUsers: 50,
    features: ['Dashboard nâng cao', 'Quản lý kho'],
    isActive: true,
  ),
];

const _defaultActiveSubscription = ActiveSubscription(
  id: 2,
  accountId: 8,
  planId: 2,
  planName: 'Pro',
  price: 299000,
  startDate: null,
  endDate: null,
  daysRemaining: 18,
  isActive: true,
  isExpired: false,
  maxStores: 5,
  maxUsers: 50,
  status: 'Active',
  autoRenew: true,
  cancelAt: null,
);
