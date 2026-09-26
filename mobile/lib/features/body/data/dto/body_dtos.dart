import '../../../../core/network/api_exception.dart';
import '../../domain/body_data.dart';
import '../../../profile/domain/user_profile.dart';

DateTime _requiredDate(Object? value, String field) {
  if (value is String) {
    final date = DateTime.tryParse(value);
    if (date != null) return date;
  }
  throw MalformedResponseException('缺少有效的 $field');
}

double _number(Object? value, String field) {
  if (value is num) return value.toDouble();
  throw MalformedResponseException('缺少有效的 $field');
}

class WeightMeasurementsResponseDto {
  const WeightMeasurementsResponseDto(this.measurements);

  factory WeightMeasurementsResponseDto.fromJson(Map<String, dynamic> json) {
    final raw = json['measurements'];
    if (raw is! List) {
      throw MalformedResponseException('体重记录响应格式异常');
    }
    return WeightMeasurementsResponseDto(
      raw.map((item) => WeightMeasurementDto.fromJson(item)).toList(),
    );
  }

  final List<WeightMeasurementDto> measurements;
}

class WeightMeasurementDto {
  const WeightMeasurementDto({
    required this.id,
    required this.measuredOn,
    required this.weightKg,
    required this.bmi,
  });

  factory WeightMeasurementDto.fromJson(Object? value) {
    if (value is! Map<String, dynamic>) {
      throw MalformedResponseException('体重记录格式异常');
    }
    final id = value['id'];
    if (id is! String || id.isEmpty) {
      throw MalformedResponseException('缺少体重记录 id');
    }
    return WeightMeasurementDto(
      id: id,
      measuredOn: _requiredDate(value['measured_on'], '记录日期'),
      weightKg: _number(value['weight_kg'], '体重'),
      bmi: _number(value['bmi'], 'BMI'),
    );
  }

  final String id;
  final DateTime measuredOn;
  final double weightKg;
  final double bmi;

  WeightMeasurement toDomain() => WeightMeasurement(
    id: id,
    measuredOn: measuredOn,
    weightKg: weightKg,
    bmi: bmi,
  );
}

class RecommendationResponseDto {
  const RecommendationResponseDto({
    required this.recommendedGoals,
    required this.method,
    required this.direction,
    required this.bmr,
    required this.maintenanceCalories,
    required this.requestedTargetDate,
    required this.recommendedTargetDate,
    required this.aggressiveTimeline,
  });

  factory RecommendationResponseDto.fromJson(Map<String, dynamic> json) {
    final goals = json['recommended_goals'];
    if (goals is! Map<String, dynamic>) {
      throw MalformedResponseException('推荐目标响应格式异常');
    }
    return RecommendationResponseDto(
      recommendedGoals: NutritionGoals(
        calories: _number(goals['calories'], '推荐热量'),
        protein: _number(goals['protein'], '推荐蛋白质'),
        carbs: _number(goals['carbs'], '推荐碳水'),
        fat: _number(goals['fat'], '推荐脂肪'),
      ),
      method: json['method'] as String? ?? '',
      direction: json['direction'] as String? ?? '',
      bmr: _number(json['bmr'], '基础代谢'),
      maintenanceCalories: _number(json['maintenance_calories'], '维持热量'),
      requestedTargetDate: _requiredDate(
        json['requested_target_date'],
        '请求目标日期',
      ),
      recommendedTargetDate: _requiredDate(
        json['recommended_target_date'],
        '建议目标日期',
      ),
      aggressiveTimeline: json['aggressive_timeline'] as bool? ?? false,
    );
  }

  final NutritionGoals recommendedGoals;
  final String method;
  final String direction;
  final double bmr;
  final double maintenanceCalories;
  final DateTime requestedTargetDate;
  final DateTime recommendedTargetDate;
  final bool aggressiveTimeline;

  CalorieRecommendation toDomain() => CalorieRecommendation(
    calories: recommendedGoals.calories,
    protein: recommendedGoals.protein,
    carbs: recommendedGoals.carbs,
    fat: recommendedGoals.fat,
    method: method,
    direction: direction,
    bmr: bmr,
    maintenanceCalories: maintenanceCalories,
    requestedTargetDate: requestedTargetDate,
    recommendedTargetDate: recommendedTargetDate,
    aggressiveTimeline: aggressiveTimeline,
  );
}

class OnboardingResponseDto {
  const OnboardingResponseDto({
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

  factory OnboardingResponseDto.fromJson(Map<String, dynamic> json) {
    final goals = json['goals'];
    if (goals is! Map<String, dynamic>) {
      throw MalformedResponseException('Onboarding goals 响应格式异常');
    }
    final current = json['current_weight'];
    return OnboardingResponseDto(
      onboardingCompletedAt: _requiredDate(
        json['onboarding_completed_at'],
        '完成时间',
      ),
      birthYear: json['birth_year'] is int
          ? json['birth_year'] as int
          : (throw MalformedResponseException('出生年份响应格式异常')),
      sexForEnergyEstimate:
          json['sex_for_energy_estimate'] as String? ??
          (throw MalformedResponseException('生理参数响应格式异常')),
      heightCm: _number(json['height_cm'], '身高'),
      targetWeightKg: _number(json['target_weight_kg'], '目标体重'),
      targetDate: _requiredDate(json['target_date'], '目标日期'),
      activityLevel:
          json['activity_level'] as String? ??
          (throw MalformedResponseException('活动量响应格式异常')),
      goals: NutritionGoals(
        calories: _number(goals['calories'], '热量目标'),
        protein: _number(goals['protein'], '蛋白质目标'),
        carbs: _number(goals['carbs'], '碳水目标'),
        fat: _number(goals['fat'], '脂肪目标'),
      ),
      currentWeight: current == null
          ? null
          : WeightMeasurementDto.fromJson(current).toDomain(),
    );
  }

  final DateTime onboardingCompletedAt;
  final int birthYear;
  final String sexForEnergyEstimate;
  final double heightCm;
  final double targetWeightKg;
  final DateTime targetDate;
  final String activityLevel;
  final NutritionGoals goals;
  final WeightMeasurement? currentWeight;

  OnboardingResult toDomain() => OnboardingResult(
    onboardingCompletedAt: onboardingCompletedAt,
    birthYear: birthYear,
    sexForEnergyEstimate: sexForEnergyEstimate,
    heightCm: heightCm,
    targetWeightKg: targetWeightKg,
    targetDate: targetDate,
    activityLevel: activityLevel,
    goals: goals,
    currentWeight: currentWeight,
  );
}
