import '../../domain/entities/store.dart';

class StoreModel {
  final int id;
  final int ownerAccountId;
  final String storeName;
  final String phone;
  final String address;
  final int statusCode;
  final DateTime? createdAt;
  final String? createdBy;
  final DateTime? updatedAt;
  final String? updatedBy;
  final bool isDeleted;

  const StoreModel({
    required this.id,
    required this.ownerAccountId,
    required this.storeName,
    required this.phone,
    required this.address,
    required this.statusCode,
    this.createdAt,
    this.createdBy,
    this.updatedAt,
    this.updatedBy,
    required this.isDeleted,
  });

  factory StoreModel.fromJson(Object? json) {
    if (json is! Map<String, dynamic>) {
      throw const FormatException('Invalid store data');
    }

    return StoreModel(
      id: _intValue(json['id']),
      ownerAccountId: _intValue(json['ownerAccountId']),
      storeName: _stringValue(json['storeName']),
      phone: _stringValue(json['phone']),
      address: _stringValue(json['address']),
      statusCode: _intValue(json['status']),
      createdAt: _dateValue(json['createdAt']),
      createdBy: _nullableString(json['createdBy']),
      updatedAt: _dateValue(json['updatedAt']),
      updatedBy: _nullableString(json['updatedBy']),
      isDeleted: _boolValue(json['isDeleted']),
    );
  }

  static List<StoreModel> listFromJson(Object? json) {
    if (json == null) {
      return const [];
    }

    if (json is List) {
      return json.map(StoreModel.fromJson).toList();
    }

    if (json is Map<String, dynamic>) {
      final items = json['items'] ?? json['stores'] ?? json['data'];
      if (items is List) {
        return items.map(StoreModel.fromJson).toList();
      }
    }

    throw const FormatException('Invalid store list data');
  }

  Store toEntity() {
    return Store(
      id: id,
      ownerAccountId: ownerAccountId,
      storeName: storeName,
      phone: phone,
      address: address,
      status: StoreStatus.fromCode(statusCode),
      createdAt: createdAt,
      createdBy: createdBy,
      updatedAt: updatedAt,
      updatedBy: updatedBy,
      isDeleted: isDeleted,
    );
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

  static String _stringValue(Object? value, {String fallback = ''}) {
    if (value == null) {
      return fallback;
    }

    final text = value.toString().trim();
    return text.isEmpty ? fallback : text;
  }

  static String? _nullableString(Object? value) {
    final text = _stringValue(value);
    return text.isEmpty ? null : text;
  }

  static bool _boolValue(Object? value) {
    if (value is bool) {
      return value;
    }

    if (value is String) {
      return value.toLowerCase() == 'true';
    }

    if (value is num) {
      return value != 0;
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
