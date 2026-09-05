import 'package:dio/dio.dart';

import '../storage/secure_storage_service.dart';
import 'auth_event_bus.dart';

/// Injects the stored Bearer token into every outgoing request and, on any
/// 401 response, clears the stored token and notifies [AuthEventBus] so
/// the auth controller can transition to `AuthUnauthenticated` and the
/// router can redirect to `/login`.
///
/// Kept as a plain `Interceptor` (not `QueuedInterceptor`) — the auth
/// state transition is fire-and-forget; the failing request itself still
/// bubbles up as an `UnauthorizedException` for the caller to display.
class AuthInterceptor extends Interceptor {
  AuthInterceptor({required this.storage, required this.eventBus});

  final SecureStorageService storage;
  final AuthEventBus eventBus;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final token = await storage.readAuthToken();
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
    if (err.response?.statusCode == 401) {
      await storage.clearAuthToken();
      eventBus.emitUnauthorized();
    }
    handler.next(err);
  }
}
