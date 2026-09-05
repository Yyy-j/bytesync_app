import '../../../../core/network/api_exception.dart';

/// Wire shape of a single Meal returned by the backend.
///
/// Matches the JSON shape in `API_CONTRACT.md` §2.2 exactly. Field types
/// are stored as `dynamic` where the backend allows a null/absent value;
/// the mapper (see `meal_mapper.dart`) validates and converts them into
/// the strict domain [Meal].
class MealDto {
  const MealDto({
    required this.id,
    required this.pairId,
    required this.userId,
    required this.sharedMealId,
    required this.name,
    required this.source,
    required this.baseCalories,
    required this.baseProtein,
    required this.baseCarbs,
    required this.baseFat,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    required this.portionRatio,
    required this.shareRatio,
    required this.shareMode,
    required this.mealDate,
    required this.mealTime,
    required this.createdAt,
    required this.updatedAt,
  });

  factory MealDto.fromJson(Map<String, dynamic> json) {
    try {
      return MealDto(
        id: json['id'] as String,
        pairId: json['pair_id'] as String,
        userId: json['user_id'] as String,
        sharedMealId: json['shared_meal_id'] as String?,
        name: json['name'] as String,
        source: json['source'] as String,
        baseCalories: (json['base_calories'] as num),
        baseProtein: (json['base_protein'] as num),
        baseCarbs: (json['base_carbs'] as num),
        baseFat: (json['base_fat'] as num),
        calories: (json['calories'] as num),
        protein: (json['protein'] as num),
        carbs: (json['carbs'] as num),
        fat: (json['fat'] as num),
        portionRatio: (json['portion_ratio'] as num).toDouble(),
        shareRatio: (json['share_ratio'] as num).toDouble(),
        shareMode: json['share_mode'] as String,
        mealDate: json['meal_date'] as String,
        mealTime: json['meal_time'] as String,
        createdAt: json['created_at'] as String,
        updatedAt: json['updated_at'] as String,
      );
    } on TypeError catch (e) {
      throw MalformedResponseException('Meal 数据解析失败: $e');
    }
  }

  final String id;
  final String pairId;
  final String userId;
  final String? sharedMealId;
  final String name;
  final String source;

  final num baseCalories;
  final num baseProtein;
  final num baseCarbs;
  final num baseFat;

  final num calories;
  final num protein;
  final num carbs;
  final num fat;

  final double portionRatio;
  final double shareRatio;
  final String shareMode;

  final String mealDate;
  final String mealTime;
  final String createdAt;
  final String updatedAt;
}

/// Wire shape of `GET /meals` / `GET /meals/recent` responses.
class MealListResponseDto {
  const MealListResponseDto({required this.meals});

  factory MealListResponseDto.fromJson(Map<String, dynamic> json) {
    final rawList = json['meals'];
    if (rawList is! List) {
      throw const MalformedResponseException('meals 列表格式异常');
    }
    return MealListResponseDto(
      meals: rawList
          .map((e) => MealDto.fromJson(e as Map<String, dynamic>))
          .toList(growable: false),
    );
  }

  final List<MealDto> meals;
}
