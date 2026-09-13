import '../domain/meal_ai_result.dart';

abstract class MealAiRepository {
  Future<MealAiResult> analyzeText(String text);
}

abstract interface class MealImageAiRepository {
  Future<MealAiResult> analyzeImage(String imagePath, {String? hint});
}
