import '../../domain/meal_ai_result.dart';
import '../dto/meal_ai_dto.dart';

class MealAiMapper {
  const MealAiMapper._();

  static MealAiResult fromDto(MealAiResultDto dto) => MealAiResult(
        name: dto.name,
        calories: dto.calories,
        protein: dto.protein,
        carbs: dto.carbs,
        fat: dto.fat,
        dishes: dto.dishes,
      );
}
