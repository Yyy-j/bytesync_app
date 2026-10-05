import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bytesync/core/network/dio_error_mapper.dart';
import 'package:bytesync/core/network/api_exception.dart';
import 'package:bytesync/features/auth/data/dto/current_user_response_dto.dart';
import 'package:bytesync/features/body/data/remote_body_repository.dart';
import 'package:bytesync/features/body/domain/body_validation.dart';
import 'package:bytesync/features/body/domain/body_data.dart';
import 'package:bytesync/features/profile/domain/user_profile.dart';

typedef _Handler = FutureOr<ResponseBody> Function(RequestOptions options);

class _Adapter implements HttpClientAdapter {
  _Adapter(this.handler);

  final _Handler handler;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async => handler(options);

  @override
  void close({bool force = false}) {}
}

ResponseBody _json(Map<String, dynamic> body, {int statusCode = 200}) =>
    ResponseBody.fromString(
      jsonEncode(body),
      statusCode,
      headers: {
        Headers.contentTypeHeader: ['application/json'],
      },
    );

void main() {
  test('recommendation 404 has endpoint-specific guidance', () async {
    late String requestedPath;
    final dio = Dio()
      ..httpClientAdapter = _Adapter((options) {
        requestedPath = options.path;
        return _json({'detail': 'Not Found'}, statusCode: 404);
      });
    final repository = RemoteBodyRepository(dio, const DioErrorMapper());

    await expectLater(
      repository.recommend(
        BodyInput(
          birthYear: 1998,
          sexForEnergyEstimate: 'male',
          heightCm: 170,
          currentWeightKg: 63,
          targetWeightKg: 58,
          targetDate: DateTime(2027, 1, 1),
          activityLevel: 'moderate',
        ),
      ),
      throwsA(
        isA<NotFoundException>()
            .having(
              (error) => error.message,
              'message',
              contains('当前服务器暂不支持热量推荐'),
            )
            .having((error) => error.message, 'raw detail', isNot('Not Found')),
      ),
    );
    expect(requestedPath, '/users/me/calorie-recommendation');
  });

  test('current user DTO accepts nullable Phase 3 fields', () {
    final dto = CurrentUserResponseDto.fromJson({
      'id': 'user-1',
      'email': 'one@example.com',
      'provider': 'google',
      'display_name': 'Me',
      'onboarding_completed_at': '2026-09-27T00:00:00Z',
      'birth_year': 1998,
      'sex_for_energy_estimate': 'male',
      'height_cm': 170,
      'target_weight_kg': 58,
      'target_date': '2027-01-01',
      'activity_level': 'moderate',
    });

    expect(dto.onboardingCompletedAt, isNotNull);
    expect(dto.birthYear, 1998);
    expect(dto.heightCm, 170);
    expect(dto.targetDate, DateTime.parse('2027-01-01'));
  });

  test('completed grandfathered user may have all body fields null', () {
    final dto = CurrentUserResponseDto.fromJson({
      'id': 'user-1',
      'provider': 'google',
      'onboarding_completed_at': '2026-09-27T00:00:00Z',
      'birth_year': null,
      'sex_for_energy_estimate': null,
      'height_cm': null,
      'target_weight_kg': null,
      'target_date': null,
      'activity_level': null,
    });

    expect(dto.onboardingCompletedAt, isNotNull);
    expect(dto.heightCm, isNull);
    expect(dto.targetWeightKg, isNull);
  });

  test('recommendation exposes suggested goals and aggressive timeline', () {
    const recommendation = CalorieRecommendation(
      calories: 1850,
      protein: 110,
      carbs: 220,
      fat: 55,
      aggressiveTimeline: true,
      method: 'mifflin_st_jeor',
    );

    expect(recommendation.goals, isA<NutritionGoals>());
    expect(recommendation.goals.calories, 1850);
    expect(recommendation.aggressiveTimeline, isTrue);
    expect(recommendation.method, 'mifflin_st_jeor');
  });

  test('body data keeps backend BMI and does not recalculate it', () {
    final data = BodyData(
      heightCm: 180,
      currentWeight: CurrentWeight(
        measurementId: 'measurement-1',
        measuredOn: DateTime(2026, 9, 27),
        weightKg: 80,
        bmi: 21.9,
      ),
      targetWeightKg: 75,
      targetDate: DateTime(2026, 12, 31),
      weightDifferenceKg: -5,
    );

    expect(data.currentWeight!.bmi, 21.9);
    expect(data.weightDifferenceKg, -5);
  });

  test('weight repository parses the final measurements wrapper', () async {
    final dio = Dio()
      ..httpClientAdapter = _Adapter(
        (_) => _json({
          'measurements': [
            {
              'id': 'weight-1',
              'measured_on': '2026-09-27',
              'weight_kg': 63.2,
              'height_cm_snapshot': 170,
              'bmi': 21.9,
              'created_at': '2026-09-27T00:00:00Z',
              'updated_at': '2026-09-27T00:00:00Z',
            },
          ],
        }),
      );
    final repository = RemoteBodyRepository(dio, const DioErrorMapper());

    final measurements = await repository.getWeights();

    expect(measurements, hasLength(1));
    expect(measurements.single.id, 'weight-1');
    expect(measurements.single.measuredOn, DateTime(2026, 9, 27));
    expect(measurements.single.weightKg, 63.2);
    expect(measurements.single.bmi, 21.9);
  });

  test(
    'recommendation repository parses final recommended_goals JSON',
    () async {
      final dio = Dio()
        ..httpClientAdapter = _Adapter(
          (_) => _json({
            'method': 'mifflin_st_jeor_v1',
            'direction': 'lose',
            'bmr': 1558,
            'maintenance_calories': 2414,
            'recommended_calories': 2013,
            'requested_target_date': '2027-01-01',
            'recommended_target_date': '2027-01-01',
            'aggressive_timeline': false,
            'recommended_goals': {
              'calories': 2013,
              'protein': 113,
              'carbs': 264,
              'fat': 56,
            },
          }),
        );
      final repository = RemoteBodyRepository(dio, const DioErrorMapper());

      final result = await repository.recommend(
        BodyInput(
          birthYear: 1998,
          sexForEnergyEstimate: 'male',
          heightCm: 170,
          currentWeightKg: 63,
          targetWeightKg: 58,
          targetDate: DateTime(2027, 1, 1),
          activityLevel: 'moderate',
        ),
      );

      expect(result.method, 'mifflin_st_jeor_v1');
      expect(result.direction, 'lose');
      expect(result.bmr, 1558);
      expect(result.maintenanceCalories, 2414);
      expect(result.calories, 2013);
      expect(result.protein, 113);
      expect(result.carbs, 264);
      expect(result.fat, 56);
      expect(result.requestedTargetDate, DateTime(2027, 1, 1));
      expect(result.recommendedTargetDate, DateTime(2027, 1, 1));
      expect(result.aggressiveTimeline, isFalse);
    },
  );

  test(
    'onboarding repository maps independent response DTO to result',
    () async {
      final dio = Dio()
        ..httpClientAdapter = _Adapter(
          (_) => _json({
            'onboarding_completed_at': '2026-09-27T00:00:00Z',
            'birth_year': 1998,
            'sex_for_energy_estimate': 'male',
            'height_cm': 170,
            'target_weight_kg': 58,
            'target_date': '2027-01-01',
            'activity_level': 'moderate',
            'goals': {
              'calories': 2013,
              'protein': 113,
              'carbs': 264,
              'fat': 56,
            },
            'current_weight': {
              'id': 'weight-1',
              'measured_on': '2026-09-27',
              'weight_kg': 63.2,
              'bmi': 21.9,
            },
          }),
        );
      final repository = RemoteBodyRepository(dio, const DioErrorMapper());
      final input = BodyInput(
        birthYear: 1998,
        sexForEnergyEstimate: 'male',
        heightCm: 170,
        currentWeightKg: 63.2,
        targetWeightKg: 58,
        targetDate: DateTime(2027, 1, 1),
        activityLevel: 'moderate',
      );

      final result = await repository.completeOnboarding(
        input,
        const NutritionGoals(calories: 2013, protein: 113, carbs: 264, fat: 56),
      );

      expect(result, isA<OnboardingResult>());
      expect(result.goals.calories, 2013);
      expect(result.currentWeight?.id, 'weight-1');
      expect(
        result.onboardingCompletedAt,
        DateTime.parse('2026-09-27T00:00:00Z'),
      );
    },
  );

  test('goal timeline blocks changing weight on today and allows maintain', () {
    final today = DateTime(2026, 9, 27, 23, 59);

    expect(
      isValidGoalTimeline(
        currentWeight: 63,
        targetWeight: 58,
        targetDate: DateTime(2026, 9, 27, 12),
        today: today,
      ),
      isFalse,
    );
    expect(
      isValidGoalTimeline(
        currentWeight: 63,
        targetWeight: 63,
        targetDate: DateTime(2026, 9, 27),
        today: today,
      ),
      isTrue,
    );
    expect(
      isValidGoalTimeline(
        currentWeight: 63,
        targetWeight: 58,
        targetDate: DateTime(2026, 9, 28),
        today: today,
      ),
      isTrue,
    );
  });
}
