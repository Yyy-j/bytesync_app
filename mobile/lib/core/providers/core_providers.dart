import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../network/auth_event_bus.dart';
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

final dioProvider = Provider<Dio>((ref) {
  return buildDio(
    storage: ref.watch(secureStorageServiceProvider),
    authEventBus: ref.watch(authEventBusProvider),
  );
});

final dioErrorMapperProvider = Provider<DioErrorMapper>((ref) {
  return const DioErrorMapper();
});
