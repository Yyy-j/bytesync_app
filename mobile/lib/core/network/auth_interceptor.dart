import 'package:dio/dio.dart';

import '../storage/secure_storage_service.dart';
import 'api_endpoints.dart';
import 'auth_session_manager.dart';

/// Injects the access token and refreshes/retries once after a 401.
class AuthInterceptor extends Interceptor {
  AuthInterceptor({
    required this.dio,
    required this.storage,
    required this.sessionManager,
  });

  final Dio dio;
  final SecureStorageService storage;
  final AuthSessionManager sessionManager;

  static const _retriedKey = 'auth_refresh_retried';

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final token = await storage.readAccessToken();
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final request = err.requestOptions;
    if (err.response?.statusCode != 401 ||
        request.extra[_retriedKey] == true ||
        _isAuthSessionEndpoint(request.path)) {
      handler.next(err);
      return;
    }

    final failedToken = _bearerToken(request.headers['Authorization']);
    var accessToken = await storage.readAccessToken();
    if (accessToken == null || accessToken == failedToken) {
      final refreshed = await sessionManager.refresh();
      if (!refreshed) {
        handler.next(err);
        return;
      }
      accessToken = await storage.readAccessToken();
    }

    if (accessToken == null || accessToken.isEmpty) {
      handler.next(err);
      return;
    }
    request.extra[_retriedKey] = true;
    request.headers['Authorization'] = 'Bearer $accessToken';
    try {
      handler.resolve(await dio.fetch<dynamic>(request));
    } on DioException catch (retryError) {
      handler.next(retryError);
    }
  }

  String? _bearerToken(Object? authorization) {
    if (authorization is! String || !authorization.startsWith('Bearer ')) {
      return null;
    }
    return authorization.substring(7);
  }

  bool _isAuthSessionEndpoint(String path) {
    return path == ApiEndpoints.authRefresh ||
        path == ApiEndpoints.authLogout ||
        path == ApiEndpoints.authGoogle;
  }
}
