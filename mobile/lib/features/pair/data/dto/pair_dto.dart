import '../../../../core/network/api_exception.dart';

class PairDto {
  const PairDto({
    required this.pairId,
    required this.inviteCode,
    required this.members,
    required this.createdAt,
  });

  factory PairDto.fromJson(Map<String, dynamic> json) {
    final rawMembers = json['members'];
    if (rawMembers is! List) {
      throw const MalformedResponseException('pair members 格式异常');
    }
    try {
      return PairDto(
        pairId: json['pair_id'] as String,
        inviteCode: json['invite_code'] as String,
        members: rawMembers
            .map((member) => PairMemberDto.fromJson(member as Map<String, dynamic>))
            .toList(growable: false),
        createdAt: json['created_at'] as String,
      );
    } on TypeError catch (error) {
      throw MalformedResponseException('Pair 数据解析失败: $error');
    }
  }

  final String pairId;
  final String inviteCode;
  final List<PairMemberDto> members;
  final String createdAt;
}

class PairMemberDto {
  const PairMemberDto({
    required this.userId,
    required this.displayName,
    required this.avatarUrl,
  });

  factory PairMemberDto.fromJson(Map<String, dynamic> json) => PairMemberDto(
        userId: json['user_id'] as String,
        displayName: json['display_name'] as String?,
        avatarUrl: json['avatar_url'] as String?,
      );

  final String userId;
  final String? displayName;
  final String? avatarUrl;
}