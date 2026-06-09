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
}
