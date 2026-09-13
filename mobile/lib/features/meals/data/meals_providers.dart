import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/core_providers.dart';
import 'meals_repository.dart';
import 'remote_meals_repository.dart';
import 'meal_ai_repository.dart';
import 'remote_meal_ai_repository.dart';

final mealsRepositoryProvider = Provider<MealsRepository>((ref) {
  return RemoteMealsRepository(
    ref.watch(dioProvider),
    ref.watch(dioErrorMapperProvider),
  );
});

final mealAiRepositoryProvider = Provider<MealAiRepository>((ref) {
  return RemoteMealAiRepository(
    ref.watch(dioProvider),
    ref.watch(dioErrorMapperProvider),
  );
});
