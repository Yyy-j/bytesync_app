import '../domain/body_data.dart';
import '../../profile/domain/user_profile.dart';

abstract interface class BodyRepository {
  Future<BodyData> getBody();
  Future<List<WeightMeasurement>> getWeights({int limit = 30});
  Future<WeightMeasurement> createWeight({
    required DateTime measuredOn,
    required double weightKg,
  });
  Future<WeightMeasurement> updateWeight(
    String id, {
    required DateTime measuredOn,
    required double weightKg,
  });
  Future<void> deleteWeight(String id);
  Future<CalorieRecommendation> recommend(BodyInput input);
  Future<OnboardingResult> completeOnboarding(
    BodyInput input,
    NutritionGoals goals,
  );
}
