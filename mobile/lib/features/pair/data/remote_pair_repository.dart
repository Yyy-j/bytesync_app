import 'package:dio/dio.dart';

import '../../../core/network/api_endpoints.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/network/dio_error_mapper.dart';
import '../../auth/data/auth_repository.dart';
import '../domain/pair.dart';
import 'dto/pair_dto.dart';
import 'mappers/pair_mapper.dart';
import 'pair_repository.dart';

class RemotePairRepository implements PairRepository {
  RemotePairRepository({
    required this.dio,
    required this.errorMapper,
    required this.authRepository,
  });

  final Dio dio;
  final DioErrorMapper errorMapper;
  final AuthRepository authRepository;

  @override
  Future<Pair?> getCurrentPair() async {
    try {
      final response = await dio.get<Map<String, dynamic>>(ApiEndpoints.pairsMe);
      return await _map(response.data!);
    } on NotFoundException {
      return null;
    } catch (error) {
      throw errorMapper.map(error);
    }
  }

  @override
  Future<Pair> createPair() => _post(ApiEndpoints.pairs);

  @override
  Future<Pair> joinPair({required String inviteCode}) => _post(
        ApiEndpoints.pairsJoin,
        data: {'invite_code': inviteCode},
      );

  Future<Pair> _post(String path, {Map<String, dynamic>? data}) async {
    try {
      final response = await dio.post<Map<String, dynamic>>(path, data: data);
      return await _map(response.data!);
    } catch (error) {
      throw errorMapper.map(error);
    }
  }

  Future<Pair> _map(Map<String, dynamic> json) async {
    final user = await authRepository.getCurrentUser();
    return PairMapper.fromDto(
      PairDto.fromJson(json),
      currentUserId: user.id,
    );
  }
}