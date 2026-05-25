import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quan_oi/core/network/interceptors/auth_interceptor.dart';
import 'package:quan_oi/core/network/interceptors/refresh_token_interceptor.dart';
import 'package:quan_oi/core/session/session_invalidator.dart';
import 'package:quan_oi/core/storage/token_storage.dart';

void main() {
  group('RefreshTokenInterceptor', () {
    late _FakeTokenStorage tokenStorage;
    late SessionInvalidator sessionInvalidator;
    late _QueuedAdapter adapter;
    late Dio dio;

    setUp(() {
      tokenStorage = _FakeTokenStorage(
        accessToken: 'expired-access',
        refreshToken: 'saved-refresh',
      );
      sessionInvalidator = SessionInvalidator();
      adapter = _QueuedAdapter();
      dio = Dio(BaseOptions(baseUrl: 'https://api.test'));
      dio.httpClientAdapter = adapter;
      dio.interceptors.addAll([
        AuthInterceptor(tokenStorage),
        RefreshTokenInterceptor(
          dio: dio,
          tokenStorage: tokenStorage,
          sessionInvalidator: sessionInvalidator,
        ),
      ]);
    });

    tearDown(() {
      sessionInvalidator.dispose();
    });

    test(
      'refreshes access token and retries request with new bearer token',
      () async {
        adapter.enqueue('/protected', (options) {
          return _jsonResponse({'message': 'Expired'}, 401);
        });
        adapter.enqueue('/auth/refresh', (options) {
          expect(options.data, {'refreshToken': 'saved-refresh'});
          return _jsonResponse({
            'succeeded': true,
            'message': 'Cấp access token mới thành công',
            'data': {'accessToken': 'new-access'},
            'errors': <String>[],
          }, 200);
        });
        adapter.enqueue('/protected', (options) {
          expect(options.headers['Authorization'], 'Bearer new-access');
          return _jsonResponse({'ok': true}, 200);
        });

        final response = await dio.get<dynamic>('/protected');

        expect(response.statusCode, 200);
        expect(response.data, {'ok': true});
        expect(tokenStorage.accessToken, 'new-access');
        expect(adapter.paths, ['/protected', '/auth/refresh', '/protected']);
      },
    );

    test('sends refreshToken body key to refresh endpoint', () async {
      adapter.enqueue('/protected', (options) {
        return _jsonResponse({'message': 'Expired'}, 401);
      });
      adapter.enqueue('/auth/refresh', (options) {
        return _jsonResponse({
          'succeeded': true,
          'data': {'accessToken': 'new-access'},
          'errors': <String>[],
        }, 200);
      });
      adapter.enqueue('/protected', (options) {
        return _jsonResponse({'ok': true}, 200);
      });

      await dio.get<dynamic>('/protected');

      final refreshRequest = adapter.requests.firstWhere(
        (request) => request.uri.path == '/auth/refresh',
      );
      expect(
        refreshRequest.data,
        containsPair('refreshToken', 'saved-refresh'),
      );
      expect(refreshRequest.data, isNot(contains('refresh_token')));
    });

    test('clears tokens and invalidates session when refresh fails', () async {
      final invalidation = sessionInvalidator.stream.first;
      adapter.enqueue('/protected', (options) {
        return _jsonResponse({'message': 'Expired'}, 401);
      });
      adapter.enqueue('/auth/refresh', (options) {
        return _jsonResponse({'message': 'Refresh token invalid'}, 401);
      });

      await expectLater(
        dio.get<dynamic>('/protected'),
        throwsA(isA<DioException>()),
      );
      await invalidation.timeout(const Duration(seconds: 1));

      expect(tokenStorage.accessToken, isNull);
      expect(tokenStorage.refreshToken, isNull);
      expect(tokenStorage.clearCount, 1);
    });

    test('does not recursively refresh the refresh endpoint', () async {
      adapter.enqueue('/auth/refresh', (options) {
        return _jsonResponse({'message': 'Refresh token invalid'}, 401);
      });

      await expectLater(
        dio.post<dynamic>('/auth/refresh'),
        throwsA(isA<DioException>()),
      );

      expect(adapter.paths, ['/auth/refresh']);
      expect(tokenStorage.clearCount, 0);
    });

    test(
      'does not retry forever when retried request still returns 401',
      () async {
        final invalidation = sessionInvalidator.stream.first;
        adapter.enqueue('/protected', (options) {
          return _jsonResponse({'message': 'Expired'}, 401);
        });
        adapter.enqueue('/auth/refresh', (options) {
          return _jsonResponse({
            'succeeded': true,
            'data': {'accessToken': 'new-access'},
            'errors': <String>[],
          }, 200);
        });
        adapter.enqueue('/protected', (options) {
          return _jsonResponse({'message': 'Still unauthorized'}, 401);
        });

        await expectLater(
          dio.get<dynamic>('/protected'),
          throwsA(isA<DioException>()),
        );
        await invalidation.timeout(const Duration(seconds: 1));

        expect(adapter.paths, ['/protected', '/auth/refresh', '/protected']);
        expect(tokenStorage.clearCount, 1);
      },
    );

    test('shares one refresh request for concurrent 401 responses', () async {
      final refreshCompleter = Completer<ResponseBody>();
      for (var i = 0; i < 3; i += 1) {
        adapter.enqueue('/protected', (options) {
          return _jsonResponse({'message': 'Expired'}, 401);
        });
      }
      adapter.enqueue('/auth/refresh', (options) {
        return refreshCompleter.future;
      });
      for (var i = 0; i < 3; i += 1) {
        adapter.enqueue('/protected', (options) {
          expect(options.headers['Authorization'], 'Bearer new-access');
          return _jsonResponse({'ok': true}, 200);
        });
      }

      final requests = Future.wait([
        dio.get<dynamic>('/protected'),
        dio.get<dynamic>('/protected'),
        dio.get<dynamic>('/protected'),
      ]);
      await Future<void>.delayed(Duration.zero);

      refreshCompleter.complete(
        _jsonResponse({
          'succeeded': true,
          'data': {'accessToken': 'new-access'},
          'errors': <String>[],
        }, 200),
      );

      final responses = await requests;

      expect(responses, hasLength(3));
      expect(
        adapter.paths.where((path) => path == '/auth/refresh'),
        hasLength(1),
      );
    });
  });
}

typedef _RequestHandler = FutureOr<ResponseBody> Function(RequestOptions);

class _QueuedAdapter implements HttpClientAdapter {
  final Map<String, Queue<_RequestHandler>> _handlers = {};
  final List<RequestOptions> requests = [];

  List<String> get paths {
    return requests.map((request) => request.uri.path).toList();
  }

  void enqueue(String path, _RequestHandler handler) {
    _handlers.putIfAbsent(path, Queue<_RequestHandler>.new).add(handler);
  }

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    final queue = _handlers[options.uri.path];
    if (queue == null || queue.isEmpty) {
      return _jsonResponse({'message': 'No mock response'}, 500);
    }

    return queue.removeFirst()(options);
  }

  @override
  void close({bool force = false}) {}
}

class _FakeTokenStorage implements TokenStorage {
  String? accessToken;
  String? refreshToken;
  int clearCount = 0;

  _FakeTokenStorage({this.accessToken, this.refreshToken});

  @override
  Future<void> saveAccessToken(String token) async {
    accessToken = token;
  }

  @override
  Future<void> saveRefreshToken(String token) async {
    refreshToken = token;
  }

  @override
  Future<String?> getAccessToken() async {
    return accessToken;
  }

  @override
  Future<String?> getRefreshToken() async {
    return refreshToken;
  }

  @override
  Future<void> clear() async {
    clearCount += 1;
    accessToken = null;
    refreshToken = null;
  }
}

ResponseBody _jsonResponse(Object body, int statusCode) {
  return ResponseBody.fromString(
    jsonEncode(body),
    statusCode,
    headers: {
      Headers.contentTypeHeader: [Headers.jsonContentType],
    },
  );
}
