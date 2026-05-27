enum StoreStatus {
  active(1, 'Hoạt động'),
  inactive(2, 'Ngưng hoạt động'),
  closed(3, 'Đóng cửa'),
  unknown(0, 'Không xác định');

  final int code;
  final String label;

  const StoreStatus(this.code, this.label);

  bool get canAccess => this == StoreStatus.active;

  static StoreStatus fromCode(int code) {
    return switch (code) {
      1 => StoreStatus.active,
      2 => StoreStatus.inactive,
      3 => StoreStatus.closed,
      _ => StoreStatus.unknown,
    };
  }
}

class Store {
  final int id;
  final int ownerAccountId;
  final String storeName;
  final String phone;
  final String address;
  final StoreStatus status;
  final DateTime? createdAt;
  final String? createdBy;
  final DateTime? updatedAt;
  final String? updatedBy;
  final bool isDeleted;

  const Store({
    required this.id,
    required this.ownerAccountId,
    required this.storeName,
    required this.phone,
    required this.address,
    required this.status,
    this.createdAt,
    this.createdBy,
    this.updatedAt,
    this.updatedBy,
    required this.isDeleted,
  });
}
