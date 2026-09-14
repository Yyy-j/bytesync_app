import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../../summary/presentation/summary_controller.dart';
import '../data/meal_ai_repository.dart';
import '../data/meals_providers.dart';
import '../data/meals_repository.dart';
import '../domain/meal.dart';
import '../domain/meal_ai_result.dart';
import '../domain/meal_patch.dart';
import '../domain/meal_source.dart';

@immutable
class MealManagementState {
  const MealManagementState({this.busyMealIds = const <String>{}});

  final Set<String> busyMealIds;

  bool isBusy(String mealId) => busyMealIds.contains(mealId);
}

class MealManagementResult {
  const MealManagementResult.success()
      : isSuccess = true,
        message = null,
        isConflict = false;

  const MealManagementResult.failure(
    this.message, {
    this.isConflict = false,
  }) : isSuccess = false;

  final bool isSuccess;
  final String? message;
  final bool isConflict;
}

final mealManagementControllerProvider =
    NotifierProvider<MealManagementController, MealManagementState>(
      MealManagementController.new,
    );

class MealManagementController extends Notifier<MealManagementState> {
  late final MealsRepository _mealsRepository;
  late final MealAiRepository _aiRepository;

  @override
  MealManagementState build() {
    _mealsRepository = ref.watch(mealsRepositoryProvider);
    _aiRepository = ref.watch(mealAiRepositoryProvider);
    return const MealManagementState();
  }

  Future<MealManagementResult> updatePortion(
    Meal meal,
    double portionRatio,
  ) {
    return updateMeal(
      meal,
      MealPatch(portionRatio: portionRatio),
    );
  }

  Future<MealManagementResult> updateDetails(
    Meal meal, {
    required String name,
    required num baseCalories,
    required num baseProtein,
    required num baseCarbs,
    required num baseFat,
  }) {
    return updateMeal(
      meal,
      MealPatch(
        name: name,
        baseCalories: baseCalories,
        baseProtein: baseProtein,
        baseCarbs: baseCarbs,
        baseFat: baseFat,
      ),
    );
  }

  Future<MealManagementResult> updateMeal(Meal meal, MealPatch patch) {
    final guardedPatch = MealPatch(
      name: patch.name,
      baseCalories: patch.baseCalories,
      baseProtein: patch.baseProtein,
      baseCarbs: patch.baseCarbs,
      baseFat: patch.baseFat,
      portionRatio: patch.portionRatio,
      shareMode: patch.shareMode,
      mealTime: patch.mealTime,
      dishes: patch.dishes,
      aiHint: patch.aiHint,
      originalInput: patch.originalInput,
      expectedUpdatedAt: meal.updatedAt,
    );
    return _mutate(
      meal.id,
      () async {
        await _mealsRepository.updateMeal(meal.id, guardedPatch);
      },
    );
  }

  Future<MealManagementResult> deleteMeal(Meal meal) {
    return _mutate(
      meal.id,
      () => _mealsRepository.deleteMeal(meal.id),
    );
  }

  Future<MealManagementResult> refineMeal(Meal meal, String newHint) async {
    final trimmedHint = newHint.trim();
    if (meal.source != MealSource.text) {
      return const MealManagementResult.failure('这条记录暂不支持重新估算');
    }
    if (trimmedHint.isEmpty) {
      return const MealManagementResult.failure('请输入补充说明');
    }

    return _mutate(meal.id, () async {
      final savedOriginal = meal.originalInput?.trim();
      final originalInput = savedOriginal == null || savedOriginal.isEmpty
          ? meal.name
          : savedOriginal;
      final mergedHint = _combine(meal.aiHint, trimmedHint);
      final result = await _aiRepository.analyzeText(
        _combine(originalInput, mergedHint),
      );
      await _mealsRepository.updateMeal(
        meal.id,
        MealPatch(
          name: result.name,
          baseCalories: result.calories,
          baseProtein: result.protein,
          baseCarbs: result.carbs,
          baseFat: result.fat,
          dishes: _dishesFrom(result),
          aiHint: mergedHint,
          originalInput: meal.originalInput,
          expectedUpdatedAt: meal.updatedAt,
        ),
      );
    });
  }

  Future<MealManagementResult> _mutate(
    String mealId,
    Future<void> Function() operation,
  ) async {
    if (state.isBusy(mealId)) {
      return const MealManagementResult.failure('正在处理，请稍候');
    }
    _setBusy(mealId, true);
    try {
      await operation();
      await ref.read(summaryControllerProvider.notifier).refresh();
      return const MealManagementResult.success();
    } on ConflictException {
      await ref.read(summaryControllerProvider.notifier).refresh();
      return const MealManagementResult.failure(
        '这条记录已经在其他地方被修改，请刷新后重试',
        isConflict: true,
      );
    } catch (error) {
      return MealManagementResult.failure(_messageFor(error));
    } finally {
      _setBusy(mealId, false);
    }
  }

  void _setBusy(String mealId, bool busy) {
    final next = {...state.busyMealIds};
    if (busy) {
      next.add(mealId);
    } else {
      next.remove(mealId);
    }
    state = MealManagementState(busyMealIds: Set.unmodifiable(next));
  }

  List<MealAiDish> _dishesFrom(MealAiResult result) => result.dishes
      .map(
        (dish) => dish is MealAiDish
            ? dish
            : MealAiDish(name: dish.toString()),
      )
      .toList(growable: false);

  String _combine(String? first, String? second) => [first, second]
      .whereType<String>()
      .map((value) => value.trim())
      .where((value) => value.isNotEmpty)
      .join('；');

  String _messageFor(Object error) {
    if (error is NetworkException) return '网络连接失败，请检查网络后重试';
    if (error is ValidationException) return '修改内容有误，请检查后重试';
    if (error is ServerException) return '服务器开小差了，请稍后重试';
    if (error is ApiException) return error.message;
    return '操作失败，请稍后重试';
  }
}
