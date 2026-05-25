import '../entities/service_package.dart';
import '../repositories/subscription_repository.dart';

class LoadSubscriptionPlansUseCase {
  final SubscriptionRepository _repository;

  const LoadSubscriptionPlansUseCase(this._repository);

  Future<List<ServicePackage>> call() {
    return _repository.loadPlans();
  }
}
