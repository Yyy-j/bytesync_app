class Pair {
  const Pair({
    required this.pairId,
    required this.inviteCode,
    required this.members,
    required this.createdAt,
  });

  final String pairId;
  final String inviteCode;
  final List<PairMember> members;
  final DateTime createdAt;

  PairMember? get currentMember {
    for (final member in members) {
      if (member.isSelf) return member;
    }
    return null;
  }

  PairMember? get partner {
    for (final member in members) {
      if (!member.isSelf) return member;
    }
    return null;
  }
}

class PairMember {
  const PairMember({
    required this.userId,
    required this.displayName,
    required this.avatarUrl,
    required this.isSelf,
  });

  final String userId;
  final String displayName;
  final String? avatarUrl;
  final bool isSelf;
}