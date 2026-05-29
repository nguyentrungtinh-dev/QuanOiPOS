import 'package:dio/dio.dart';
import '../responses/api_response.dart';

class DioClient {
  final Dio dio;

  DioClient(this.dio);

  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) {
    return dio.get<T>(path, queryParameters: queryParameters);
  }

  Future<Response<T>> post<T>(String path, {dynamic data}) {
    return dio.post<T>(path, data: data);
  }

  Future<Response<T>> put<T>(String path, {dynamic data}) {
    return dio.put<T>(path, data: data);
  }

  Future<Response<T>> delete<T>(String path, {dynamic data}) {
    return dio.delete<T>(path, data: data);
  }

  Future<ApiResponse<T>> getResponse<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    T Function(Object? json)? dataFromJson,
  }) async {
    try {
      final response = await dio.get<dynamic>(
        path,
        queryParameters: queryParameters,
      );
      return _parseApiResponse<T>(response.data, dataFromJson: dataFromJson);
    } on DioException catch (error) {
      throw Exception(_extractErrorMessage(error));
    }
  }

  Future<ApiResponse<T>> postResponse<T>(
    String path, {
    dynamic data,
    T Function(Object? json)? dataFromJson,
  }) async {
    try {
      final response = await dio.post<dynamic>(path, data: data);
      return _parseApiResponse<T>(response.data, dataFromJson: dataFromJson);
    } on DioException catch (error) {
      throw Exception(_extractErrorMessage(error));
    }
  }

  Future<ApiResponse<T>> putResponse<T>(
    String path, {
    dynamic data,
    T Function(Object? json)? dataFromJson,
  }) async {
    try {
      final response = await dio.put<dynamic>(path, data: data);
      return _parseApiResponse<T>(response.data, dataFromJson: dataFromJson);
    } on DioException catch (error) {
      throw Exception(_extractErrorMessage(error));
    }
  }

  Future<ApiResponse<T>> deleteResponse<T>(
    String path, {
    dynamic data,
    T Function(Object? json)? dataFromJson,
  }) async {
    try {
      final response = await dio.delete<dynamic>(path, data: data);
      return _parseApiResponse<T>(response.data, dataFromJson: dataFromJson);
    } on DioException catch (error) {
      throw Exception(_extractErrorMessage(error));
    }
  }

  ApiResponse<T> _parseApiResponse<T>(
    Object? rawData, {
    T Function(Object? json)? dataFromJson,
  }) {
    if (rawData is Map<String, dynamic>) {
      return ApiResponse<T>.fromJson(rawData, dataFromJson: dataFromJson);
    }

    return ApiResponse<T>(
      succeeded: true,
      data: dataFromJson == null ? rawData as T? : dataFromJson(rawData),
    );
  }

  String _extractErrorMessage(DioException error) {
    final responseData = error.response?.data;

    if (responseData is Map<String, dynamic>) {
      final apiResponse = ApiResponse<dynamic>.fromJson(responseData);
      if (apiResponse.errors.isNotEmpty) {
        return apiResponse.errors.first;
      }

      if (apiResponse.message != null &&
          apiResponse.message!.trim().isNotEmpty) {
        return apiResponse.message!;
      }
    }

    if (responseData is String && responseData.trim().isNotEmpty) {
      return responseData;
    }

    final statusCode = error.response?.statusCode;
    if (statusCode != null) {
      return 'Request failed with status code $statusCode';
    }

    return error.message ?? 'Request failed';
  }
}
