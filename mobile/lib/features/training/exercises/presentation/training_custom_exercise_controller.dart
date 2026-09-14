import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_exception.dart';
import '../../data/training_providers.dart';
import '../../data/training_repository.dart';
import '../domain/training_custom_exercise.dart';

sealed class TrainingCustomExerciseState {
  const TrainingCustomExerciseState();
}

class TrainingCustomExerciseLoading extends TrainingCustomExerciseState {
  const TrainingCustomExerciseLoading();
}

class TrainingCustomExerciseFailure extends TrainingCustomExerciseState {
  const TrainingCustomExerciseFailure(this.message);

  final String message;
}

class TrainingCustomExerciseReady extends TrainingCustomExerciseState {
  const TrainingCustomExerciseReady({
    required this.exercises,
    this.mutating = false,
  });

  final List<TrainingCustomExercise> exercises;
  final bool mutating;
}

class TrainingCustomExerciseActionResult {
  const TrainingCustomExerciseActionResult.success()
    : errorMessage = null,
      isNotFound = false;

  const TrainingCustomExerciseActionResult.failure(
    this.errorMessage, {
    this.isNotFound = false,
  });

  final String? errorMessage;
  final bool isNotFound;
  bool get isSuccess => errorMessage == null;
}

final trainingCustomExerciseControllerProvider = NotifierProvider<
  TrainingCustomExerciseController,
  TrainingCustomExerciseState
>(TrainingCustomExerciseController.new);

class TrainingCustomExerciseController
    extends Notifier<TrainingCustomExerciseState> {
  late final TrainingRepository _repository;

  @override
  TrainingCustomExerciseState build() {
    _repository = ref.watch(trainingRepositoryProvider);
    _load();
    return const TrainingCustomExerciseLoading();
  }

  Future<void> load() => _load();

  Future<void> refresh() => _load();

  Future<void> _load() async {
    state = const TrainingCustomExerciseLoading();
    try {
      final exercises = await _repository.getCustomExercises();
      state = TrainingCustomExerciseReady(exercises: exercises);
    } catch (error) {
      state = TrainingCustomExerciseFailure(
        _message(error, fallback: '我的动作加载失败，请重试'),
      );
    }
  }

  Future<TrainingCustomExerciseActionResult> create(
    TrainingCustomExerciseInput input,
  ) {
    return _mutate(
      () async {
        await _repository.createCustomExercise(input);
      },
      fallback: '新增动作失败，请重试',
    );
  }

  Future<TrainingCustomExerciseActionResult> update(
    String exerciseId,
    TrainingCustomExerciseInput input,
  ) {
    return _mutate(
      () async {
        await _repository.updateCustomExercise(exerciseId, input);
      },
      fallback: '编辑动作失败，请重试',
    );
  }

  Future<TrainingCustomExerciseActionResult> delete(String exerciseId) {
    return _mutate(
      () => _repository.deleteCustomExercise(exerciseId),
      fallback: '删除动作失败，请重试',
      refreshOnNotFound: true,
    );
  }

  Future<TrainingCustomExerciseActionResult> _mutate(
    Future<void> Function() operation, {
    required String fallback,
    bool refreshOnNotFound = false,
  }) async {
    final current = state;
    if (current is! TrainingCustomExerciseReady || current.mutating) {
      return const TrainingCustomExerciseActionResult.failure(
        '动作库尚未就绪，请稍后重试',
      );
    }
    state = TrainingCustomExerciseReady(
      exercises: current.exercises,
      mutating: true,
    );
    try {
      await operation();
      final exercises = await _repository.getCustomExercises();
      state = TrainingCustomExerciseReady(exercises: exercises);
      return const TrainingCustomExerciseActionResult.success();
    } catch (error) {
      if (refreshOnNotFound && error is NotFoundException) {
        try {
          final exercises = await _repository.getCustomExercises();
          state = TrainingCustomExerciseReady(exercises: exercises);
        } catch (_) {
          state = TrainingCustomExerciseReady(exercises: current.exercises);
        }
        return const TrainingCustomExerciseActionResult.failure(
          '动作已不存在，列表已刷新',
          isNotFound: true,
        );
      }
      state = TrainingCustomExerciseReady(exercises: current.exercises);
      return TrainingCustomExerciseActionResult.failure(
        _message(error, fallback: fallback),
        isNotFound: error is NotFoundException,
      );
    }
  }
}

String _message(Object error, {required String fallback}) {
  return error is ApiException ? error.message : fallback;
}
