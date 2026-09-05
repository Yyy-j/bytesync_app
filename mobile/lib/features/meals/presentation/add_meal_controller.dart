import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../data/meals_providers.dart';
import '../data/meals_repository.dart';
import '../domain/meal.dart';
import '../domain/meal_patch.dart';

/// State for the add-meal form's submit action. Kept separate from the
/// form's local field state (which stays in the page as plain
/// `TextEditingController`s) — this only tracks the network/repository
/// call.
sealed class AddMealState {
  const AddMealState();
}

class AddMealIdle extends AddMealState {
  const AddMealIdle();
}

class AddMealSaving extends AddMealState {
  const AddMealSaving();
}

class AddMealSuccess extends AddMealState {
  const AddMealSuccess(this.meal);

  final Meal meal;
}

class AddMealError extends AddMealState {
  const AddMealError(this.message);

  final String message;
}

final addMealControllerProvider =
    NotifierProvider.autoDispose<AddMealController, AddMealState>(
      AddMealController.new,
    );

class AddMealController extends AutoDisposeNotifier<AddMealState> {
  late final MealsRepository _repository;

  @override
  AddMealState build() {
    _repository = ref.watch(mealsRepositoryProvider);
    return const AddMealIdle();
  }

  Future<bool> submit(NewMealInput input) async {
    state = const AddMealSaving();
    try {
      final meal = await _repository.addMeal(input);
      state = AddMealSuccess(meal);
      return true;
    } catch (e) {
      state = AddMealError(e is ApiException ? e.message : '保存失败，请重试');
      return false;
    }
  }
}
