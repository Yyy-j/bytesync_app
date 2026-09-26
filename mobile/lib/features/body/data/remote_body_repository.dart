import 'package:dio/dio.dart';

import '../../../core/network/api_endpoints.dart';
import '../../../core/network/dio_error_mapper.dart';
import '../../../../core/network/api_exception.dart';
import 'dto/body_dtos.dart';
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
      final response = await _dio.get<Map<String, dynamic>>(
        ApiEndpoints.usersMeWeights,
        queryParameters: {'limit': limit},
      );
      final wrapper = response.data;
      if (wrapper == null) {
        throw MalformedResponseException('体重记录响应为空');
      }
      return WeightMeasurementsResponseDto.fromJson(wrapper).measurements
          .map((item) => item.toDomain())
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
      return WeightMeasurementDto.fromJson(_data(response)).toDomain();
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
      return WeightMeasurementDto.fromJson(_data(response)).toDomain();
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

  @override
  Future<CalorieRecommendation> recommend(BodyInput input) async {
    try {
      return RecommendationResponseDto.fromJson(
        _data(
          await _dio.post<Map<String, dynamic>>(
            ApiEndpoints.usersMeRecommendation,
            data: input.toJson(),
          ),
        ),
      ).toDomain();
    } catch (error) {
      throw _errorMapper.map(error);
    }
  }

  @override
  Future<OnboardingResult> completeOnboarding(
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
      return OnboardingResponseDto.fromJson(_data(response)).toDomain();
    } catch (error) {
      throw _errorMapper.map(error);
    }
  }
}
