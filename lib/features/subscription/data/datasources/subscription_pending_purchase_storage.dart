import '../models/pending_subscription_purchase_model.dart';

abstract class SubscriptionPendingPurchaseStorage {
  Future<void> save(PendingSubscriptionPurchaseModel purchase);

  Future<PendingSubscriptionPurchaseModel?> load();

  Future<void> clear();
}
