import '../entities/pending_subscription_purchase.dart';
import '../repositories/subscription_repository.dart';

class LoadPendingSubscriptionPurchaseUseCase {
  final SubscriptionRepository _repository;

  const LoadPendingSubscriptionPurchaseUseCase(this._repository);

  Future<PendingSubscriptionPurchase?> call() {
    return _repository.loadPendingPurchase();
  }
}
