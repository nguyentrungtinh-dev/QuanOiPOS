import 'package:flutter_test/flutter_test.dart';
import 'package:quan_oi/features/subscription/domain/entities/service_package.dart';
import 'package:quan_oi/features/subscription/domain/repositories/subscription_repository.dart';
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
}

class _FakeSubscriptionRepository implements SubscriptionRepository {
  bool loadPlansCalled = false;

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
}
