import '../../../../core/network/api_exception.dart';

/// Wire shape of `GET /users/me` response body.
///
/// See `API_CONTRACT.md` §1.3. Note that [email] is nullable per the
/// current backend, and neither `display_name` nor `avatar_url` is
/// currently returned.
class CurrentUserResponseDto {
  const CurrentUserResponseDto({
    required this.id,
    required this.provider,
    this.email,
    this.displayName,
    this.avatarUrl,
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
      // Not part of the current backend schema, but tolerated if added.
      displayName: json['display_name'] as String?,
      avatarUrl: json['avatar_url'] as String?,
    );
  }

  final String id;
  final String provider;
  final String? email;
  final String? displayName;
  final String? avatarUrl;
}
