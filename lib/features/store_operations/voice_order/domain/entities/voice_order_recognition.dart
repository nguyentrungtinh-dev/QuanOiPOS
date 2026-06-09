import 'unmatched_voice_order_item.dart';
import 'voice_order_item.dart';

class VoiceOrderRecognition {
  final String filename;
  final int? storeId;
  final String transcript;
  final bool validationSucceeded;
  final String validationMessage;
  final List<String> errors;
  final int? tableId;
  final String? tableName;
  final String? tableStatus;
  final List<String> missingFields;
  final List<VoiceOrderItem> items;
  final List<UnmatchedVoiceOrderItem> unmatchedItems;

  const VoiceOrderRecognition({
    this.filename = '',
    this.storeId,
    required this.transcript,
    required this.validationSucceeded,
    required this.validationMessage,
    this.errors = const [],
    this.tableId,
    this.tableName,
    this.tableStatus,
    this.missingFields = const [],
    required this.items,
    required this.unmatchedItems,
  });

  bool get hasRecognizedItems => items.isNotEmpty;

  bool get hasErrors =>
      errors.isNotEmpty ||
      unmatchedItems.isNotEmpty ||
      missingFields.isNotEmpty;
}
