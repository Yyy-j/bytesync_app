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
  static const String authRefresh = '/auth/refresh';
  static const String authLogout = '/auth/logout';
  static const String usersMe = '/users/me';

  // ── Pairs ─────────────────────────────────────────────
  static const String pairsMe = '/pairs/me';
  static const String pairs = '/pairs';
  static const String pairsJoin = '/pairs/join';

  // ── Meals ─────────────────────────────────────────────
  static const String meals = '/meals';
  static String mealById(String id) => '/meals/$id';
  static const String mealsRecent = '/meals/recent';
  static const String mealsReuse = '/meals/reuse';

  // ── Meal AI ──────────────────────────────────────────
  static const String analyzeMealText = '/ai/meals/analyze-text';
  static const String analyzeMealImage = '/ai/meals/analyze-image';

  // ── Summary ───────────────────────────────────────────
  static const String summaryDaily = '/summary/daily';
  static const String summaryMonthly = '/summary/monthly';

  // ── Training ──────────────────────────────────────────
  static const String trainingCustomExercises = '/training/exercises/custom';
  static const String trainingExerciseVideos = '/training/exercises/videos';
  static String trainingExerciseVideo(String exerciseId) =>
      '/training/exercises/${Uri.encodeComponent(exerciseId)}/video';
  static String trainingCustomExerciseById(String id) =>
      '$trainingCustomExercises/${Uri.encodeComponent(id)}';
  static const String trainingTemplate = '/training/template';
  static const String trainingWeeks = '/training/weeks';
  static const String trainingWeeksCurrent = '/training/weeks/current';
  static const String trainingWeeksCurrentSync = '/training/weeks/current/sync';
  static String trainingWeekById(String weekId) =>
      '/training/weeks/${Uri.encodeComponent(weekId)}';
  static String trainingItemSets(String weekId, String itemId) =>
      '${trainingWeekById(weekId)}/items/${Uri.encodeComponent(itemId)}/sets';
  static String trainingSetDetail(
    String weekId,
    String itemId,
    String requestId,
  ) => '${trainingItemSets(weekId, itemId)}/${Uri.encodeComponent(requestId)}';
}
