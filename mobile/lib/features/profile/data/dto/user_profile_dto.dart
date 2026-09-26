import '../../../../core/network/api_exception.dart';
import '../../domain/user_character.dart';
import '../../domain/user_profile.dart';

class NutritionGoalsDto {
  const NutritionGoalsDto({
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
  });

  factory NutritionGoalsDto.fromJson(Map<String, dynamic> json) {
    try {
      return NutritionGoalsDto(
        calories: (json['calories'] as num).toDouble(),
        protein: (json['protein'] as num).toDouble(),
        carbs: (json['carbs'] as num).toDouble(),
        fat: (json['fat'] as num).toDouble(),
      );
    } on TypeError catch (error) {
      throw MalformedResponseException('营养目标数据解析失败: $error');
    }
  }

  final double calories;
  final double protein;
  final double carbs;
  final double fat;

  NutritionGoals toDomain() => NutritionGoals(
    calories: calories,
    protein: protein,
    carbs: carbs,
    fat: fat,
  );
}

class UserProfileDto {
  const UserProfileDto({
    required this.id,
    required this.email,
    required this.provider,
    required this.displayName,
    required this.goals,
    required this.character,
    this.onboardingCompletedAt,
    this.birthYear,
    this.sexForEnergyEstimate,
    this.heightCm,
    this.targetWeightKg,
    this.targetDate,
    this.activityLevel,
  });

  factory UserProfileDto.fromJson(Map<String, dynamic> json) {
    try {
      return UserProfileDto(
        id: json['id'] as String,
        email: json['email'] as String?,
        provider: json['provider'] as String,
        displayName: json['display_name'] as String?,
        goals: NutritionGoalsDto.fromJson(
          json['goals'] as Map<String, dynamic>,
        ),
        character: UserCharacter.fromWire(json['character']),
        onboardingCompletedAt: _date(json['onboarding_completed_at']),
        birthYear: json['birth_year'] as int?,
        sexForEnergyEstimate: json['sex_for_energy_estimate'] as String?,
        heightCm: (json['height_cm'] as num?)?.toDouble(),
        targetWeightKg: (json['target_weight_kg'] as num?)?.toDouble(),
        targetDate: _date(json['target_date']),
        activityLevel: json['activity_level'] as String?,
      );
    } on TypeError catch (error) {
      throw MalformedResponseException('用户资料数据解析失败: $error');
    }
  }

  final String id;
  final String? email;
  final String provider;
  final String? displayName;
  final NutritionGoalsDto goals;
  final UserCharacter character;
  final DateTime? onboardingCompletedAt;
  final int? birthYear;
  final String? sexForEnergyEstimate;
  final double? heightCm;
  final double? targetWeightKg;
  final DateTime? targetDate;
  final String? activityLevel;

  static DateTime? _date(Object? value) =>
      value is String ? DateTime.tryParse(value) : null;

  UserProfile toDomain() => UserProfile(
    id: id,
    email: email,
    provider: provider,
    displayName: displayName,
    goals: goals.toDomain(),
    character: character,
    onboardingCompletedAt: onboardingCompletedAt,
    birthYear: birthYear,
    sexForEnergyEstimate: sexForEnergyEstimate,
    heightCm: heightCm,
    targetWeightKg: targetWeightKg,
    targetDate: targetDate,
    activityLevel: activityLevel,
  );
}

class UpdateNutritionGoalsRequestDto {
  const UpdateNutritionGoalsRequestDto(this.goals);

  final NutritionGoals goals;

  Map<String, dynamic> toJson() => {
    'goals': {
      'calories': goals.calories,
      'protein': goals.protein,
      'carbs': goals.carbs,
      'fat': goals.fat,
    },
  };
}

class UpdateUserProfileRequestDto {
  const UpdateUserProfileRequestDto({
    required this.displayName,
    this.birthYear,
    this.sexForEnergyEstimate,
    this.heightCm,
    this.targetWeightKg,
    this.targetDate,
    this.activityLevel,
  });

  final String? displayName;
  final int? birthYear;
  final String? sexForEnergyEstimate;
  final double? heightCm;
  final double? targetWeightKg;
  final DateTime? targetDate;
  final String? activityLevel;

  Map<String, dynamic> toJson() => {
    'display_name': displayName,
    if (birthYear != null) 'birth_year': birthYear,
    if (sexForEnergyEstimate != null)
      'sex_for_energy_estimate': sexForEnergyEstimate,
    if (heightCm != null) 'height_cm': heightCm,
    if (targetWeightKg != null) 'target_weight_kg': targetWeightKg,
    if (targetDate != null)
      'target_date': targetDate!.toIso8601String().split('T').first,
    if (activityLevel != null) 'activity_level': activityLevel,
  };
}

class UpdateUserCharacterRequestDto {
  const UpdateUserCharacterRequestDto(this.character);

  final UserCharacter character;

  Map<String, dynamic> toJson() => {'character': character.toWire()};
}
