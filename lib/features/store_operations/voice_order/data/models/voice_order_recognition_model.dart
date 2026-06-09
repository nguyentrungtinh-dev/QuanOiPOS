import '../../domain/entities/unmatched_voice_order_item.dart';
import '../../domain/entities/voice_order_item.dart';
import '../../domain/entities/voice_order_recognition.dart';

class VoiceOrderRecognitionModel {
  final String filename;
  final int? storeId;
  final String transcript;
  final bool validationSucceeded;
  final String validationMessage;
  final List<String> errors;
  final VoiceOrderTableModel? table;
  final String? tableName;
  final List<String> missingFields;
  final List<VoiceOrderItemModel> items;
  final List<UnmatchedVoiceOrderItemModel> unmatchedItems;

  const VoiceOrderRecognitionModel({
    required this.filename,
    required this.storeId,
    required this.transcript,
    required this.validationSucceeded,
    required this.validationMessage,
    required this.errors,
    required this.table,
    required this.tableName,
    required this.missingFields,
    required this.items,
    required this.unmatchedItems,
  });

  factory VoiceOrderRecognitionModel.fromJson(Object? json) {
    if (json is! Map<String, dynamic>) {
      throw const FormatException('Invalid voice order recognition data');
    }

    final validation = _mapValue(json['orderValidation']);
    if (validation != null) {
      final data = _mapValue(validation['data']);
      final orderJson = _mapValue(data?['orderJson']);
      final orderData = orderJson ?? data;
      final items = VoiceOrderItemModel.listFromJson(orderData?['items']);

      return VoiceOrderRecognitionModel(
        filename: _stringValue(json['filename']),
        storeId: _intValueOrNull(orderData?['storeId'] ?? json['storeId']),
        transcript: _stringValue(json['text'] ?? data?['rawText']),
        validationSucceeded: _boolValue(validation['succeeded']),
        validationMessage: _stringValue(validation['message']),
        errors: _stringList(validation['errors']),
        table: VoiceOrderTableModel.fromJsonOrNull(data?['table']),
        tableName: _stringValueOrNull(
          orderData?['tableName'] ?? data?['tableName'],
        ),
        missingFields: _stringList(orderData?['missingFields']),
        items: items,
        unmatchedItems: items
            .where((item) => !item.available)
            .map(
              (item) => UnmatchedVoiceOrderItemModel(
                rawText: item.productName,
                quantity: item.quantity,
                reason: item.message ?? 'Sản phẩm chưa hợp lệ.',
              ),
            )
            .toList(),
      );
    }

    final isRawOrder =
        json.containsKey('storeId') ||
        json.containsKey('tableName') ||
        json.containsKey('missingFields');
    if (isRawOrder) {
      return VoiceOrderRecognitionModel(
        filename: _stringValue(json['filename'] ?? json['Filename']),
        storeId: _intValueOrNull(json['storeId'] ?? json['StoreId']),
        transcript: _stringValue(json['text'] ?? json['Text']),
        validationSucceeded: _stringList(json['missingFields']).isEmpty,
        validationMessage: '',
        errors: const [],
        table: null,
        tableName: _stringValueOrNull(json['tableName'] ?? json['TableName']),
        missingFields: _stringList(
          json['missingFields'] ?? json['MissingFields'],
        ),
        items: VoiceOrderItemModel.listFromJson(json['items'] ?? json['Items']),
        unmatchedItems: const [],
      );
    }

    return VoiceOrderRecognitionModel(
      filename: _stringValue(json['filename'] ?? json['Filename']),
      storeId: _intValueOrNull(json['storeId'] ?? json['StoreId']),
      transcript: _stringValue(
        json['transcript'] ??
            json['Transcript'] ??
            json['text'] ??
            json['Text'],
      ),
      validationSucceeded: _boolValue(
        json['succeeded'] ??
            json['Succeeded'] ??
            json['success'] ??
            json['Success'],
        defaultValue: true,
      ),
      validationMessage: _stringValue(json['message'] ?? json['Message']),
      errors: _stringList(json['errors'] ?? json['Errors']),
      table: VoiceOrderTableModel.fromJsonOrNull(
        json['table'] ?? json['Table'],
      ),
      tableName: _stringValueOrNull(json['tableName'] ?? json['TableName']),
      missingFields: _stringList(
        json['missingFields'] ?? json['MissingFields'],
      ),
      items: VoiceOrderItemModel.listFromJson(json['items'] ?? json['Items']),
      unmatchedItems: UnmatchedVoiceOrderItemModel.listFromJson(
        json['unmatchedItems'] ?? json['UnmatchedItems'],
      ),
    );
  }

  factory VoiceOrderRecognitionModel.fromApiResponse(Object? json) {
    if (json is! Map<String, dynamic>) {
      return VoiceOrderRecognitionModel.fromJson(json);
    }

    final successValue =
        json['success'] ??
        json['Success'] ??
        json['succeeded'] ??
        json['Succeeded'];
    if (successValue == false) {
      _throwRequestFailure(json);
    }

    return VoiceOrderRecognitionModel.fromJson(
      json['data'] ?? json['Data'] ?? json,
    );
  }

  VoiceOrderRecognition toEntity() {
    return VoiceOrderRecognition(
      filename: filename,
      storeId: storeId,
      transcript: transcript,
      validationSucceeded: validationSucceeded,
      validationMessage: validationMessage,
      errors: errors,
      tableId: table?.id,
      tableName: table?.name.isNotEmpty == true ? table?.name : tableName,
      tableStatus: table?.status,
      missingFields: missingFields,
      items: items.map((item) => item.toEntity()).toList(),
      unmatchedItems: unmatchedItems.map((item) => item.toEntity()).toList(),
    );
  }

  static Map<String, dynamic>? _mapValue(Object? value) {
    if (value is Map<String, dynamic>) {
      return value;
    }

    if (value is Map) {
      return value.map((key, value) => MapEntry(key.toString(), value));
    }

    return null;
  }

  static bool _boolValue(Object? value, {bool defaultValue = false}) {
    if (value is bool) {
      return value;
    }

    if (value is String) {
      final normalized = value.trim().toLowerCase();
      if (normalized == 'true') return true;
      if (normalized == 'false') return false;
    }

    return defaultValue;
  }

  static String _stringValue(Object? value) {
    return value?.toString().trim() ?? '';
  }

  static String? _stringValueOrNull(Object? value) {
    final text = _stringValue(value);
    return text.isEmpty ? null : text;
  }

  static int? _intValueOrNull(Object? value) {
    if (value == null) {
      return null;
    }

    if (value is num) {
      return value.toInt();
    }

    if (value is String) {
      return int.tryParse(value) ?? double.tryParse(value)?.toInt();
    }

    return null;
  }

  static List<String> _stringList(Object? value) {
    if (value == null) {
      return const [];
    }

    if (value is List) {
      return value
          .map((item) => item.toString().trim())
          .where((item) => item.isNotEmpty)
          .toList();
    }

    final text = value.toString().trim();
    return text.isEmpty ? const [] : [text];
  }

  static Never _throwRequestFailure(Map<String, dynamic> json) {
    final errors = json['errors'] ?? json['Errors'];
    if (errors is List && errors.isNotEmpty) {
      throw FormatException(errors.first.toString());
    }

    final message = json['message'] ?? json['Message'];
    if (message != null && message.toString().trim().isNotEmpty) {
      throw FormatException(message.toString());
    }

    throw const FormatException('Invalid voice order recognition response');
  }
}

class VoiceOrderTableModel {
  final int? id;
  final String name;
  final String status;

  const VoiceOrderTableModel({
    required this.id,
    required this.name,
    required this.status,
  });

  static VoiceOrderTableModel? fromJsonOrNull(Object? json) {
    if (json == null) {
      return null;
    }

    if (json is! Map<String, dynamic>) {
      throw const FormatException('Invalid voice order table data');
    }

    return VoiceOrderTableModel(
      id: _intValueOrNull(json['id'] ?? json['Id']),
      name: _stringValue(json['name'] ?? json['Name']),
      status: _stringValue(json['status'] ?? json['Status']),
    );
  }

  static int? _intValueOrNull(Object? value) {
    if (value == null) {
      return null;
    }

    if (value is num) {
      return value.toInt();
    }

    if (value is String) {
      return int.tryParse(value) ?? double.tryParse(value)?.toInt();
    }

    return null;
  }

  static String _stringValue(Object? value) {
    return value?.toString().trim() ?? '';
  }
}

class VoiceOrderItemModel {
  final int? productId;
  final String productName;
  final int quantity;
  final bool available;
  final String? message;
  final String? note;

  const VoiceOrderItemModel({
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.available,
    this.message,
    this.note,
  });

  factory VoiceOrderItemModel.fromJson(Object? json) {
    if (json is! Map<String, dynamic>) {
      throw const FormatException('Invalid voice order item data');
    }

    return VoiceOrderItemModel(
      productId: _intValueOrNull(json['productId'] ?? json['ProductId']),
      productName: _stringValue(
        json['name'] ??
            json['Name'] ??
            json['productName'] ??
            json['ProductName'],
      ),
      quantity: _intValue(json['quantity'] ?? json['Quantity']),
      available: _boolValue(
        json['available'] ?? json['Available'],
        defaultValue: true,
      ),
      message: _nullableString(json['message'] ?? json['Message']),
      note: _nullableString(json['note'] ?? json['Note']),
    );
  }

  static List<VoiceOrderItemModel> listFromJson(Object? json) {
    if (json == null) {
      return const [];
    }

    if (json is List) {
      return json.map(VoiceOrderItemModel.fromJson).toList();
    }

    throw const FormatException('Invalid voice order item list data');
  }

  VoiceOrderItem toEntity() {
    return VoiceOrderItem(
      productId: productId,
      productName: productName,
      quantity: quantity,
      available: available,
      message: message,
      note: note,
    );
  }

  static int _intValue(Object? value) {
    if (value is num) {
      return value.toInt();
    }

    if (value is String) {
      return int.tryParse(value) ?? double.tryParse(value)?.toInt() ?? 0;
    }

    return 0;
  }

  static int? _intValueOrNull(Object? value) {
    if (value == null) {
      return null;
    }

    if (value is num) {
      return value.toInt();
    }

    if (value is String) {
      return int.tryParse(value) ?? double.tryParse(value)?.toInt();
    }

    return null;
  }

  static String _stringValue(Object? value) {
    final text = value?.toString().trim() ?? '';
    return text.isEmpty ? 'Sản phẩm' : text;
  }

  static String? _nullableString(Object? value) {
    final text = value?.toString().trim() ?? '';
    return text.isEmpty ? null : text;
  }

  static bool _boolValue(Object? value, {bool defaultValue = false}) {
    if (value is bool) {
      return value;
    }

    if (value is String) {
      final normalized = value.trim().toLowerCase();
      if (normalized == 'true') return true;
      if (normalized == 'false') return false;
    }

    return defaultValue;
  }
}

class UnmatchedVoiceOrderItemModel {
  final String rawText;
  final int quantity;
  final String reason;

  const UnmatchedVoiceOrderItemModel({
    required this.rawText,
    required this.quantity,
    required this.reason,
  });

  factory UnmatchedVoiceOrderItemModel.fromJson(Object? json) {
    if (json is! Map<String, dynamic>) {
      throw const FormatException('Invalid unmatched voice order item data');
    }

    return UnmatchedVoiceOrderItemModel(
      rawText: _stringValue(json['rawText'] ?? json['RawText']),
      quantity: _intValue(json['quantity'] ?? json['Quantity']),
      reason: _stringValue(json['reason'] ?? json['Reason']),
    );
  }

  static List<UnmatchedVoiceOrderItemModel> listFromJson(Object? json) {
    if (json == null) {
      return const [];
    }

    if (json is List) {
      return json.map(UnmatchedVoiceOrderItemModel.fromJson).toList();
    }

    throw const FormatException('Invalid unmatched voice order item list data');
  }

  UnmatchedVoiceOrderItem toEntity() {
    return UnmatchedVoiceOrderItem(
      rawText: rawText,
      quantity: quantity,
      reason: reason,
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

  static String _stringValue(Object? value) {
    return value?.toString().trim() ?? '';
  }
}
