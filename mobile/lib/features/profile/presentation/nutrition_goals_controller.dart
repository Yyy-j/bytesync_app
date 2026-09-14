import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../../summary/presentation/summary_controller.dart';
import '../data/user_providers.dart';
import '../data/user_repository.dart';
import '../domain/user_profile.dart';

sealed class NutritionGoalsState {
  const NutritionGoalsState();
}

class NutritionGoalsLoading extends NutritionGoalsState {
  const NutritionGoalsLoading();
}

class NutritionGoalsFailure extends NutritionGoalsState {
  const NutritionGoalsFailure(this.message);

  final String message;
}

class NutritionGoalsReady extends NutritionGoalsState {
  const NutritionGoalsReady({required this.profile, this.saving = false});

  final UserProfile profile;
  final bool saving;
}

class NutritionGoalsSaveResult {
  const NutritionGoalsSaveResult.success() : errorMessage = null;
  const NutritionGoalsSaveResult.failure(this.errorMessage);

  final String? errorMessage;
  bool get isSuccess => errorMessage == null;
}

final nutritionGoalsControllerProvider = NotifierProvider.autoDispose<
  NutritionGoalsController,
  NutritionGoalsState
>(NutritionGoalsController.new);

class NutritionGoalsController extends AutoDisposeNotifier<NutritionGoalsState> {
  late final UserRepository _repository;

  @override
  NutritionGoalsState build() {
    _repository = ref.watch(userRepositoryProvider);
    _load();
    return const NutritionGoalsLoading();
  }

  Future<void> _load() async {
    state = const NutritionGoalsLoading();
    try {
      state = NutritionGoalsReady(profile: await _repository.getProfile());
    } catch (error) {
      state = NutritionGoalsFailure(_message(error, '营养目标加载失败，请重试'));
    }
  }

  Future<void> refresh() => _load();

  Future<NutritionGoalsSaveResult> save(NutritionGoals goals) async {
    final current = state;
    if (current is! NutritionGoalsReady || current.saving) {
      return const NutritionGoalsSaveResult.failure('当前无法保存，请稍后重试');
    }
    state = NutritionGoalsReady(profile: current.profile, saving: true);
    try {
      final profile = await _repository.updateNutritionGoals(goals);
      await ref.read(summaryControllerProvider.notifier).refresh();
      state = NutritionGoalsReady(profile: profile);
      return const NutritionGoalsSaveResult.success();
    } catch (error) {
      state = NutritionGoalsReady(profile: current.profile);
      return NutritionGoalsSaveResult.failure(
        _message(error, '营养目标保存失败，请重试'),
      );
    }
  }

  String _message(Object error, String fallback) {
    return error is ApiException ? error.message : fallback;
  }
}
