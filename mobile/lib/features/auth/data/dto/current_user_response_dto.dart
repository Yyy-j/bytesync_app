import '../../../../core/network/api_exception.dart';

/// Wire shape of `GET /users/me` response body.
///
/// This auth-specific parser intentionally ignores the `goals` object.
/// Profile and nutrition-goal screens use their own DTO because the goal
/// keys differ from `GET /summary/daily`.
class CurrentUserResponseDto {
  const CurrentUserResponseDto({
    required this.id,
    required this.provider,
    this.email,
    this.displayName,
  });

  factory CurrentUserResponseDto.fromJson(Map<String, dynamic> json) {
    final id = json['id'];
    if (id is! String || id.isEmpty) {
      throw const MalformedResponseException('缺少用户 id');
    }
    final provider = json['provider'];
    if (provider is! String || provider.isEmpty) {
      throw const MalformedResponseException('缺少 provider');
    }
    return CurrentUserResponseDto(
      id: id,
      provider: provider,
      email: json['email'] as String?,
      displayName: json['display_name'] as String?,
    );
  }

  final String id;
  final String provider;
  final String? email;
  final String? displayName;
}
