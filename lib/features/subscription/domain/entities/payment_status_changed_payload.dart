class PaymentStatusChangedPayload {
  final String paymentType;
  final int subscriptionId;
  final int paymentId;
  final int accountId;
  final double amount;
  final String paymentStatus;
  final String subscriptionStatus;
  final bool success;
  final int orderCode;
  final String paymentLinkId;
  final String reference;
  final bool payosSuccess;
  final String payosCode;
  final String payosDescription;
  final DateTime? transactionDateTime;

  const PaymentStatusChangedPayload({
    required this.paymentType,
    required this.subscriptionId,
    required this.paymentId,
    required this.accountId,
    required this.amount,
    required this.paymentStatus,
    required this.subscriptionStatus,
    required this.success,
    required this.orderCode,
    required this.paymentLinkId,
    required this.reference,
    required this.payosSuccess,
    required this.payosCode,
    required this.payosDescription,
    required this.transactionDateTime,
  });

  factory PaymentStatusChangedPayload.fromJson(Object? json) {
    if (json is! Map<String, dynamic>) {
      throw const FormatException('Invalid payment status payload');
    }

    return PaymentStatusChangedPayload(
      paymentType: _stringValue(json['paymentType']),
      subscriptionId: _intValue(json['subscriptionId']),
      paymentId: _intValue(json['paymentId']),
      accountId: _intValue(json['accountId']),
      amount: _doubleValue(json['amount']),
      paymentStatus: _stringValue(json['paymentStatus']),
      subscriptionStatus: _stringValue(json['subscriptionStatus']),
      success: _boolValue(json['success']),
      orderCode: _intValue(json['orderCode']),
      paymentLinkId: _stringValue(json['paymentLinkId']),
      reference: _stringValue(json['reference']),
      payosSuccess: _boolValue(json['payosSuccess']),
      payosCode: _stringValue(json['payosCode']),
      payosDescription: _stringValue(json['payosDescription']),
      transactionDateTime: _dateValue(json['transactionDateTime']),
    );
  }

  bool get isSubscriptionPayment => paymentType == 'Subscription';

  bool get isCompletedActive =>
      paymentStatus == 'Completed' && subscriptionStatus == 'Active';

  bool get isFailed => paymentStatus == 'Failed';

  static String _stringValue(Object? value) {
    if (value == null) {
      return '';
    }

    return value.toString().trim();
  }

  static int _intValue(Object? value) {
    if (value is num) {
      return value.toInt();
    }

    if (value is String) {
      return int.tryParse(value) ?? 0;
    }

    return 0;
  }

  static double _doubleValue(Object? value) {
    if (value is num) {
      return value.toDouble();
    }

    if (value is String) {
      return double.tryParse(value) ?? 0;
    }

    return 0;
  }

  static bool _boolValue(Object? value) {
    if (value is bool) {
      return value;
    }

    if (value is String) {
      return value.toLowerCase() == 'true';
    }

    return false;
  }

  static DateTime? _dateValue(Object? value) {
    if (value is DateTime) {
      return value;
    }

    if (value is String && value.trim().isNotEmpty) {
      return DateTime.tryParse(value);
    }

    return null;
  }
}
