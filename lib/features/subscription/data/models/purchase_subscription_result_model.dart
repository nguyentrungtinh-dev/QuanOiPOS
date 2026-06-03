import '../../domain/entities/purchase_subscription_result.dart';

class PurchaseSubscriptionResultModel {
  final int subscriptionId;
  final int paymentId;
  final int orderCode;
  final String planName;
  final double amount;
  final String paymentLink;
  final int daysValid;
  final int maxStores;
  final DateTime? expiresAt;

  const PurchaseSubscriptionResultModel({
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

  factory PurchaseSubscriptionResultModel.fromJson(Object? json) {
    if (json is! Map<String, dynamic>) {
      throw const FormatException('Invalid purchase subscription result data');
    }

    return PurchaseSubscriptionResultModel(
      subscriptionId: _intValue(json['subscriptionId']),
      paymentId: _intValue(json['paymentId']),
      orderCode: _intValue(json['orderCode']),
      planName: _stringValue(json['planName']),
      amount: _doubleValue(json['amount']),
      paymentLink: _stringValue(json['paymentLink']),
      daysValid: _intValue(json['daysValid']),
      maxStores: _intValue(json['maxStores']),
      expiresAt: _dateValue(json['expiresAt']),
    );
  }

  PurchaseSubscriptionResult toEntity() {
    return PurchaseSubscriptionResult(
      subscriptionId: subscriptionId,
      paymentId: paymentId,
      orderCode: orderCode,
      planName: planName,
      amount: amount,
      paymentLink: paymentLink,
      daysValid: daysValid,
      maxStores: maxStores,
      expiresAt: expiresAt,
    );
  }

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
