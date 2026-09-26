import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bytesync/core/network/dio_error_mapper.dart';
import 'package:bytesync/features/auth/data/auth_repository.dart';
import 'package:bytesync/features/auth/domain/auth_user.dart';
import 'package:bytesync/features/pair/data/dto/pair_dto.dart';
import 'package:bytesync/features/pair/data/mappers/pair_mapper.dart';
import 'package:bytesync/features/pair/data/remote_pair_repository.dart';
import 'package:bytesync/features/pair/domain/pair.dart';

final _user = AuthUser(
  id: 'user-1',
  provider: 'google',
  email: 'one@example.com',
);

class _FakeAuthRepository implements AuthRepository {
  @override
  Future<AuthUser?> restoreSession() async => _user;

  @override
  Future<AuthUser> signInWithGoogle() async => _user;

  @override
  Future<AuthUser> getCurrentUser() async => _user;

  @override
  Future<void> signOut() async {}

  @override
  Future<void> deleteAccount() async {}
}

class _NotFoundAdapter implements HttpClientAdapter {
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async =>
      ResponseBody.fromString('{"detail":"Current pair not found"}', 404);

  @override
  void close({bool force = false}) {}
}

Map<String, dynamic> _pairJson({
  required List<Map<String, dynamic>> members,
  String? connectedAt,
  String? endedAt,
}) => {
  'pair_id': 'pair-1',
  'invite_code': 'ABC123',
  'members': members,
  'created_at': '2026-09-20T12:00:00Z',
  'connected_at': connectedAt,
  'ended_at': endedAt,
};

Pair _mapPair(Map<String, dynamic> json) =>
    PairMapper.fromDto(PairDto.fromJson(json), currentUserId: 'user-1');

void main() {
  test('GET /pairs/me 404 is the normal Single state', () async {
    final dio = Dio()..httpClientAdapter = _NotFoundAdapter();
    final repository = RemotePairRepository(
      dio: dio,
      errorMapper: const DioErrorMapper(),
      authRepository: _FakeAuthRepository(),
    );

    expect(await repository.getCurrentPair(), isNull);
  });

  test('one member without lifecycle timestamps is Pending', () {
    final pair = _mapPair(
      _pairJson(
        members: [
          {'user_id': 'user-1', 'display_name': 'One'},
        ],
      ),
    );

    expect(pair.isPending, isTrue);
    expect(pair.isConnected, isFalse);
    expect(pair.partner, isNull);
  });

  test('two members with connected_at and no ended_at is Connected', () {
    final pair = _mapPair(
      _pairJson(
        members: [
          {'user_id': 'user-1', 'display_name': 'One'},
          {'user_id': 'user-2', 'display_name': 'Two'},
        ],
        connectedAt: '2026-09-21T12:00:00Z',
      ),
    );

    expect(pair.isPending, isFalse);
    expect(pair.isConnected, isTrue);
    expect(pair.connectedAt, DateTime.parse('2026-09-21T12:00:00Z'));
    expect(pair.endedAt, isNull);
    expect(pair.partner?.displayName, 'Two');
  });
}
