import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Persists auth session data securely (Keychain on iOS, Keystore-backed
/// EncryptedSharedPreferences on Android).
///
/// Kept as a small dedicated service (rather than spreading
/// `flutter_secure_storage` calls across the auth feature) so the storage
/// mechanism can be swapped later without touching callers.
class SecureStorageService {
  SecureStorageService({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  static const _accessTokenKey = 'access_token';
  static const _refreshTokenKey = 'refresh_token';
  static const _lastRefreshAtKey = 'last_successful_refresh_at';
  static const _legacyAuthTokenKey = 'auth_token';

  Future<String?> readAccessToken() async {
    final token = await _storage.read(key: _accessTokenKey);
    if (token != null) return token;
    return _storage.read(key: _legacyAuthTokenKey);
  }

  Future<String?> readRefreshToken() => _storage.read(key: _refreshTokenKey);

  Future<DateTime?> readLastSuccessfulRefreshAt() async {
    final value = await _storage.read(key: _lastRefreshAtKey);
    return value == null ? null : DateTime.tryParse(value)?.toUtc();
  }

  Future<void> saveTokenPair({
    required String accessToken,
    required String refreshToken,
    required DateTime refreshedAt,
  }) async {
    await _storage.write(key: _refreshTokenKey, value: refreshToken);
    await _storage.write(key: _accessTokenKey, value: accessToken);
    await _storage.write(
      key: _lastRefreshAtKey,
      value: refreshedAt.toUtc().toIso8601String(),
    );
    await _storage.delete(key: _legacyAuthTokenKey);
  }

  Future<void> clearTokens() async {
    await _storage.delete(key: _accessTokenKey);
    await _storage.delete(key: _refreshTokenKey);
    await _storage.delete(key: _lastRefreshAtKey);
    await _storage.delete(key: _legacyAuthTokenKey);
  }
}
