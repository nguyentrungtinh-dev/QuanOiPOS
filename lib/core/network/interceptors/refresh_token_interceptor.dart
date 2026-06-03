import 'package:dio/dio.dart';
import '../../session/session_invalidator.dart';
import '../../storage/token_storage.dart';

class RefreshTokenInterceptor extends Interceptor {
  static const _refreshPath = '/auth/refresh';
  static const _publicAuthPaths = {
    '/auth/login',
    '/auth/register',
    '/auth/confirm-registration',
    '/auth/forgot-password',
    '/auth/confirm-forgot-password',
  };
  static const _hasRetriedAfterRefreshKey = 'has_retried_after_refresh';

  final Dio dio;
  final TokenStorage tokenStorage;
  final SessionInvalidator sessionInvalidator;
  final Future<void> Function()? onAccessTokenRefreshed;

  Future<String?>? _refreshAccessTokenFuture;

  RefreshTokenInterceptor({
    required this.dio,
    required this.tokenStorage,
    required this.sessionInvalidator,
    this.onAccessTokenRefreshed,
  });

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final status = err.response?.statusCode;
    final requestOptions = err.requestOptions;

    if (status != 401 || _shouldSkipRefresh(requestOptions)) {
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

  bool _isPublicAuthRequest(RequestOptions requestOptions) {
    final uri = Uri.tryParse(requestOptions.path);
    final path = uri?.path ?? requestOptions.path;
    return _publicAuthPaths.contains(path);
  }

  bool _hasBearerToken(RequestOptions requestOptions) {
    final authorization = requestOptions.headers['Authorization'];
    return authorization is String && authorization.trim().isNotEmpty;
  }

  bool _shouldSkipRefresh(RequestOptions requestOptions) {
    return _isRefreshRequest(requestOptions) ||
        _isPublicAuthRequest(requestOptions) ||
        !_hasBearerToken(requestOptions);
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
      await onAccessTokenRefreshed?.call();
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
