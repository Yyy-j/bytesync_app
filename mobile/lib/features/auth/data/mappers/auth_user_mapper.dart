import '../../domain/auth_user.dart';
import '../dto/current_user_response_dto.dart';

/// Translates the wire DTO into the domain [AuthUser] and vice versa.
///
/// Purpose: isolate any schema drift on the backend to this one function
/// (and its DTO) — controllers and widgets never touch DTOs.
AuthUser mapCurrentUserResponseToAuthUser(CurrentUserResponseDto dto) {
  return AuthUser(
    id: dto.id,
    provider: dto.provider,
    email: dto.email,
    displayName: dto.displayName,
    avatarUrl: dto.avatarUrl,
  );
}
