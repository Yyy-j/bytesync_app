import 'meal_share_mode.dart';

/// The per-user, per-nutrient result of applying portion + share to a
/// baseline. Used both:
///
/// - internally during `RemoteMealsRepository.addMeal` to populate the
///   client-side [Meal] fields, and
/// - by the record page's live preview widget (before any repo call).
///
/// Rounding: exactly once, at the point where a number becomes
/// user-visible or persisted. Callers should not round intermediate
/// [double]s.
class MealNutrition {
  const MealNutrition({
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
  });

  final num calories;
  final num protein;
  final num carbs;
  final num fat;
}

/// Baseline nutrition = one portion, one person.
class BaseNutrition {
  const BaseNutrition({
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
  });

  final num calories;
  final num protein;
  final num carbs;
  final num fat;
}

/// Applies portion adjustment to a baseline. Never rounds.
BaseNutrition scaledByPortion(BaseNutrition base, double portionRatio) {
  return BaseNutrition(
    calories: base.calories * portionRatio,
    protein: base.protein * portionRatio,
    carbs: base.carbs * portionRatio,
    fat: base.fat * portionRatio,
  );
}

/// Given the base one-portion nutrition, applies `portionRatio` and the
/// per-user `shareRatio`, then rounds to `int` for the storage layer.
///
/// Callers must always start from [base] — never chain
/// `computeStored(computeStored(base, ...), ...)`, which is the source of
/// the legacy floating-point drift discussed in `SPEC.md` §4.1.
MealNutrition computeStored({
  required BaseNutrition base,
  required double portionRatio,
  required double shareRatio,
}) {
  final effectiveRatio = portionRatio * shareRatio;
  return MealNutrition(
    calories: (base.calories * effectiveRatio).round(),
    protein: (base.protein * effectiveRatio).round(),
    carbs: (base.carbs * effectiveRatio).round(),
    fat: (base.fat * effectiveRatio).round(),
  );
}

/// Convenience: given a base + portion + share mode, returns the (self,
/// partner) stored slices. `partner` is `null` for [MealShareMode.solo]
/// and `self` is `null` for [MealShareMode.partnerOnly].
({MealNutrition? self, MealNutrition? partner}) computeSharedStored({
  required BaseNutrition base,
  required double portionRatio,
  required MealShareMode shareMode,
}) {
  final me = shareMode.meRatio;
  final ta = shareMode.partnerRatio;
  return (
    self: me == 0
        ? null
        : computeStored(base: base, portionRatio: portionRatio, shareRatio: me),
    partner: ta == 0
        ? null
        : computeStored(base: base, portionRatio: portionRatio, shareRatio: ta),
  );
}
