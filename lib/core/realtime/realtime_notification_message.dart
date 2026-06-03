class RealtimeNotificationMessage {
  final String eventName;
  final String title;
  final String content;
  final String audience;
  final Map<String, dynamic> payload;
  final DateTime? occurredAt;

  const RealtimeNotificationMessage({
    required this.eventName,
    required this.title,
    required this.content,
    required this.audience,
    required this.payload,
    required this.occurredAt,
  });

  factory RealtimeNotificationMessage.fromJson(Object? json) {
    if (json is! Map<String, dynamic>) {
      throw const FormatException('Invalid realtime notification data');
    }

    return RealtimeNotificationMessage(
      eventName: _stringValue(json['eventName']),
      title: _stringValue(json['title']),
      content: _stringValue(json['content']),
      audience: _stringValue(json['audience']),
      payload: _mapValue(json['payload']),
      occurredAt: _dateValue(json['occurredAt']),
    );
  }

  static String _stringValue(Object? value) {
    if (value == null) {
      return '';
    }

    return value.toString().trim();
  }

  static Map<String, dynamic> _mapValue(Object? value) {
    if (value is Map<String, dynamic>) {
      return value;
    }

    if (value is Map) {
      return value.map((key, item) => MapEntry(key.toString(), item));
    }

    return const {};
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
