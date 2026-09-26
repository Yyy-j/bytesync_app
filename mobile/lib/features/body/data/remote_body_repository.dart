import 'package:dio/dio.dart';

import '../../../core/network/api_endpoints.dart';
import '../../../core/network/dio_error_mapper.dart';
import '../../profile/data/dto/user_profile_dto.dart';
import '../../profile/domain/user_profile.dart';
import '../domain/body_data.dart';
import 'body_repository.dart';

class RemoteBodyRepository implements BodyRepository {
  RemoteBodyRepository(this._dio, this._errorMapper);
  final Dio _dio;
  final DioErrorMapper _errorMapper;

  Map<String, dynamic> _data(Response<Map<String, dynamic>> response) =>
      response.data!;

  DateTime? _date(Object? value) =>
      value is String ? DateTime.tryParse(value) : null;

  WeightMeasurement _weight(Map<String, dynamic> json) => WeightMeasurement(
    id: json['measurement_id'] as String? ?? json['id'] as String,
    measuredOn: _date(json['measured_on'])!,
    weightKg: (json['weight_kg'] as num).toDouble(),
    bmi: (json['bmi'] as num).toDouble(),
  );

  @override
  Future<BodyData> getBody() async {
    try {
      final json = _data(
        await _dio.get<Map<String, dynamic>>(ApiEndpoints.usersMeBody),
      );
      final current = json['current_weight'] as Map<String, dynamic>?;
      return BodyData(
        heightCm: (json['height_cm'] as num?)?.toDouble(),
        currentWeight: current == null
            ? null
            : CurrentWeight(
                measurementId: current['measurement_id'] as String,
                measuredOn: _date(current['measured_on'])!,
                weightKg: (current['weight_kg'] as num).toDouble(),
                bmi: (current['bmi'] as num).toDouble(),
              ),
        targetWeightKg: (json['target_weight_kg'] as num?)?.toDouble(),
        targetDate: _date(json['target_date']),
        weightDifferenceKg: (json['weight_difference_kg'] as num?)?.toDouble(),
      );
    } catch (error) {
      throw _errorMapper.map(error);
    }
  }

  @override
  Future<List<WeightMeasurement>> getWeights({int limit = 30}) async {
    try {
      final response = await _dio.get<List<dynamic>>(
        ApiEndpoints.usersMeWeights,
        queryParameters: {'limit': limit},
      );
      return (response.data ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(_weight)
          .toList();
    } catch (error) {
      throw _errorMapper.map(error);
    }
  }

  @override
  Future<WeightMeasurement> createWeight({
    required DateTime measuredOn,
    required double weightKg,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        ApiEndpoints.usersMeWeights,
        data: {
          'measured_on': measuredOn.toIso8601String().split('T').first,
          'weight_kg': weightKg,
        },
      );
      return _weight(_data(response));
    } catch (error) {
      throw _errorMapper.map(error);
    }
  }

  @override
  Future<WeightMeasurement> updateWeight(
    String id, {
    required DateTime measuredOn,
    required double weightKg,
  }) async {
    try {
      final response = await _dio.patch<Map<String, dynamic>>(
        ApiEndpoints.usersMeWeight(id),
        data: {
          'measured_on': measuredOn.toIso8601String().split('T').first,
          'weight_kg': weightKg,
        },
      );
      return _weight(_data(response));
    } catch (error) {
      throw _errorMapper.map(error);
    }
  }

  @override
  Future<void> deleteWeight(String id) async {
    try {
      await _dio.delete<void>(ApiEndpoints.usersMeWeight(id));
    } catch (error) {
      throw _errorMapper.map(error);
    }
  }

  CalorieRecommendation _recommendation(Map<String, dynamic> json) =>
      CalorieRecommendation(
        calories:
            (json['calories'] ?? (json['goals'] as Map?)?['calories'] as num)
                .toDouble(),
        protein: (json['protein'] ?? (json['goals'] as Map?)?['protein'] as num)
            .toDouble(),
        carbs: (json['carbs'] ?? (json['goals'] as Map?)?['carbs'] as num)
            .toDouble(),
        fat: (json['fat'] ?? (json['goals'] as Map?)?['fat'] as num).toDouble(),
        aggressiveTimeline: json['aggressive_timeline'] as bool? ?? false,
        recommendedTargetDate: _date(json['recommended_target_date']),
        requestedTargetDate: _date(json['requested_target_date']),
        bmr: (json['bmr'] as num?)?.toDouble(),
        maintenanceCalories: (json['maintenance_calories'] as num?)?.toDouble(),
        method: json['method'] as String?,
      );

  @override
  Future<CalorieRecommendation> recommend(BodyInput input) async {
    try {
      return _recommendation(
        _data(
          await _dio.post<Map<String, dynamic>>(
            ApiEndpoints.usersMeRecommendation,
            data: input.toJson(),
          ),
        ),
      );
    } catch (error) {
      throw _errorMapper.map(error);
    }
  }

  @override
  Future<UserProfile> completeOnboarding(
    BodyInput input,
    NutritionGoals goals,
  ) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        ApiEndpoints.usersMeOnboarding,
        data: {
          ...input.toJson(),
          'goals': {
            'calories': goals.calories,
            'protein': goals.protein,
            'carbs': goals.carbs,
            'fat': goals.fat,
          },
        },
      );
      return UserProfileDto.fromJson(_data(response)).toDomain();
    } catch (error) {
      throw _errorMapper.map(error);
    }
  }
}
