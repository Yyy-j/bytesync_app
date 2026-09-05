import '../domain/meal.dart';
import '../domain/meal_patch.dart';

/// Input for creating a new meal record. Only covers the MVP's manual-entry
/// fields (name + calories/protein/carbs/fat) — photo capture, AI
/// recognition, portion ratios, and pairing/sharing are explicitly out of
/// scope for this stage (see project brief) but can be added as new
/// optional fields here later without touching callers that don't set them.
/// Meal-entry operations. The add-meal page depends only on this
/// interface — never on whether requests are mocked or hit the real
/// backend.
abstract interface class MealsRepository {
  Future<Meal> addMeal(NewMealInput input);

  Future<List<Meal>> getMealsForDate(DateTime date);

  Future<Meal> getMealById(String id);

  Future<Meal> updateMeal(String id, MealPatch patch);

  Future<void> deleteMeal(String id);

  Future<List<Meal>> getRecentMealsForReuse({int limit = 3});
}
