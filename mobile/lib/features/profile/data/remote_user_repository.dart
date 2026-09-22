import 'package:dio/dio.dart';

import '../../../core/network/api_endpoints.dart';
import '../../../core/network/dio_error_mapper.dart';
import '../domain/user_character.dart';
import '../domain/user_profile.dart';
import 'dto/user_profile_dto.dart';
import 'user_repository.dart';

class RemoteUserRepository implements UserRepository {
  RemoteUserRepository(this._dio, this._errorMapper);

  final Dio _dio;
  final DioErrorMapper _errorMapper;

  @override
  Future<UserProfile> getProfile() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        ApiEndpoints.usersMe,
      );
      return UserProfileDto.fromJson(response.data!).toDomain();
    } catch (error) {
      throw _errorMapper.map(error);
    }
  }

  @override
  Future<UserProfile> updateNutritionGoals(NutritionGoals goals) async {
    try {
      final response = await _dio.patch<Map<String, dynamic>>(
        ApiEndpoints.usersMe,
        data: UpdateNutritionGoalsRequestDto(goals).toJson(),
      );
      return UserProfileDto.fromJson(response.data!).toDomain();
    } catch (error) {
      throw _errorMapper.map(error);
    }
  }

  @override
  Future<UserProfile> updateProfile({required String? displayName}) async {
    try {
      final response = await _dio.patch<Map<String, dynamic>>(
        ApiEndpoints.usersMe,
        data: UpdateUserProfileRequestDto(displayName: displayName).toJson(),
      );
      return UserProfileDto.fromJson(response.data!).toDomain();
    } catch (error) {
      throw _errorMapper.map(error);
    }
  }

  @override
  Future<UserProfile> updateCharacter(UserCharacter character) async {
    try {
      final response = await _dio.patch<Map<String, dynamic>>(
        ApiEndpoints.usersMe,
        data: UpdateUserCharacterRequestDto(character).toJson(),
      );
      return UserProfileDto.fromJson(response.data!).toDomain();
    } catch (error) {
      throw _errorMapper.map(error);
    }
  }
}
