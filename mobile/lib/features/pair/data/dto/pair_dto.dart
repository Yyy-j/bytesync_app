import '../../../../core/network/api_exception.dart';
import '../../../profile/domain/user_character.dart';

class PairDto {
  const PairDto({
    required this.pairId,
    required this.inviteCode,
    required this.members,
    required this.createdAt,
    required this.connectedAt,
    required this.endedAt,
  });

  factory PairDto.fromJson(Map<String, dynamic> json) {
    final rawMembers = json['members'];
    if (rawMembers is! List) {
      throw MalformedResponseException('pair members 格式异常');
    }
    try {
      return PairDto(
        pairId: json['pair_id'] as String,
        inviteCode: json['invite_code'] as String,
        members: rawMembers
            .map(
              (member) =>
                  PairMemberDto.fromJson(member as Map<String, dynamic>),
            )
            .toList(growable: false),
        createdAt: json['created_at'] as String,
        connectedAt: json['connected_at'] as String?,
        endedAt: json['ended_at'] as String?,
      );
    } on TypeError catch (error) {
      throw MalformedResponseException('Pair 数据解析失败: $error');
    }
  }

  final String pairId;
  final String inviteCode;
  final List<PairMemberDto> members;
  final String createdAt;
  final String? connectedAt;
  final String? endedAt;
}

class PairMemberDto {
  const PairMemberDto({
    required this.userId,
    required this.displayName,
    required this.character,
  });

  factory PairMemberDto.fromJson(Map<String, dynamic> json) => PairMemberDto(
    userId: json['user_id'] as String,
    displayName: json['display_name'] as String?,
    character: UserCharacter.fromWire(json['character']),
  );

  final String userId;
  final String? displayName;
  final UserCharacter character;
}
