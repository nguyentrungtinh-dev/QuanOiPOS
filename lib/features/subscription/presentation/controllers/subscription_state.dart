import '../../domain/entities/active_subscription.dart';
import '../../domain/entities/pending_subscription_purchase.dart';
import '../../domain/entities/service_package.dart';

enum SubscriptionStatus {
  initial,
  loading,
  ready,
  purchasing,
  waitingForPayment,
  paymentCompletedRefreshing,
  paymentFailed,
  error,
}

class SubscriptionState {
  final SubscriptionStatus status;
  final List<ServicePackage> plans;
  final ActiveSubscription? activeSubscription;
  final PendingSubscriptionPurchase? pendingPurchase;
  final String? checkoutUrl;
  final String? purchasingPlanId;
  final String? errorMessage;

  const SubscriptionState({
    required this.status,
    this.plans = const [],
    this.activeSubscription,
    this.pendingPurchase,
    this.checkoutUrl,
    this.purchasingPlanId,
    this.errorMessage,
  });

  const SubscriptionState.initial()
    : status = SubscriptionStatus.initial,
      plans = const [],
      activeSubscription = null,
      pendingPurchase = null,
      checkoutUrl = null,
      purchasingPlanId = null,
      errorMessage = null;

  bool get isLoading =>
      status == SubscriptionStatus.loading ||
      status == SubscriptionStatus.purchasing ||
      status == SubscriptionStatus.paymentCompletedRefreshing;

  bool get isWaitingForPayment =>
      status == SubscriptionStatus.waitingForPayment;

  SubscriptionState copyWith({
    SubscriptionStatus? status,
    List<ServicePackage>? plans,
    ActiveSubscription? activeSubscription,
    PendingSubscriptionPurchase? pendingPurchase,
    String? checkoutUrl,
    String? purchasingPlanId,
    String? errorMessage,
    bool clearError = false,
    bool clearActiveSubscription = false,
    bool clearPendingPurchase = false,
    bool clearCheckoutUrl = false,
    bool clearPurchasingPlanId = false,
  }) {
    return SubscriptionState(
      status: status ?? this.status,
      plans: plans ?? this.plans,
      activeSubscription: clearActiveSubscription
          ? null
          : (activeSubscription ?? this.activeSubscription),
      pendingPurchase: clearPendingPurchase
          ? null
          : (pendingPurchase ?? this.pendingPurchase),
      checkoutUrl: clearCheckoutUrl ? null : (checkoutUrl ?? this.checkoutUrl),
      purchasingPlanId: clearPurchasingPlanId
          ? null
          : (purchasingPlanId ?? this.purchasingPlanId),
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}
