import '../../profile/domain/user_profile.dart';

class CurrentWeight {
  const CurrentWeight({
    required this.measurementId,
    required this.measuredOn,
    required this.weightKg,
    required this.bmi,
  });

  final String measurementId;
  final DateTime measuredOn;
  final double weightKg;
  final double bmi;
}

class BodyData {
  const BodyData({
    required this.heightCm,
    required this.currentWeight,
    required this.targetWeightKg,
    required this.targetDate,
    required this.weightDifferenceKg,
  });

  final double? heightCm;
  final CurrentWeight? currentWeight;
  final double? targetWeightKg;
  final DateTime? targetDate;
  final double? weightDifferenceKg;

  bool get canRecommend =>
      heightCm != null && currentWeight != null && targetWeightKg != null;
}

class WeightMeasurement {
  const WeightMeasurement({
    required this.id,
    required this.measuredOn,
    required this.weightKg,
    required this.bmi,
  });

  final String id;
  final DateTime measuredOn;
  final double weightKg;
  final double bmi;
}

class CalorieRecommendation {
  const CalorieRecommendation({
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    this.aggressiveTimeline = false,
    this.recommendedTargetDate,
    this.requestedTargetDate,
    this.bmr,
    this.maintenanceCalories,
    this.method,
    this.direction,
  });

  final double calories;
  final double protein;
  final double carbs;
  final double fat;
  final bool aggressiveTimeline;
  final DateTime? recommendedTargetDate;
  final DateTime? requestedTargetDate;
  final double? bmr;
  final double? maintenanceCalories;
  final String? method;
  final String? direction;

  NutritionGoals get goals => NutritionGoals(
    calories: calories,
    protein: protein,
    carbs: carbs,
    fat: fat,
  );
}

class OnboardingResult {
  const OnboardingResult({
    required this.onboardingCompletedAt,
    required this.birthYear,
    required this.sexForEnergyEstimate,
    required this.heightCm,
    required this.targetWeightKg,
    required this.targetDate,
    required this.activityLevel,
    required this.goals,
    required this.currentWeight,
  });

  final DateTime onboardingCompletedAt;
  final int birthYear;
  final String sexForEnergyEstimate;
  final double heightCm;
  final double targetWeightKg;
  final DateTime targetDate;
  final String activityLevel;
  final NutritionGoals goals;
  final WeightMeasurement? currentWeight;
}

class BodyInput {
  const BodyInput({
    required this.birthYear,
    required this.sexForEnergyEstimate,
    required this.heightCm,
    required this.currentWeightKg,
    required this.targetWeightKg,
    required this.targetDate,
    required this.activityLevel,
  });

  final int birthYear;
  final String sexForEnergyEstimate;
  final double heightCm;
  final double currentWeightKg;
  final double targetWeightKg;
  final DateTime targetDate;
  final String activityLevel;

  Map<String, dynamic> toJson() => {
    'birth_year': birthYear,
    'sex_for_energy_estimate': sexForEnergyEstimate,
    'height_cm': heightCm,
    'current_weight_kg': currentWeightKg,
    'target_weight_kg': targetWeightKg,
    'target_date': targetDate.toIso8601String().split('T').first,
    'activity_level': activityLevel,
  };
}
