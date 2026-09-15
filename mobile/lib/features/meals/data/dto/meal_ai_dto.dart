import '../../../../core/network/api_exception.dart';
import '../../domain/meal_ai_result.dart';

class MealAiResultDto {
  const MealAiResultDto({
    required this.name,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    required this.dishes,
  });

  factory MealAiResultDto.fromJson(Map<String, dynamic> json) {
    final rawDishes = json['dishes'];
    if (rawDishes is! List) {
      throw MalformedResponseException('AI 菜品列表格式异常');
    }

    try {
      return MealAiResultDto(
        name: json['name'] as String,
        calories: json['calories'] as num,
        protein: json['protein'] as num,
        carbs: json['carbs'] as num,
        fat: json['fat'] as num,
        dishes: rawDishes.map(_dish).toList(growable: false),
      );
    } on TypeError catch (error) {
      throw MalformedResponseException('AI 估算结果格式异常: $error');
    }
  }

  static MealAiDish _dish(dynamic dish) {
    if (dish is String) return MealAiDish(name: dish);
    if (dish is Map && dish['name'] is String) {
      return MealAiDish(
        name: dish['name'] as String,
        calories: dish['calories'] as num?,
      );
    }
    throw MalformedResponseException('AI 菜品格式异常');
  }

  final String name;
  final num calories;
  final num protein;
  final num carbs;
  final num fat;
  final List<MealAiDish> dishes;
}
