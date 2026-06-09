class VoiceOrderItem {
  final int? productId;
  final String productName;
  final int quantity;
  final bool available;
  final String? message;
  final String? note;

  const VoiceOrderItem({
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.available,
    this.message,
    this.note,
  });

  VoiceOrderItem copyWith({
    int? productId,
    String? productName,
    int? quantity,
    bool? available,
    Object? message = _unchanged,
    Object? note = _unchanged,
  }) {
    return VoiceOrderItem(
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      quantity: quantity ?? this.quantity,
      available: available ?? this.available,
      message: message == _unchanged ? this.message : message as String?,
      note: note == _unchanged ? this.note : note as String?,
    );
  }
}

const Object _unchanged = Object();
