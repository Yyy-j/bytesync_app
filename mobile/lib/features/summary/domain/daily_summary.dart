import 'package:bytesync/l10n/l10n.dart';

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
    selfSlice: UserDailySlice.fromJson(
      json['self_slice'] as Map<String, dynamic>?,
    ),
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

class MonthlySummary {
  const MonthlySummary({required this.month, required this.days});

  factory MonthlySummary.fromJson(Map<String, dynamic> json) {
    final rawDays = json['days'] ?? json['daily_summaries'] ?? json['data'];
    if (rawDays is! List) {
      throw const FormatException('Monthly summary days are missing');
    }
    final monthValue = json['month'] as String?;
    final parsedMonth = monthValue == null
        ? DateTime.now()
        : DateTime.parse('$monthValue-01');
    final days = <DateTime, MonthlyDaySummary>{};
    for (final value in rawDays) {
      if (value is! Map<String, dynamic>) {
        throw const FormatException('Monthly summary day is malformed');
      }
      final day = MonthlyDaySummary.fromJson(value);
      days[DateTime(day.date.year, day.date.month, day.date.day)] = day;
    }
    return MonthlySummary(
      month: DateTime(parsedMonth.year, parsedMonth.month),
      days: days,
    );
  }

  final DateTime month;
  final Map<DateTime, MonthlyDaySummary> days;

  MonthlyDaySummary? dayAt(DateTime date) =>
      days[DateTime(date.year, date.month, date.day)];
}

class MonthlyDaySummary {
  const MonthlyDaySummary({
    required this.date,
    required this.selfCalories,
    required this.selfCalorieGoal,
    this.partnerCalories,
    this.partnerCalorieGoal,
  });

  factory MonthlyDaySummary.fromJson(Map<String, dynamic> json) {
    final date = DateTime.parse(json['date'] as String);
    final self = json['self_slice'] is Map<String, dynamic>
        ? json['self_slice'] as Map<String, dynamic>
        : json['self'] is Map<String, dynamic>
        ? json['self'] as Map<String, dynamic>
        : const <String, dynamic>{};
    final partner = json['partner_slice'] is Map<String, dynamic>
        ? json['partner_slice'] as Map<String, dynamic>
        : json['partner'] is Map<String, dynamic>
        ? json['partner'] as Map<String, dynamic>
        : null;
    final selfGoals = json['self_goals'] is Map<String, dynamic>
        ? json['self_goals'] as Map<String, dynamic>
        : const <String, dynamic>{};
    final partnerGoals = json['partner_goals'] is Map<String, dynamic>
        ? json['partner_goals'] as Map<String, dynamic>
        : null;
    return MonthlyDaySummary(
      date: date,
      selfCalories: _number(self['calories'] ?? json['self_calories']),
      selfCalorieGoal: _number(
        selfGoals['calorie_goal'] ?? json['self_calorie_goal'],
        fallback: 2000,
      ),
      partnerCalories: partner == null
          ? _nullableNumber(json['partner_calories'])
          : _nullableNumber(partner['calories']),
      partnerCalorieGoal: partner == null
          ? _nullableNumber(json['partner_calorie_goal'])
          : _nullableNumber(partnerGoals?['calorie_goal']),
    );
  }

  final DateTime date;
  final num selfCalories;
  final num selfCalorieGoal;
  final num? partnerCalories;
  final num? partnerCalorieGoal;

  static num _number(Object? value, {num fallback = 0}) =>
      value is num ? value : fallback;

  static num? _nullableNumber(Object? value) => value is num ? value : null;
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
      displayName:
          json['display_name'] as String? ?? appL10n.commonUnnamedMember,
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

/// Daily nutrition goals returned under `self_goals` / `partner_goals` by
/// `GET /summary/daily`. These wire keys intentionally differ from the
/// profile endpoint's `goals` object.
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
