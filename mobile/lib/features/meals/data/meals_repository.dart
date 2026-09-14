import '../domain/meal.dart';
import '../domain/meal_patch.dart';

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

  Future<List<Meal>> getMealsForReuse({
    required DateTime date,
    int limit = 3,
  });
}
