class PurchaseSubscriptionRequestModel {
  final int planId;
  final bool autoRenew;
  final String? returnUrl;
  final String? cancelUrl;

  const PurchaseSubscriptionRequestModel({
    required this.planId,
    required this.autoRenew,
    this.returnUrl,
    this.cancelUrl,
  });

  Map<String, dynamic> toJson() {
    return {
      'planId': planId,
      'autoRenew': autoRenew,
      if (returnUrl != null) 'returnUrl': returnUrl,
      if (cancelUrl != null) 'cancelUrl': cancelUrl,
    };
  }
}
