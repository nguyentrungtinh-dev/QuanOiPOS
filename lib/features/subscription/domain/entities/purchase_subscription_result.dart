import 'pending_subscription_purchase.dart';

class PurchaseSubscriptionResult {
  final int subscriptionId;
  final int paymentId;
  final int orderCode;
  final String planName;
  final double amount;
  final String paymentLink;
  final int daysValid;
  final int maxStores;
  final DateTime? expiresAt;

  const PurchaseSubscriptionResult({
    required this.subscriptionId,
    required this.paymentId,
    required this.orderCode,
    required this.planName,
    required this.amount,
    required this.paymentLink,
    required this.daysValid,
    required this.maxStores,
    required this.expiresAt,
  });

  PendingSubscriptionPurchase toPendingPurchase() {
    return PendingSubscriptionPurchase(
      subscriptionId: subscriptionId,
      paymentId: paymentId,
      orderCode: orderCode,
      planName: planName,
      amount: amount,
      paymentLink: paymentLink,
      expiresAt: expiresAt,
    );
  }
}
