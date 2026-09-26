import '../../domain/meal_ai_result.dart';
import '../../domain/meal_share_mode.dart';
import '../../domain/meal_source.dart';

class RecordDraft {
  const RecordDraft({
    required this.name,
    required this.baseCalories,
    required this.baseProtein,
    required this.baseCarbs,
    required this.baseFat,
    required this.dishes,
    required this.source,
    this.originalText,
    this.hint,
    this.localImagePath,
    this.portionRatio = 1,
    this.shareMode = MealShareMode.solo,
  });

  factory RecordDraft.fromAi({
    required MealAiResult result,
    required MealSource source,
    String? originalText,
    String? hint,
    String? localImagePath,
  }) {
    return RecordDraft(
      name: result.name,
      baseCalories: result.calories,
      baseProtein: result.protein,
      baseCarbs: result.carbs,
      baseFat: result.fat,
      dishes: result.dishes
          .map((dish) {
            if (dish is MealAiDish) return dish;
            return MealAiDish(name: dish.toString());
          })
          .toList(growable: false),
      source: source,
      originalText: originalText,
      hint: hint,
      localImagePath: localImagePath,
    );
  }

  final String name;
  final num baseCalories;
  final num baseProtein;
  final num baseCarbs;
  final num baseFat;
  final List<MealAiDish> dishes;
  final MealSource source;
  final String? originalText;
  final String? hint;
  final String? localImagePath;
  final double portionRatio;
  final MealShareMode shareMode;

  num get calories => baseCalories * portionRatio;
  num get protein => baseProtein * portionRatio;
  num get carbs => baseCarbs * portionRatio;
  num get fat => baseFat * portionRatio;

  List<MealAiDish> get scaledDishes => dishes
      .map(
        (dish) => MealAiDish(
          name: dish.name,
          calories: dish.calories == null
              ? null
              : dish.calories! * portionRatio,
        ),
      )
      .toList(growable: false);

  RecordDraft copyWith({
    String? name,
    num? baseCalories,
    num? baseProtein,
    num? baseCarbs,
    num? baseFat,
    List<MealAiDish>? dishes,
    MealSource? source,
    String? originalText,
    String? hint,
    String? localImagePath,
    double? portionRatio,
    MealShareMode? shareMode,
  }) {
    return RecordDraft(
      name: name ?? this.name,
      baseCalories: baseCalories ?? this.baseCalories,
      baseProtein: baseProtein ?? this.baseProtein,
      baseCarbs: baseCarbs ?? this.baseCarbs,
      baseFat: baseFat ?? this.baseFat,
      dishes: dishes ?? this.dishes,
      source: source ?? this.source,
      originalText: originalText ?? this.originalText,
      hint: hint ?? this.hint,
      localImagePath: localImagePath ?? this.localImagePath,
      portionRatio: portionRatio ?? this.portionRatio,
      shareMode: shareMode ?? this.shareMode,
    );
  }
}
