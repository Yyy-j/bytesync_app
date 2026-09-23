import '../../domain/reusable_meal_item.dart';

class ReusableMealItemDto {
  const ReusableMealItemDto({
    required this.mealId,
    required this.favoriteId,
    required this.name,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    required this.isFavorite,
  });

  factory ReusableMealItemDto.fromJson(Map<String, dynamic> json) =>
      ReusableMealItemDto(
        mealId: json['meal_id'] as String?,
        favoriteId: json['favorite_id'] as String?,
        name: json['name'] as String,
        calories: json['calories'] as num,
        protein: json['protein'] as num,
        carbs: json['carbs'] as num,
        fat: json['fat'] as num,
        isFavorite: json['is_favorite'] as bool,
      );

  final String? mealId;
  final String? favoriteId;
  final String name;
  final num calories;
  final num protein;
  final num carbs;
  final num fat;
  final bool isFavorite;

  ReusableMealItem toDomain() => ReusableMealItem(
    mealId: mealId,
    favoriteId: favoriteId,
    name: name,
    calories: calories,
    protein: protein,
    carbs: carbs,
    fat: fat,
    isFavorite: isFavorite,
  );
}
