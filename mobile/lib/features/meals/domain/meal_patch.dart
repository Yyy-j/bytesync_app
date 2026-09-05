import 'meal_share_mode.dart';
import 'meal_source.dart';

/// Input to `MealsRepository.addMeal`. Everything the UI collects on the
/// record page.
///
/// `pairId` / `userId` / `mealDate` are set server-side (`API_CONTRACT.md`
/// §2.2) — the client never fills them.
class NewMealInput {
  const NewMealInput({
    required this.name,
    required this.source,
    required this.baseCalories,
    required this.baseProtein,
    required this.baseCarbs,
    required this.baseFat,
    required this.portionRatio,
    required this.shareMode,
    required this.mealTime,
  });

  final String name;
  final MealSource source;
  final num baseCalories;
  final num baseProtein;
  final num baseCarbs;
  final num baseFat;
  final double portionRatio;
  final MealShareMode shareMode;
  final String mealTime; // "HH:mm"
}

/// Input to `MealsRepository.updateMeal`. All fields optional. See
/// `REPOSITORY_CONTRACTS.md` §3.2 for the propagation rules.
///
/// Optimistic-concurrency: [expectedUpdatedAt] is required whenever the
/// caller wants to safely apply an update to a row they read earlier —
/// server returns 409 if the row changed on someone else's device.
class MealPatch {
  const MealPatch({
    this.name,
    this.baseCalories,
    this.baseProtein,
    this.baseCarbs,
    this.baseFat,
    this.portionRatio,
    this.shareMode,
    this.mealTime,
    this.expectedUpdatedAt,
  });

  final String? name;
  final num? baseCalories;
  final num? baseProtein;
  final num? baseCarbs;
  final num? baseFat;
  final double? portionRatio;
  final MealShareMode? shareMode;
  final String? mealTime;
  final DateTime? expectedUpdatedAt;
}
