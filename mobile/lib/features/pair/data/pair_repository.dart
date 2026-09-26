import '../domain/pair.dart';

abstract interface class PairRepository {
  Future<Pair?> getCurrentPair();

  Future<Pair> createPair();

  Future<Pair> joinPair({required String inviteCode});

  Future<Pair> regenerateInviteCode();

  Future<void> cancelPair();

  Future<void> endPair();
}
