/// Backend HTTP endpoint paths, relative to `AppConfig.apiBaseUrl`.
///
/// The single place in the codebase that knows about specific paths.
/// Remote repositories reference these constants — never raw string
/// literals — so a backend routing change touches exactly one file.
class ApiEndpoints {
  const ApiEndpoints._();

  // ── Health ────────────────────────────────────────────
  static const String health = '/health';

  // ── Auth ──────────────────────────────────────────────
  static const String authGoogle = '/auth/google';
  static const String usersMe = '/users/me';

  // ── Pairs ─────────────────────────────────────────────
  static const String pairsMe = '/pairs/me';
  static const String pairs = '/pairs';
  static const String pairsJoin = '/pairs/join';

  // ── Meals ─────────────────────────────────────────────
  static const String meals = '/meals';
  static String mealById(String id) => '/meals/$id';
  static const String mealsRecent = '/meals/recent';

  // ── Summary ───────────────────────────────────────────
  static const String summaryDaily = '/summary/daily';
}
