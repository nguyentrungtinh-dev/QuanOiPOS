import '../repositories/subscription_repository.dart';

class ClearPendingSubscriptionPurchaseUseCase {
  final SubscriptionRepository _repository;

  const ClearPendingSubscriptionPurchaseUseCase(this._repository);

  Future<void> call() {
    return _repository.clearPendingPurchase();
  }
}
