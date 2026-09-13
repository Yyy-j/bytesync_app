class MealAiResult {
  const MealAiResult({
    required this.name,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    required this.dishes,
  });

  final String name;
  final num calories;
  final num protein;
  final num carbs;
  final num fat;
  final List<dynamic> dishes;
}

class MealAiDish {
  const MealAiDish({required this.name, this.calories});

  final String name;
  final num? calories;
}
