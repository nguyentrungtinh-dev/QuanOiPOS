import '../entities/active_subscription.dart';
import '../entities/pending_subscription_purchase.dart';
import '../entities/purchase_subscription_result.dart';
import '../entities/service_package.dart';

abstract class SubscriptionRepository {
  Future<List<ServicePackage>> loadPlans();

  Future<ActiveSubscription?> loadActiveSubscription();

  Future<PurchaseSubscriptionResult> purchaseSubscription({
    required int planId,
    bool autoRenew = true,
    String? returnUrl,
    String? cancelUrl,
  });

  Future<PendingSubscriptionPurchase?> loadPendingPurchase();

  Future<void> clearPendingPurchase();
}
