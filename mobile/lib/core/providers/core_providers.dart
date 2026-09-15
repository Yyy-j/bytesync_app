import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../network/auth_event_bus.dart';
import '../network/auth_session_manager.dart';
import '../network/dio_error_mapper.dart';
import '../network/dio_factory.dart';
import '../storage/secure_storage_service.dart';

/// Shared, cross-feature infrastructure. Every feature builds on top of
/// these providers instead of constructing its own [Dio] /
/// [SecureStorageService] / [DioErrorMapper].
final secureStorageServiceProvider = Provider<SecureStorageService>((ref) {
  return SecureStorageService();
});

final authEventBusProvider = Provider<AuthEventBus>((ref) {
  final bus = AuthEventBus();
  ref.onDispose(bus.dispose);
  return bus;
});

final refreshDioProvider = Provider<Dio>((ref) {
  return Dio(buildBaseOptions());
});

final authSessionManagerProvider = Provider<AuthSessionManager>((ref) {
  return AuthSessionManager(
    refreshDio: ref.watch(refreshDioProvider),
    storage: ref.watch(secureStorageServiceProvider),
    eventBus: ref.watch(authEventBusProvider),
  );
});

final dioProvider = Provider<Dio>((ref) {
  return buildDio(
    storage: ref.watch(secureStorageServiceProvider),
    sessionManager: ref.watch(authSessionManagerProvider),
  );
});

final dioErrorMapperProvider = Provider<DioErrorMapper>((ref) {
  return const DioErrorMapper();
});
