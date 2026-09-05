import '../domain/auth_user.dart';

/// UI-facing auth operations. The login page, the router, and every
/// other feature only depend on this interface — never on `Dio`,
/// `google_sign_in`, DTOs, or the concrete impl.
///
/// Implementations must:
/// - throw a typed [ApiException] subclass on failure (never a
///   [DioException]);
/// - never depend on any repository from another feature.
abstract interface class AuthRepository {
  /// Restores a previous session from secure storage. Returns `null` if
  /// there is no valid stored session. Never throws — network failures
  /// clear the local token and return `null`.
  Future<AuthUser?> restoreSession();

  /// Runs the Google Sign-In flow, exchanges the id_token with the
  /// backend, saves the returned access token, and fetches the current
  /// user.
  Future<AuthUser> signInWithGoogle();

  /// Refetches the current user via `GET /users/me`. Used when a screen
  /// wants fresh profile data. Throws [UnauthorizedException] if the
  /// token is stale.
  Future<AuthUser> getCurrentUser();

  /// Signs out of Google, clears the local access token. Idempotent.
  Future<void> signOut();
}
