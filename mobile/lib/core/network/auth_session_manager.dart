import 'dart:async';

import 'package:dio/dio.dart';

import '../storage/secure_storage_service.dart';
import 'api_endpoints.dart';
import 'auth_event_bus.dart';

typedef UtcNow = DateTime Function();

/// Owns refresh-token rotation and guarantees one in-flight refresh per app.
class AuthSessionManager {
  factory AuthSessionManager({
    required Dio refreshDio,
    required SecureStorageService storage,
    required AuthEventBus eventBus,
    UtcNow? utcNow,
  }) {
    return AuthSessionManager._(
      refreshDio,
      storage,
      eventBus,
      utcNow ?? (() => DateTime.now().toUtc()),
    );
  }

  AuthSessionManager._(
    this._refreshDio,
    this._storage,
    this._eventBus,
    this._utcNow,
  );

  static const foregroundRefreshInterval = Duration(hours: 18);

  final Dio _refreshDio;
  final SecureStorageService _storage;
  final AuthEventBus _eventBus;
  final UtcNow _utcNow;
  Future<bool>? _refreshInFlight;

  Future<bool> refresh() {
    final existing = _refreshInFlight;
    if (existing != null) return existing;

    late final Future<bool> tracked;
    tracked = _performRefresh().whenComplete(() {
      if (identical(_refreshInFlight, tracked)) _refreshInFlight = null;
    });
    _refreshInFlight = tracked;
    return tracked;
  }

  Future<bool> refreshIfStale({
    Duration interval = foregroundRefreshInterval,
  }) async {
    final refreshToken = await _storage.readRefreshToken();
    if (refreshToken == null || refreshToken.isEmpty) return false;
    final lastRefresh = await _storage.readLastSuccessfulRefreshAt();
    if (lastRefresh != null && _utcNow().difference(lastRefresh) < interval) {
      return false;
    }
    return refresh();
  }

  Future<void> saveTokenPair({
    required String accessToken,
    required String refreshToken,
  }) {
    return _storage.saveTokenPair(
      accessToken: accessToken,
      refreshToken: refreshToken,
      refreshedAt: _utcNow(),
    );
  }

  Future<void> logout() async {
    final refreshToken = await _storage.readRefreshToken();
    if (refreshToken != null && refreshToken.isNotEmpty) {
      try {
        await _refreshDio.post<void>(
          ApiEndpoints.authLogout,
          data: {'refresh_token': refreshToken},
        );
      } catch (_) {
        // User-initiated logout is local-first; remote revocation is best-effort.
      }
    }
    await _storage.clearTokens();
  }

  Future<bool> _performRefresh() async {
    final refreshToken = await _storage.readRefreshToken();
    if (refreshToken == null || refreshToken.isEmpty) return false;
    try {
      final response = await _refreshDio.post<Map<String, dynamic>>(
        ApiEndpoints.authRefresh,
        data: {'refresh_token': refreshToken},
      );
      final data = response.data;
      final accessToken = data?['access_token'];
      final rotatedRefreshToken = data?['refresh_token'];
      if (accessToken is! String ||
          accessToken.isEmpty ||
          rotatedRefreshToken is! String ||
          rotatedRefreshToken.isEmpty) {
        return false;
      }
      await saveTokenPair(
        accessToken: accessToken,
        refreshToken: rotatedRefreshToken,
      );
      return true;
    } on DioException catch (error) {
      if (error.response?.statusCode == 401) {
        await _storage.clearTokens();
        _eventBus.emitUnauthorized();
      }
      return false;
    }
  }
}
