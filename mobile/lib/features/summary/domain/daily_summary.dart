import '../../meals/domain/meal.dart';
import '../../meals/data/mappers/meal_mapper.dart';
import '../../meals/data/dto/meal_dto.dart';

/// Aggregated nutrition totals for a single day, plus the list of meals
/// that make it up — mirrors the backend's planned `GET /summary/daily`
/// response shape.
class DailySummary {
  const DailySummary({
    required this.date,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    required this.mealCount,
    required this.meals,
    required this.selfSlice,
    required this.partnerSlice,
    required this.selfGoals,
    required this.partnerGoals,
  });

  factory DailySummary.empty(DateTime date) => DailySummary(
    date: date,
    calories: 0,
    protein: 0,
    carbs: 0,
    fat: 0,
    mealCount: 0,
    meals: const [],
    selfSlice: const UserDailySlice.empty(),
    partnerSlice: null,
    selfGoals: const DailyGoals(),
    partnerGoals: null,
  );

  factory DailySummary.fromJson(Map<String, dynamic> json) => DailySummary(
    date: DateTime.parse(json['date'] as String),
    calories: json['calories'] as num,
    protein: json['protein'] as num,
    carbs: json['carbs'] as num,
    fat: json['fat'] as num,
    mealCount: (json['meal_count'] as num?)?.toInt() ?? 0,
    meals: ((json['meals'] as List<dynamic>?) ?? const <dynamic>[])
        .map(
          (m) =>
              MealMapper.fromDto(MealDto.fromJson(m as Map<String, dynamic>)),
        )
        .toList(),
    selfSlice: UserDailySlice.fromJson(json['self_slice'] as Map<String, dynamic>?),
    partnerSlice: UserDailySlice.fromNullableJson(
      json['partner_slice'] as Map<String, dynamic>?,
    ),
    selfGoals: DailyGoals.fromJson(json['self_goals'] as Map<String, dynamic>?),
    partnerGoals: DailyGoals.fromNullableJson(
      json['partner_goals'] as Map<String, dynamic>?,
    ),
  );

  /// Builds a summary by aggregating an already-fetched meal list — used
  /// by the mock repository so it stays consistent with whatever meals
  /// were added on the record page.
  factory DailySummary.fromMeals(DateTime date, List<Meal> meals) {
    num sum(num Function(Meal) pick) =>
        meals.fold<num>(0, (total, m) => total + pick(m));
    return DailySummary(
      date: date,
      calories: sum((m) => m.calories),
      protein: sum((m) => m.protein),
      carbs: sum((m) => m.carbs),
      fat: sum((m) => m.fat),
      mealCount: meals.length,
      meals: meals,
      selfSlice: const UserDailySlice.empty(),
      partnerSlice: null,
      selfGoals: const DailyGoals(),
      partnerGoals: null,
    );
  }

  final DateTime date;
  final num calories;
  final num protein;
  final num carbs;
  final num fat;
  final int mealCount;
  final List<Meal> meals;
  final UserDailySlice selfSlice;
  final UserDailySlice? partnerSlice;
  final DailyGoals selfGoals;
  final DailyGoals? partnerGoals;
}

class UserDailySlice {
  const UserDailySlice({
    required this.userId,
    required this.displayName,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
  });

  const UserDailySlice.empty()
      : userId = '',
        displayName = '',
        calories = 0,
        protein = 0,
        carbs = 0,
        fat = 0;

  factory UserDailySlice.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const UserDailySlice.empty();
    return UserDailySlice(
      userId: json['user_id'] as String? ?? '',
      displayName: json['display_name'] as String? ?? '未命名成员',
      calories: json['calories'] as num? ?? 0,
      protein: json['protein'] as num? ?? 0,
      carbs: json['carbs'] as num? ?? 0,
      fat: json['fat'] as num? ?? 0,
    );
  }

  static UserDailySlice? fromNullableJson(Map<String, dynamic>? json) =>
      json == null ? null : UserDailySlice.fromJson(json);

  final String userId;
  final String displayName;
  final num calories;
  final num protein;
  final num carbs;
  final num fat;
}

/// Daily nutrition goals. Hardcoded defaults for MVP (mirroring the
/// mini-program's `config.goals`); a per-user goals setting can replace
/// this later without changing how the summary page reads goals.
class DailyGoals {
  const DailyGoals({
    this.calorieGoal = 2000,
    this.proteinGoal = 90,
    this.carbsGoal = 250,
    this.fatGoal = 60,
  });

  factory DailyGoals.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const DailyGoals();
    return DailyGoals(
      calorieGoal: json['calorie_goal'] as num? ?? 2000,
      proteinGoal: json['protein_goal'] as num? ?? 90,
      carbsGoal: json['carbs_goal'] as num? ?? 250,
      fatGoal: json['fat_goal'] as num? ?? 60,
    );
  }

  static DailyGoals? fromNullableJson(Map<String, dynamic>? json) =>
      json == null ? null : DailyGoals.fromJson(json);

  final num calorieGoal;
  final num proteinGoal;
  final num carbsGoal;
  final num fatGoal;
}
