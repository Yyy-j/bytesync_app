import 'package:flutter_test/flutter_test.dart';

import 'package:bytesync/features/auth/data/dto/current_user_response_dto.dart';
import 'package:bytesync/features/body/domain/body_data.dart';
import 'package:bytesync/features/profile/domain/user_profile.dart';

void main() {
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
}
