class ReusableMealItem {
  const ReusableMealItem({
    required this.mealId,
    required this.favoriteId,
    required this.name,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    required this.isFavorite,
  });

  final String? mealId;
  final String? favoriteId;
  final String name;
  final num calories;
  final num protein;
  final num carbs;
  final num fat;
  final bool isFavorite;
}
