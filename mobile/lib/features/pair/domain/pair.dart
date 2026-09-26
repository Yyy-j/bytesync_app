class Pair {
  const Pair({
    required this.pairId,
    required this.inviteCode,
    required this.members,
    required this.createdAt,
    this.connectedAt,
    this.endedAt,
  });

  final String pairId;
  final String inviteCode;
  final List<PairMember> members;
  final DateTime createdAt;
  final DateTime? connectedAt;
  final DateTime? endedAt;

  bool get isPending =>
      members.length == 1 && connectedAt == null && endedAt == null;

  bool get isConnected =>
      members.length == 2 && connectedAt != null && endedAt == null;

  PairMember? get currentMember {
    for (final member in members) {
      if (member.isSelf) return member;
    }
    return null;
  }

  PairMember? get partner {
    if (!isConnected) return null;
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
    required this.isSelf,
  });

  final String userId;
  final String displayName;
  final bool isSelf;
}
