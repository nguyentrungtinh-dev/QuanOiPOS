class PendingSubscriptionPurchase {
  final int subscriptionId;
  final int paymentId;
  final int orderCode;
  final String planName;
  final double amount;
  final String paymentLink;
  final DateTime? expiresAt;

  const PendingSubscriptionPurchase({
    required this.subscriptionId,
    required this.paymentId,
    required this.orderCode,
    required this.planName,
    required this.amount,
    required this.paymentLink,
    required this.expiresAt,
  });
}
