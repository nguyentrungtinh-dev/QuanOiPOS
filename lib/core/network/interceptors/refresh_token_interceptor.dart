import 'package:dio/dio.dart';
import '../../session/session_invalidator.dart';
import '../../storage/token_storage.dart';

class RefreshTokenInterceptor extends Interceptor {
  static const _refreshPath = '/auth/refresh';
  static const _hasRetriedAfterRefreshKey = 'has_retried_after_refresh';

  final Dio dio;
  final TokenStorage tokenStorage;
  final SessionInvalidator sessionInvalidator;

  Future<String?>? _refreshAccessTokenFuture;

  RefreshTokenInterceptor({
    required this.dio,
    required this.tokenStorage,
    required this.sessionInvalidator,
  });

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final status = err.response?.statusCode;
    final requestOptions = err.requestOptions;

    if (status != 401 || _isRefreshRequest(requestOptions)) {
      return handler.next(err);
    }

    final hasRetried = requestOptions.extra[_hasRetriedAfterRefreshKey] == true;
    if (hasRetried) {
      await _invalidateSession();
      return handler.next(err);
    }

    final String? newAccessToken;
    try {
      newAccessToken = await _refreshAccessToken();
    } catch (_) {
      await _invalidateSession();
      return handler.next(err);
    }

    if (newAccessToken == null || newAccessToken.isEmpty) {
      await _invalidateSession();
      return handler.next(err);
    }

    try {
      requestOptions.extra[_hasRetriedAfterRefreshKey] = true;
      requestOptions.headers['Authorization'] = 'Bearer $newAccessToken';

      final response = await dio.fetch<dynamic>(requestOptions);
      return handler.resolve(response);
    } catch (_) {
      return handler.next(err);
    }
  }

  bool _isRefreshRequest(RequestOptions requestOptions) {
    final uri = Uri.tryParse(requestOptions.path);
    return requestOptions.path == _refreshPath || uri?.path == _refreshPath;
  }

  Future<String?> _refreshAccessToken() {
    _refreshAccessTokenFuture ??= _requestNewAccessToken().whenComplete(() {
      _refreshAccessTokenFuture = null;
    });

    return _refreshAccessTokenFuture!;
  }

  Future<String?> _requestNewAccessToken() async {
    final refreshToken = await tokenStorage.getRefreshToken();
    if (refreshToken == null || refreshToken.isEmpty) {
      return null;
    }

    final response = await dio.post<dynamic>(
      _refreshPath,
      data: {'refreshToken': refreshToken},
    );

    final newAccessToken = _extractAccessToken(response.data);
    if (newAccessToken != null && newAccessToken.isNotEmpty) {
      await tokenStorage.saveAccessToken(newAccessToken);
    }

    return newAccessToken;
  }

  String? _extractAccessToken(Object? rawData) {
    if (rawData is! Map<String, dynamic>) {
      return null;
    }

    if (rawData['succeeded'] == false) {
      return null;
    }

    final data = rawData['data'];
    if (data is Map<String, dynamic>) {
      return data['accessToken'] as String?;
    }

    return rawData['accessToken'] as String?;
  }

  Future<void> _invalidateSession() async {
    await tokenStorage.clear();
    sessionInvalidator.invalidate();
  }
}
