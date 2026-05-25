import 'dart:convert';

import '../../domain/entities/service_package.dart';

class ServicePackageModel {
  final String id;
  final String name;
  final double priceAmount;
  final int durationDays;
  final int maxStores;
  final int maxUsers;
  final List<String> features;
  final bool isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final bool isDeleted;

  const ServicePackageModel({
    required this.id,
    required this.name,
    required this.priceAmount,
    required this.durationDays,
    required this.maxStores,
    required this.maxUsers,
    required this.features,
    required this.isActive,
    this.createdAt,
    this.updatedAt,
    required this.isDeleted,
  });

  factory ServicePackageModel.fromJson(Object? json) {
    if (json is! Map<String, dynamic>) {
      throw const FormatException('Invalid service package data');
    }

    return ServicePackageModel(
      id: _stringValue(json['id'] ?? json['packageId']),
      name: _stringValue(json['name'] ?? json['packageName']),
      priceAmount: _doubleValue(json['priceAmount'] ?? json['price']),
      durationDays: _intValue(json['durationDays']),
      maxStores: _intValue(json['maxStores']),
      maxUsers: _intValue(json['maxUsers']),
      features: _featuresValue(json['features']),
      isActive: _boolValue(json['isActive']),
      createdAt: _dateValue(json['createdAt']),
      updatedAt: _dateValue(json['updatedAt']),
      isDeleted: _boolValue(json['isDeleted']),
    );
  }

  static List<ServicePackageModel> listFromJson(Object? json) {
    if (json == null) {
      return const [];
    }

    if (json is List) {
      return json.map(ServicePackageModel.fromJson).toList();
    }

    if (json is Map<String, dynamic>) {
      final items = json['items'] ?? json['packages'] ?? json['data'];
      if (items is List) {
        return items.map(ServicePackageModel.fromJson).toList();
      }
    }

    throw const FormatException('Invalid service package list data');
  }

  ServicePackage toEntity() {
    return ServicePackage(
      id: id,
      name: name,
      priceAmount: priceAmount,
      durationDays: durationDays,
      maxStores: maxStores,
      maxUsers: maxUsers,
      features: features,
      isActive: isActive,
    );
  }

  static String _stringValue(Object? value, {String fallback = ''}) {
    if (value == null) {
      return fallback;
    }

    final text = value.toString().trim();
    return text.isEmpty ? fallback : text;
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

  static int _intValue(Object? value) {
    if (value is num) {
      return value.toInt();
    }

    if (value is String) {
      return int.tryParse(value) ?? 0;
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

  static List<String> _featuresValue(Object? value) {
    if (value is List) {
      return value.map((item) => item.toString()).toList();
    }

    if (value is String && value.trim().isNotEmpty) {
      try {
        final decoded = jsonDecode(value);
        if (decoded is Map<String, dynamic>) {
          final features = decoded['features'];
          if (features is List) {
            return features.map((item) => item.toString()).toList();
          }
        }

        if (decoded is List) {
          return decoded.map((item) => item.toString()).toList();
        }
      } on FormatException {
        return [value.trim()];
      }

      return [value.trim()];
    }

    return const [];
  }
}
