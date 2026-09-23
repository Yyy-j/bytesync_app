import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bytesync/core/network/api_exception.dart';
import 'package:bytesync/features/meals/data/dto/meal_request_dtos.dart';
import 'package:bytesync/features/meals/data/meal_ai_repository.dart';
import 'package:bytesync/features/meals/data/meals_providers.dart';
import 'package:bytesync/features/meals/data/meals_repository.dart';
import 'package:bytesync/features/meals/domain/meal.dart';
import 'package:bytesync/features/meals/domain/meal_ai_result.dart';
import 'package:bytesync/features/meals/domain/meal_patch.dart';
import 'package:bytesync/features/meals/domain/meal_share_mode.dart';
import 'package:bytesync/features/meals/domain/meal_source.dart';
import 'package:bytesync/features/meals/domain/reusable_meal_item.dart';
import 'package:bytesync/features/meals/presentation/meal_management_controller.dart';
import 'package:bytesync/features/summary/domain/daily_summary.dart';
import 'package:bytesync/features/summary/presentation/summary_controller.dart';

class _FakeMealsRepository implements MealsRepository {
  MealPatch? lastPatch;
  String? lastUpdatedId;
  String? lastDeletedId;
  int updateCallCount = 0;
  Object? updateError;
  Object? deleteError;

  @override
  Future<Meal> updateMeal(String id, MealPatch patch) async {
    updateCallCount++;
    lastUpdatedId = id;
    lastPatch = patch;
    if (updateError != null) throw updateError!;
    return _meal();
  }

  @override
  Future<void> deleteMeal(String id) async {
    lastDeletedId = id;
    if (deleteError != null) throw deleteError!;
  }

  @override
  Future<Meal> addMeal(NewMealInput input) => throw UnimplementedError();

  @override
  Future<Meal> getMealById(String id) => throw UnimplementedError();

  @override
  Future<List<Meal>> getMealsForDate(DateTime date) =>
      throw UnimplementedError();

  @override
  Future<List<ReusableMealItem>> getMealsForReuse({
    required DateTime date,
    int limit = 5,
  }) => throw UnimplementedError();

  @override
  Future<ReusableMealItem> favoriteMeal(String mealId) =>
      throw UnimplementedError();

  @override
  Future<void> unfavoriteMeal(String favoriteId) => throw UnimplementedError();

  @override
  Future<List<Meal>> getRecentMealsForReuse({int limit = 3}) =>
      throw UnimplementedError();
}

class _FakeMealAiRepository implements MealAiRepository {
  String? lastText;
  MealAiResult result = const MealAiResult(
    name: '半碗鸡肉饭',
    calories: 500,
    protein: 35,
    carbs: 55,
    fat: 12,
    dishes: [
      MealAiDish(name: '鸡肉饭', calories: 500),
      MealAiDish(name: '水'),
    ],
  );

  @override
  Future<MealAiResult> analyzeText(String text) async {
    lastText = text;
    return result;
  }
}

class _CountingSummaryController extends SummaryController {
  int refreshCount = 0;

  @override
  SummaryState build() => SummaryLoaded(
        DailySummary.empty(DateTime(2026, 9, 14)),
      );

  @override
  Future<void> refresh() async {
    refreshCount++;
  }
}

Meal _meal({MealSource source = MealSource.text}) {
  return Meal(
    id: 'meal-1',
    pairId: 'pair-1',
    userId: 'self-1',
    sharedMealId: null,
    name: '鸡肉饭',
    source: source,
    baseCalories: 800,
    baseProtein: 45,
    baseCarbs: 90,
    baseFat: 20,
    calories: 400,
    protein: 22.5,
    carbs: 45,
    fat: 10,
    portionRatio: 1,
    shareRatio: 0.5,
    shareMode: MealShareMode.sharedHalf,
    mealDate: DateTime(2026, 9, 14),
    mealTime: '12:30',
    createdAt: DateTime.utc(2026, 9, 14, 3),
    updatedAt: DateTime.utc(2026, 9, 14, 4, 5, 6),
    dishes: const [MealAiDish(name: '鸡肉饭', calories: 800)],
    aiHint: '少油',
    originalInput: '一碗鸡肉饭',
  );
}

({
  ProviderContainer container,
  _FakeMealsRepository meals,
  _FakeMealAiRepository ai,
  _CountingSummaryController summary,
}) _container() {
  final meals = _FakeMealsRepository();
  final ai = _FakeMealAiRepository();
  final summary = _CountingSummaryController();
  final container = ProviderContainer(
    overrides: [
      mealsRepositoryProvider.overrideWithValue(meals),
      mealAiRepositoryProvider.overrideWithValue(ai),
      summaryControllerProvider.overrideWith(() => summary),
    ],
  );
  return (container: container, meals: meals, ai: ai, summary: summary);
}

void main() {
  test('metadata PATCH keeps an explicit empty dishes list', () {
    final json = UpdateMealRequestDto.fromPatch(
      const MealPatch(dishes: <MealAiDish>[]),
    ).toJson();

    expect(json, {'dishes': <Map<String, dynamic>>[]});
  });

  test('portion PATCH sends only portion ratio and expected timestamp', () async {
    final scope = _container();
    addTearDown(scope.container.dispose);
    final meal = _meal();

    final result = await scope.container
        .read(mealManagementControllerProvider.notifier)
        .updatePortion(meal, 1.5);

    expect(result.isSuccess, isTrue);
    expect(
      UpdateMealRequestDto.fromPatch(scope.meals.lastPatch!).toJson(),
      {
        'portion_ratio': 1.5,
        'expected_updated_at': meal.updatedAt.toIso8601String(),
      },
    );
    expect(scope.summary.refreshCount, 1);
  });

  test('direct edit sends canonical base macros, not allocation macros', () async {
    final scope = _container();
    addTearDown(scope.container.dispose);
    final meal = _meal();

    await scope.container
        .read(mealManagementControllerProvider.notifier)
        .updateDetails(
          meal,
          name: '大份鸡肉饭',
          baseCalories: 900,
          baseProtein: 50,
          baseCarbs: 100,
          baseFat: 25,
        );

    final patch = scope.meals.lastPatch!;
    expect(patch.baseCalories, 900);
    expect(patch.baseProtein, 50);
    expect(patch.baseCarbs, 100);
    expect(patch.baseFat, 25);
    expect(patch.portionRatio, isNull);
    expect(patch.shareMode, isNull);
    expect(patch.expectedUpdatedAt, meal.updatedAt);
  });

  test('delete calls once and refreshes only after success', () async {
    final scope = _container();
    addTearDown(scope.container.dispose);
    final meal = _meal();

    final result = await scope.container
        .read(mealManagementControllerProvider.notifier)
        .deleteMeal(meal);

    expect(result.isSuccess, isTrue);
    expect(scope.meals.lastDeletedId, meal.id);
    expect(scope.summary.refreshCount, 1);
  });

  test('delete failure does not refresh or pretend success', () async {
    final scope = _container();
    addTearDown(scope.container.dispose);
    scope.meals.deleteError = NetworkException();
    final meal = _meal();

    final result = await scope.container
        .read(mealManagementControllerProvider.notifier)
        .deleteMeal(meal);

    expect(result.isSuccess, isFalse);
    expect(result.message, contains('网络'));
    expect(scope.meals.lastDeletedId, meal.id);
    expect(scope.summary.refreshCount, 0);
  });

  test('409 refreshes server state and never retries the stale PATCH', () async {
    final scope = _container();
    addTearDown(scope.container.dispose);
    scope.meals.updateError = ConflictException();
    final meal = _meal();

    final result = await scope.container
        .read(mealManagementControllerProvider.notifier)
        .updatePortion(meal, 2);

    expect(result.isSuccess, isFalse);
    expect(result.isConflict, isTrue);
    expect(result.message, contains('其他地方被修改'));
    expect(scope.meals.lastUpdatedId, meal.id);
    expect(scope.meals.updateCallCount, 1);
    expect(scope.summary.refreshCount, 1);
  });

  test('text refine PATCHes new baseline and metadata', () async {
    final scope = _container();
    addTearDown(scope.container.dispose);
    final meal = _meal();

    final result = await scope.container
        .read(mealManagementControllerProvider.notifier)
        .refineMeal(meal, '米饭其实只有半碗');

    expect(result.isSuccess, isTrue);
    expect(scope.ai.lastText, '一碗鸡肉饭；少油；米饭其实只有半碗');
    final json = UpdateMealRequestDto.fromPatch(
      scope.meals.lastPatch!,
    ).toJson();
    expect(json['name'], '半碗鸡肉饭');
    expect(json['base_calories'], 500);
    expect(json['base_protein'], 35);
    expect(json['base_carbs'], 55);
    expect(json['base_fat'], 12);
    expect(json['dishes'], [
      {'name': '鸡肉饭', 'calories': 500},
    ]);
    expect(json['ai_hint'], '少油；米饭其实只有半碗');
    expect(json['original_input'], '一碗鸡肉饭');
    expect(json['expected_updated_at'], meal.updatedAt.toIso8601String());
    expect(json.containsKey('portion_ratio'), isFalse);
    expect(json.containsKey('share_mode'), isFalse);
  });
}
