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
  /// there is no valid stored session. Transient verification failures throw
  /// an [ApiException] while preserving both stored tokens.
  Future<AuthUser?> restoreSession();

  /// Runs the Google Sign-In flow, exchanges the id_token with the
  /// backend, saves the returned access/refresh token pair, and fetches the current
  /// user.
  Future<AuthUser> signInWithGoogle();

  /// Refetches the current user via `GET /users/me`. Used when a screen
  /// wants fresh profile data. Throws [UnauthorizedException] if the
  /// token is stale.
  Future<AuthUser> getCurrentUser();

  /// Revokes the refresh session, signs out of Google, and clears local tokens.
  Future<void> signOut();
}
