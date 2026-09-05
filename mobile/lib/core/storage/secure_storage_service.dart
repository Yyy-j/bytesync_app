import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Persists the auth token securely (Keychain on iOS, Keystore-backed
/// EncryptedSharedPreferences on Android).
///
/// Kept as a small dedicated service (rather than spreading
/// `flutter_secure_storage` calls across the auth feature) so the storage
/// mechanism can be swapped later without touching callers.
class SecureStorageService {
  SecureStorageService({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  static const _authTokenKey = 'auth_token';

  Future<String?> readAuthToken() => _storage.read(key: _authTokenKey);

  Future<void> saveAuthToken(String token) =>
      _storage.write(key: _authTokenKey, value: token);

  Future<void> clearAuthToken() => _storage.delete(key: _authTokenKey);
}
