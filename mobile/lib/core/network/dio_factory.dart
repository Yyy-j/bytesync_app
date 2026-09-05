import 'package:dio/dio.dart';

import '../config/app_config.dart';
import '../storage/secure_storage_service.dart';
import 'auth_event_bus.dart';
import 'auth_interceptor.dart';

/// Builds a configured [Dio] instance: base URL, timeouts, auth
/// interceptor.
///
/// Kept as a factory (not a class wrapper) so `Remote*Repository`s depend
/// directly on [Dio] and can be tested by injecting a Dio with a
/// swapped-in `httpClientAdapter`.
Dio buildDio({
  required SecureStorageService storage,
  required AuthEventBus authEventBus,
}) {
  final dio = Dio(
    BaseOptions(
      baseUrl: AppConfig.apiBaseUrl,
      connectTimeout: const Duration(milliseconds: AppConfig.connectTimeoutMs),
      receiveTimeout: const Duration(milliseconds: AppConfig.receiveTimeoutMs),
      contentType: 'application/json',
      responseType: ResponseType.json,
    ),
  );

  dio.interceptors.add(
    AuthInterceptor(storage: storage, eventBus: authEventBus),
  );

  return dio;
}
