import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bytesync/core/network/auth_event_bus.dart';
import 'package:bytesync/core/network/auth_interceptor.dart';
import 'package:bytesync/core/network/auth_session_manager.dart';
import 'package:bytesync/core/network/dio_error_mapper.dart';
import 'package:bytesync/core/storage/secure_storage_service.dart';
import 'package:bytesync/features/auth/data/google_auth_client.dart';
import 'package:bytesync/features/auth/data/remote_auth_repository.dart';
import 'package:bytesync/features/auth/data/auth_providers.dart';
import 'package:bytesync/features/auth/domain/auth_state.dart';
import 'package:bytesync/features/auth/presentation/auth_controller.dart';

typedef _Handler = FutureOr<ResponseBody> Function(RequestOptions options);

class _Adapter implements HttpClientAdapter {
  _Adapter(this.handler);

  final _Handler handler;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async => handler(options);

  @override
  void close({bool force = false}) {}
}

class _MemorySecureStorage extends SecureStorageService {
  String? accessToken;
  String? refreshToken;
  DateTime? refreshedAt;
  int clearCount = 0;

  @override
  Future<String?> readAccessToken() async => accessToken;

  @override
  Future<String?> readRefreshToken() async => refreshToken;

  @override
  Future<DateTime?> readLastSuccessfulRefreshAt() async => refreshedAt;

  @override
  Future<void> saveTokenPair({
    required String accessToken,
    required String refreshToken,
    required DateTime refreshedAt,
  }) async {
    this.accessToken = accessToken;
    this.refreshToken = refreshToken;
    this.refreshedAt = refreshedAt;
  }

  @override
  Future<void> clearTokens() async {
    clearCount++;
    accessToken = null;
    refreshToken = null;
    refreshedAt = null;
  }
}

ResponseBody _json(int status, Map<String, dynamic> body) {
  return ResponseBody.fromString(
    jsonEncode(body),
    status,
    headers: {
      Headers.contentTypeHeader: ['application/json'],
    },
  );
}

ResponseBody _tokenPair([String suffix = '2']) => _json(200, {
  'access_token': 'access-$suffix',
  'refresh_token': 'refresh-$suffix',
  'token_type': 'bearer',
});

class _Harness {
  _Harness({
    required _Handler resourceHandler,
    required _Handler refreshHandler,
    DateTime Function()? utcNow,
  }) {
    refreshDio.httpClientAdapter = _Adapter(refreshHandler);
    sessionManager = AuthSessionManager(
      refreshDio: refreshDio,
      storage: storage,
      eventBus: eventBus,
      utcNow: utcNow,
    );
    resourceDio.httpClientAdapter = _Adapter(resourceHandler);
    resourceDio.interceptors.add(
      AuthInterceptor(
        dio: resourceDio,
        storage: storage,
        sessionManager: sessionManager,
      ),
    );
  }

  final storage = _MemorySecureStorage();
  final eventBus = AuthEventBus();
  final refreshDio = Dio(BaseOptions(baseUrl: 'https://api.test'));
  final resourceDio = Dio(BaseOptions(baseUrl: 'https://api.test'));
  late final AuthSessionManager sessionManager;

  void dispose() => eventBus.dispose();
}

void main() {
  test(
    'cold start refreshes an expired access token and restores user',
    () async {
      var refreshCalls = 0;
      final harness = _Harness(
        resourceHandler: (options) {
          if (options.headers['Authorization'] == 'Bearer access-2') {
            return _json(200, {
              'id': 'user-1',
              'provider': 'google',
              'email': 'one@example.com',
            });
          }
          return _json(401, {'detail': 'expired'});
        },
        refreshHandler: (options) {
          refreshCalls++;
          return _tokenPair();
        },
      );
      await harness.storage.saveTokenPair(
        accessToken: 'expired-access',
        refreshToken: 'refresh-1',
        refreshedAt: DateTime.now().toUtc(),
      );
      final repository = RemoteAuthRepository(
        dio: harness.resourceDio,
        storage: harness.storage,
        googleAuthClient: GoogleAuthClient(),
        errorMapper: const DioErrorMapper(),
        sessionManager: harness.sessionManager,
      );

      final user = await repository.restoreSession();

      expect(user?.id, 'user-1');
      expect(refreshCalls, 1);
      expect(harness.storage.refreshToken, 'refresh-2');
      harness.dispose();
    },
  );

  test('401 refreshes tokens and retries the original request once', () async {
    var resourceCalls = 0;
    var refreshCalls = 0;
    final harness = _Harness(
      resourceHandler: (options) {
        resourceCalls++;
        return options.headers['Authorization'] == 'Bearer access-2'
            ? _json(200, {'ok': true})
            : _json(401, {'detail': 'expired'});
      },
      refreshHandler: (options) {
        refreshCalls++;
        return _tokenPair();
      },
    );
    await harness.storage.saveTokenPair(
      accessToken: 'access-1',
      refreshToken: 'refresh-1',
      refreshedAt: DateTime.now().toUtc(),
    );

    final response = await harness.resourceDio.get<Map<String, dynamic>>(
      '/data',
    );

    expect(response.data, {'ok': true});
    expect(resourceCalls, 2);
    expect(refreshCalls, 1);
    harness.dispose();
  });

  test('refresh 401 clears tokens and emits logout', () async {
    final harness = _Harness(
      resourceHandler: (_) => _json(401, {'detail': 'expired'}),
      refreshHandler: (_) => _json(401, {'detail': 'invalid refresh'}),
    );
    await harness.storage.saveTokenPair(
      accessToken: 'access-1',
      refreshToken: 'refresh-1',
      refreshedAt: DateTime.now().toUtc(),
    );
    final unauthorized = harness.eventBus.stream.first;

    await expectLater(
      harness.resourceDio.get<void>('/data'),
      throwsA(isA<DioException>()),
    );

    expect(await unauthorized, AuthEvent.unauthorized);
    expect(harness.storage.accessToken, isNull);
    expect(harness.storage.refreshToken, isNull);
    expect(harness.storage.clearCount, 1);
    harness.dispose();
  });

  test('refresh network error preserves login state', () async {
    final harness = _Harness(
      resourceHandler: (_) => _json(401, {'detail': 'expired'}),
      refreshHandler: (options) => throw DioException(
        requestOptions: options,
        type: DioExceptionType.connectionError,
      ),
    );
    await harness.storage.saveTokenPair(
      accessToken: 'access-1',
      refreshToken: 'refresh-1',
      refreshedAt: DateTime.now().toUtc(),
    );

    await expectLater(
      harness.resourceDio.get<void>('/data'),
      throwsA(isA<DioException>()),
    );

    expect(harness.storage.accessToken, 'access-1');
    expect(harness.storage.refreshToken, 'refresh-1');
    expect(harness.storage.clearCount, 0);
    harness.dispose();
  });

  test('concurrent 401 responses share one refresh flight', () async {
    var refreshCalls = 0;
    final harness = _Harness(
      resourceHandler: (options) async {
        if (options.headers['Authorization'] == 'Bearer access-1') {
          await Future<void>.delayed(const Duration(milliseconds: 10));
          return _json(401, {'detail': 'expired'});
        }
        return _json(200, {'ok': true});
      },
      refreshHandler: (_) async {
        refreshCalls++;
        await Future<void>.delayed(const Duration(milliseconds: 30));
        return _tokenPair();
      },
    );
    await harness.storage.saveTokenPair(
      accessToken: 'access-1',
      refreshToken: 'refresh-1',
      refreshedAt: DateTime.now().toUtc(),
    );

    final responses = await Future.wait([
      harness.resourceDio.get<Map<String, dynamic>>('/one'),
      harness.resourceDio.get<Map<String, dynamic>>('/two'),
      harness.resourceDio.get<Map<String, dynamic>>('/three'),
    ]);

    expect(responses.every((response) => response.data?['ok'] == true), isTrue);
    expect(refreshCalls, 1);
    harness.dispose();
  });

  test('foreground refresh renews only after the 18-hour interval', () async {
    final now = DateTime.utc(2026, 9, 15, 12);
    var refreshCalls = 0;
    final harness = _Harness(
      resourceHandler: (_) => _json(200, {'ok': true}),
      refreshHandler: (_) {
        refreshCalls++;
        return _tokenPair('$refreshCalls');
      },
      utcNow: () => now,
    );
    await harness.storage.saveTokenPair(
      accessToken: 'access-0',
      refreshToken: 'refresh-0',
      refreshedAt: now.subtract(const Duration(hours: 19)),
    );

    expect(await harness.sessionManager.refreshIfStale(), isTrue);
    expect(await harness.sessionManager.refreshIfStale(), isFalse);
    expect(refreshCalls, 1);
    expect(harness.storage.refreshedAt, now);
    harness.dispose();
  });

  test(
    'cold start network failure preserves tokens and exposes retryable state',
    () async {
      var networkDown = true;
      final harness = _Harness(
        resourceHandler: (options) {
          if (networkDown) {
            throw DioException(
              requestOptions: options,
              type: DioExceptionType.connectionError,
            );
          }
          return _json(200, {
            'id': 'user-1',
            'provider': 'google',
            'email': 'one@example.com',
          });
        },
        refreshHandler: (_) => _tokenPair(),
      );
      await harness.storage.saveTokenPair(
        accessToken: 'access-1',
        refreshToken: 'refresh-1',
        refreshedAt: DateTime.now().toUtc(),
      );
      final repository = RemoteAuthRepository(
        dio: harness.resourceDio,
        storage: harness.storage,
        googleAuthClient: GoogleAuthClient(),
        errorMapper: const DioErrorMapper(),
        sessionManager: harness.sessionManager,
      );
      final container = ProviderContainer(
        overrides: [authRepositoryProvider.overrideWithValue(repository)],
      );
      final retryable = Completer<AuthRestoreFailed>();
      final subscription = container.listen<AuthState>(authControllerProvider, (
        _,
        next,
      ) {
        if (next is AuthRestoreFailed && !retryable.isCompleted) {
          retryable.complete(next);
        }
      }, fireImmediately: true);

      final failedState = await retryable.future;

      expect(failedState.message, '网络连接失败，请检查网络后重试');
      expect(
        container.read(authControllerProvider),
        isNot(isA<AuthUnauthenticated>()),
      );
      expect(harness.storage.accessToken, 'access-1');
      expect(harness.storage.refreshToken, 'refresh-1');
      expect(harness.storage.clearCount, 0);

      networkDown = false;
      await container
          .read(authControllerProvider.notifier)
          .retryRestoreSession();
      final restoredState = container.read(authControllerProvider);
      expect(restoredState, isA<AuthAuthenticated>());
      expect((restoredState as AuthAuthenticated).user.id, 'user-1');

      subscription.close();
      container.dispose();
      harness.dispose();
    },
  );
}
