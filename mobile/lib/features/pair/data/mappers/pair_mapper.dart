import 'package:bytesync/l10n/l10n.dart';

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
                displayName: member.displayName ?? appL10n.commonUnnamedMember,
                isSelf: member.userId == currentUserId,
              ),
            )
            .toList(growable: false),
        connectedAt: dto.connectedAt == null
            ? null
            : DateTime.parse(dto.connectedAt!),
        endedAt: dto.endedAt == null ? null : DateTime.parse(dto.endedAt!),
        createdAt: DateTime.parse(dto.createdAt),
      );
    } on FormatException catch (error) {
      throw MalformedResponseException('Pair 时间格式异常: $error');
    }
  }
}
