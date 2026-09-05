import 'meal.dart';

/// Groups the two rows of a shared meal into a single conceptual view.
///
/// Backend / wire storage keeps two [Meal] rows linked by `sharedMealId`;
/// the UI needs to render them as one aggregate on the detail / edit
/// screen and know both sides' contribution on the summary page.
///
/// This class is pure: it never touches a repository. Feed it the list
/// returned by `MealsRepository.getMealsForDate` (or similar) and it
/// gives back a grouped view.
class SharedMealResolver {
  const SharedMealResolver._();

  /// Splits a list of meals into (soloMeals, sharedGroups).
  ///
  /// A "shared group" is a `MealPair`: two rows with the same
  /// `sharedMealId`. If only one row is present for a given
  /// `sharedMealId` (an orphan, which the Phase 2 backend contract
  /// forbids but which we defensively handle), the resolver treats it as
  /// a solo meal for rendering — the summary won't crash on a partial
  /// server state.
  static ResolvedMeals resolve(List<Meal> meals) {
    final byShared = <String, List<Meal>>{};
    final solos = <Meal>[];

    for (final meal in meals) {
      final key = meal.sharedMealId;
      if (key == null) {
        solos.add(meal);
      } else {
        (byShared[key] ??= <Meal>[]).add(meal);
      }
    }

    final pairs = <SharedMealGroup>[];
    for (final entry in byShared.entries) {
      final rows = entry.value;
      if (rows.length == 2) {
        pairs.add(SharedMealGroup(sharedMealId: entry.key, rows: rows));
      } else {
        // Defensive: treat orphans as solo meals so the summary keeps
        // rendering.
        solos.addAll(rows);
      }
    }

    return ResolvedMeals(solos: solos, sharedGroups: pairs);
  }

  /// Given one row of a shared meal (from `getMealById` or the summary
  /// list), finds its sibling row in the same list. Returns `null` if
  /// [meal] isn't shared or its sibling isn't in [pool].
  static Meal? siblingOf(Meal meal, List<Meal> pool) {
    final id = meal.sharedMealId;
    if (id == null) return null;
    for (final other in pool) {
      if (other.id != meal.id && other.sharedMealId == id) return other;
    }
    return null;
  }
}

/// A [Meal] pair, both sides of a shared meal.
class SharedMealGroup {
  const SharedMealGroup({required this.sharedMealId, required this.rows});

  final String sharedMealId;
  final List<Meal> rows;
}

/// Result of grouping meals into solos and shared pairs.
class ResolvedMeals {
  const ResolvedMeals({required this.solos, required this.sharedGroups});

  final List<Meal> solos;
  final List<SharedMealGroup> sharedGroups;
}
