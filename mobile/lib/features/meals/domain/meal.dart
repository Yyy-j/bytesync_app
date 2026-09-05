import 'meal_share_mode.dart';
import 'meal_source.dart';

/// One persisted meal record.
///
/// **Domain model**, not the wire DTO. See `MealDto` in
/// `lib/features/meals/data/dto/meal_dto.dart` for the wire shape and the
/// mapper for the translation. This class deliberately carries no
/// serialization concerns and has no factory that reads JSON directly.
///
/// For shared meals (see `SPEC.md` §5), the backend stores two [Meal]
/// rows linked by [sharedMealId]; the frontend treats them as siblings via
/// `SharedMealResolver`.
class Meal {
  const Meal({
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

  // ── identity ──
  final String id;
  final String pairId;
  final String userId;
  final String? sharedMealId;

  // ── content ──
  final String name;
  final MealSource source;

  // ── baseline (one portion, one person) ──
  final num baseCalories;
  final num baseProtein;
  final num baseCarbs;
  final num baseFat;

  // ── stored (base × portion × share, rounded once) ──
  final num calories;
  final num protein;
  final num carbs;
  final num fat;

  // ── portion & share ──
  final double portionRatio;
  final double shareRatio;
  final MealShareMode shareMode;

  // ── time ──
  final DateTime mealDate;
  final String mealTime;
  final DateTime createdAt;
  final DateTime updatedAt;

  // ── derived ──
  bool get isShared => sharedMealId != null;
}
