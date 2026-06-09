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

  VoiceOrderRecognition copyWith({
    String? filename,
    Object? storeId = _unchanged,
    String? transcript,
    bool? validationSucceeded,
    String? validationMessage,
    List<String>? errors,
    Object? tableId = _unchanged,
    Object? tableName = _unchanged,
    Object? tableStatus = _unchanged,
    List<String>? missingFields,
    List<VoiceOrderItem>? items,
    List<UnmatchedVoiceOrderItem>? unmatchedItems,
  }) {
    return VoiceOrderRecognition(
      filename: filename ?? this.filename,
      storeId: storeId == _unchanged ? this.storeId : storeId as int?,
      transcript: transcript ?? this.transcript,
      validationSucceeded: validationSucceeded ?? this.validationSucceeded,
      validationMessage: validationMessage ?? this.validationMessage,
      errors: errors ?? this.errors,
      tableId: tableId == _unchanged ? this.tableId : tableId as int?,
      tableName: tableName == _unchanged
          ? this.tableName
          : tableName as String?,
      tableStatus: tableStatus == _unchanged
          ? this.tableStatus
          : tableStatus as String?,
      missingFields: missingFields ?? this.missingFields,
      items: items ?? this.items,
      unmatchedItems: unmatchedItems ?? this.unmatchedItems,
    );
  }
}

const Object _unchanged = Object();
