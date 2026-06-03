import '../../domain/entities/active_subscription.dart';
import '../../domain/entities/pending_subscription_purchase.dart';
import '../../domain/entities/purchase_subscription_result.dart';
import '../../domain/entities/service_package.dart';
import '../../domain/repositories/subscription_repository.dart';
import '../datasources/subscription_pending_purchase_storage.dart';
import '../datasources/subscription_remote_data_source.dart';
import '../models/pending_subscription_purchase_model.dart';
import '../models/purchase_subscription_request_model.dart';

class SubscriptionRepositoryImpl implements SubscriptionRepository {
  final SubscriptionRemoteDataSource _remoteDataSource;
  final SubscriptionPendingPurchaseStorage _pendingPurchaseStorage;

  const SubscriptionRepositoryImpl(
    this._remoteDataSource,
    this._pendingPurchaseStorage,
  );

  @override
  Future<List<ServicePackage>> loadPlans() async {
    final plans = await _remoteDataSource.getSubscriptionPlans();
    return plans
        .where((plan) => !plan.isDeleted)
        .map((plan) => plan.toEntity())
        .toList();
  }

  @override
  Future<ActiveSubscription?> loadActiveSubscription() async {
    final subscription = await _remoteDataSource.getActiveSubscription();
    return subscription?.toEntity();
  }

  @override
  Future<PurchaseSubscriptionResult> purchaseSubscription({
    required int planId,
    bool autoRenew = true,
    String? returnUrl,
    String? cancelUrl,
  }) async {
    final result = await _remoteDataSource.purchaseSubscription(
      PurchaseSubscriptionRequestModel(
        planId: planId,
        autoRenew: autoRenew,
        returnUrl: returnUrl,
        cancelUrl: cancelUrl,
      ),
    );
    final entity = result.toEntity();
    await _pendingPurchaseStorage.save(
      PendingSubscriptionPurchaseModel.fromEntity(entity.toPendingPurchase()),
    );
    return entity;
  }

  @override
  Future<PendingSubscriptionPurchase?> loadPendingPurchase() async {
    final purchase = await _pendingPurchaseStorage.load();
    return purchase?.toEntity();
  }

  @override
  Future<void> clearPendingPurchase() {
    return _pendingPurchaseStorage.clear();
  }
}
