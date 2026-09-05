import '../../../../core/network/api_exception.dart';
import '../../domain/meal.dart';
import '../../domain/meal_share_mode.dart';
import '../../domain/meal_source.dart';
import '../dto/meal_dto.dart';

class MealMapper {
  const MealMapper._();

  static Meal fromDto(MealDto dto) {
    try {
      return Meal(
        id: dto.id,
        pairId: dto.pairId,
        userId: dto.userId,
        sharedMealId: dto.sharedMealId,
        name: dto.name,
        source: MealSource.fromWire(dto.source),
        baseCalories: dto.baseCalories,
        baseProtein: dto.baseProtein,
        baseCarbs: dto.baseCarbs,
        baseFat: dto.baseFat,
        calories: dto.calories,
        protein: dto.protein,
        carbs: dto.carbs,
        fat: dto.fat,
        portionRatio: dto.portionRatio,
        shareRatio: dto.shareRatio,
        shareMode: MealShareMode.fromWire(dto.shareMode),
        mealDate: DateTime.parse(dto.mealDate),
        mealTime: dto.mealTime,
        createdAt: DateTime.parse(dto.createdAt),
        updatedAt: DateTime.parse(dto.updatedAt),
      );
    } on FormatException catch (error) {
      throw MalformedResponseException('Meal 时间格式异常: $error');
    }
  }
}
