class ApiResponse<T> {
  final bool succeeded;
  final String? message;
  final List<String> errors;
  final T? data;

  const ApiResponse({
    required this.succeeded,
    this.message,
    this.errors = const [],
    this.data,
  });

  bool get isSuccess => succeeded;

  factory ApiResponse.fromJson(
    Map<String, dynamic> json, {
    T Function(Object? json)? dataFromJson,
  }) {
    final rawData = json['data'];

    return ApiResponse<T>(
      succeeded: json['succeeded'] as bool? ?? false,
      message: json['message'] as String?,
      errors: _toStringList(json['errors']),
      data: dataFromJson == null ? rawData as T? : dataFromJson(rawData),
    );
  }

  Map<String, dynamic> toJson({Object? Function(T value)? dataToJson}) {
    return {
      'succeeded': succeeded,
      'message': message,
      'errors': errors,
      'data': dataToJson == null ? data : (data == null ? null : dataToJson(data as T)),
    };
  }

  static List<String> _toStringList(Object? value) {
    if (value is List) {
      return value.map((item) => item.toString()).toList();
    }

    if (value is String && value.isNotEmpty) {
      return [value];
    }

    return const [];
  }
}
