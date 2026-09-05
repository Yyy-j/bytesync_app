import '../../../../core/network/api_exception.dart';
import '../../domain/pair.dart';
import '../dto/pair_dto.dart';

class PairMapper {
  const PairMapper._();

  static Pair fromDto(PairDto dto, {required String currentUserId}) {
    try {
      return Pair(
        pairId: dto.pairId,
        inviteCode: dto.inviteCode,
        members: dto.members
            .map(
              (member) => PairMember(
                userId: member.userId,
                displayName: member.displayName ?? '未命名成员',
                avatarUrl: member.avatarUrl,
                isSelf: member.userId == currentUserId,
              ),
            )
            .toList(growable: false),
        createdAt: DateTime.parse(dto.createdAt),
      );
    } on FormatException catch (error) {
      throw MalformedResponseException('Pair 时间格式异常: $error');
    }
  }
}