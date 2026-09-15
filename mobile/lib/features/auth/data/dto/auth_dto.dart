import '../../../../core/network/api_exception.dart';

/// Wire shape of `POST /auth/google` request body.
class GoogleLoginRequestDto {
  const GoogleLoginRequestDto({required this.idToken});

  final String idToken;

  Map<String, dynamic> toJson() => {'id_token': idToken};
}

/// Wire shape of `POST /auth/google` response body.
class TokenPairResponseDto {
  const TokenPairResponseDto({
    required this.accessToken,
    required this.refreshToken,
    required this.tokenType,
  });

  factory TokenPairResponseDto.fromJson(Map<String, dynamic> json) {
    final accessToken = json['access_token'];
    if (accessToken is! String || accessToken.isEmpty) {
      throw const MalformedResponseException('缺少 access_token');
    }
    final refreshToken = json['refresh_token'];
    if (refreshToken is! String || refreshToken.isEmpty) {
      throw const MalformedResponseException('缺少 refresh_token');
    }
    final tokenType = json['token_type'];
    return TokenPairResponseDto(
      accessToken: accessToken,
      refreshToken: refreshToken,
      tokenType: tokenType is String ? tokenType : 'bearer',
    );
  }

  final String accessToken;
  final String refreshToken;
  final String tokenType;
}
