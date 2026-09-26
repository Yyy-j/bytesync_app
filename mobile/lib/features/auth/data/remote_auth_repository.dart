import 'package:dio/dio.dart';

import '../../../core/network/api_endpoints.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/network/auth_session_manager.dart';
import '../../../core/network/dio_error_mapper.dart';
import '../../../core/storage/secure_storage_service.dart';
import '../domain/auth_user.dart';
import 'auth_repository.dart';
import 'dto/auth_dto.dart';
import 'dto/current_user_response_dto.dart';
import 'google_auth_client.dart';
import 'mappers/auth_user_mapper.dart';

/// Production [AuthRepository]. Talks to the real FastAPI backend via
/// [Dio] and to Google via [GoogleAuthClient]. No mock code path.
///
/// Flow:
/// ```
/// GoogleAuthClient.signIn → id_token
///   → POST /auth/google      → access_token + refresh_token
///   → secureStorage.save
///   → GET  /users/me         → AuthUser
/// ```
class RemoteAuthRepository implements AuthRepository {
  RemoteAuthRepository({
    required this.dio,
    required this.storage,
    required this.googleAuthClient,
    required this.errorMapper,
    required this.sessionManager,
  });

  final Dio dio;
  final SecureStorageService storage;
  final GoogleAuthClient googleAuthClient;
  final DioErrorMapper errorMapper;
  final AuthSessionManager sessionManager;

  @override
  Future<AuthUser?> restoreSession() async {
    final accessToken = await storage.readAccessToken();
    final refreshToken = await storage.readRefreshToken();
    if ((accessToken == null || accessToken.isEmpty) &&
        (refreshToken == null || refreshToken.isEmpty)) {
      return null;
    }
    try {
      return await getCurrentUser();
    } on UnauthorizedException {
      return null;
    } on ApiException {
      // A transient failure cannot prove that the persisted session expired.
      // Preserve both tokens and let AuthController expose a retryable state.
      rethrow;
    }
  }

  @override
  Future<AuthUser> signInWithGoogle() async {
    final googleResult = await googleAuthClient.signIn();
    try {
      final response = await dio.post<Map<String, dynamic>>(
        ApiEndpoints.authGoogle,
        data: GoogleLoginRequestDto(idToken: googleResult.idToken).toJson(),
      );
      final tokenDto = TokenPairResponseDto.fromJson(response.data!);
      await sessionManager.saveTokenPair(
        accessToken: tokenDto.accessToken,
        refreshToken: tokenDto.refreshToken,
      );

      final user = await getCurrentUser();

      // Best-effort: enrich the display name from the Google profile when
      // the backend doesn't return one. This is UI-only and gets lost on
      // cold restore (see `AuthUser` docstring).
      return user.copyWith(
        displayName: user.displayName ?? googleResult.displayName,
      );
    } on ApiException {
      rethrow;
    } catch (e) {
      throw errorMapper.map(e);
    }
  }

  @override
  Future<AuthUser> getCurrentUser() async {
    try {
      final response = await dio.get<Map<String, dynamic>>(
        ApiEndpoints.usersMe,
      );
      final dto = CurrentUserResponseDto.fromJson(response.data!);
      return mapCurrentUserResponseToAuthUser(dto);
    } on ApiException {
      rethrow;
    } catch (e) {
      throw errorMapper.map(e);
    }
  }

  @override
  Future<void> signOut() async {
    await sessionManager.logout();
    try {
      await googleAuthClient.signOut();
    } catch (_) {
      // Ignore — signing out of Google is best-effort.
    }
  }

  @override
  Future<void> deleteAccount() async {
    try {
      await dio.delete<void>(ApiEndpoints.usersMe);
    } catch (error) {
      throw errorMapper.map(error);
    }
    await sessionManager.logout();
    try {
      await googleAuthClient.signOut();
    } catch (_) {
      // Account deletion has already succeeded; Google sign-out is best-effort.
    }
  }
}
