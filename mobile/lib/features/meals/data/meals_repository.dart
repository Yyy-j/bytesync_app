import '../domain/meal.dart';
import '../domain/meal_patch.dart';
import '../domain/reusable_meal_item.dart';

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

  Future<List<ReusableMealItem>> getMealsForReuse({
    required DateTime date,
    int limit = 5,
  });

  Future<ReusableMealItem> favoriteMeal(String mealId);

  Future<void> unfavoriteMeal(String favoriteId);
}
