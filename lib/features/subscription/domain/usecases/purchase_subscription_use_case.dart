import '../entities/purchase_subscription_result.dart';
import '../repositories/subscription_repository.dart';

class PurchaseSubscriptionUseCase {
  final SubscriptionRepository _repository;

  const PurchaseSubscriptionUseCase(this._repository);

  Future<PurchaseSubscriptionResult> call({
    required int planId,
    bool autoRenew = true,
    String? returnUrl,
    String? cancelUrl,
  }) {
    return _repository.purchaseSubscription(
      planId: planId,
      autoRenew: autoRenew,
      returnUrl: returnUrl,
      cancelUrl: cancelUrl,
    );
  }
}
