import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quan_oi/features/subscription/domain/entities/service_package.dart';
import 'package:quan_oi/features/subscription/domain/repositories/subscription_repository.dart';
import 'package:quan_oi/features/subscription/domain/usecases/load_subscription_plans_use_case.dart';
import 'package:quan_oi/features/subscription/presentation/controllers/subscription_state.dart';
import 'package:quan_oi/features/subscription/presentation/providers/subscription_providers.dart';

void main() {
  test('subscription notifier loads plans on provider creation', () async {
    final repository = _FakeSubscriptionRepository();
    final container = _containerWithRepository(repository);
    addTearDown(container.dispose);

    expect(
      container.read(subscriptionNotifierProvider).status,
      SubscriptionStatus.initial,
    );

    await _flushMicrotasks();

    final state = container.read(subscriptionNotifierProvider);
    expect(state.status, SubscriptionStatus.ready);
    expect(state.plans, hasLength(2));
    expect(state.errorMessage, isNull);
  });

  test('subscription notifier exposes error when initial load fails', () async {
    final repository = _FakeSubscriptionRepository(
      loadError: Exception('Network down'),
    );
    final container = _containerWithRepository(repository);
    addTearDown(container.dispose);

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

    container.read(subscriptionNotifierProvider);
    await _flushMicrotasks();

    final state = container.read(subscriptionNotifierProvider);
    expect(state.status, SubscriptionStatus.ready);
    expect(state.plans, isEmpty);
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
    ],
  );
}

Future<void> _flushMicrotasks() async {
  await Future<void>.delayed(Duration.zero);
  await Future<void>.delayed(Duration.zero);
}

class _FakeSubscriptionRepository implements SubscriptionRepository {
  final Exception? loadError;
  final List<ServicePackage> plans;

  const _FakeSubscriptionRepository({
    this.loadError,
    this.plans = _defaultPlans,
  });

  @override
  Future<List<ServicePackage>> loadPlans() async {
    final error = loadError;
    if (error != null) {
      throw error;
    }

    return plans;
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
