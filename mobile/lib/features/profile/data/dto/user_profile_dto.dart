import '../../../../core/network/api_exception.dart';
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

  UserProfile toDomain() => UserProfile(
    id: id,
    email: email,
    provider: provider,
    displayName: displayName,
    goals: goals.toDomain(),
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
  const UpdateUserProfileRequestDto({required this.displayName});

  final String? displayName;

  Map<String, dynamic> toJson() => {'display_name': displayName};
}
