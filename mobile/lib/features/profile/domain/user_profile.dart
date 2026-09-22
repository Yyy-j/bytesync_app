import 'user_character.dart';

class NutritionGoals {
  const NutritionGoals({
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
  });

  final double calories;
  final double protein;
  final double carbs;
  final double fat;
}

class UserProfile {
  const UserProfile({
    required this.id,
    required this.email,
    required this.provider,
    required this.displayName,
    required this.goals,
    this.character = UserCharacter.boy,
  });

  final String id;
  final String? email;
  final String provider;
  final String? displayName;
  final NutritionGoals goals;
  final UserCharacter character;
}
