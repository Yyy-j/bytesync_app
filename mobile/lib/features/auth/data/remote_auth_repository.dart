import 'package:dio/dio.dart';

import '../../../core/network/api_endpoints.dart';
import '../../../core/network/api_exception.dart';
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
///   → POST /auth/google      → access_token
///   → secureStorage.save
///   → GET  /users/me         → AuthUser
/// ```
class RemoteAuthRepository implements AuthRepository {
  RemoteAuthRepository({
    required this.dio,
    required this.storage,
    required this.googleAuthClient,
    required this.errorMapper,
  });

  final Dio dio;
  final SecureStorageService storage;
  final GoogleAuthClient googleAuthClient;
  final DioErrorMapper errorMapper;

  @override
  Future<AuthUser?> restoreSession() async {
    final token = await storage.readAuthToken();
    if (token == null || token.isEmpty) return null;
    try {
      return await getCurrentUser();
    } on UnauthorizedException {
      await storage.clearAuthToken();
      return null;
    } on ApiException {
      // Network / server error on cold start: don't clear the token
      // (user still owns the session); just surface no user for now.
      // AuthController will treat as unauthenticated for this launch.
      return null;
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
      final tokenDto = AccessTokenResponseDto.fromJson(response.data!);
      await storage.saveAuthToken(tokenDto.accessToken);

      final user = await getCurrentUser();

      // Best-effort: enrich with Google-side profile when the backend
      // doesn't return display_name / avatar_url. This is UI-only and
      // gets lost on cold restore (see `AuthUser` docstring).
      return user.copyWith(
        displayName: user.displayName ?? googleResult.displayName,
        avatarUrl: user.avatarUrl ?? googleResult.photoUrl,
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
    try {
      await googleAuthClient.signOut();
    } catch (_) {
      // Ignore — signing out of Google is best-effort.
    }
    await storage.clearAuthToken();
  }
}
