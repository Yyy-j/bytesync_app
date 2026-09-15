import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bytesync/l10n/l10n.dart';

import '../../data/training_providers.dart';
import '../../data/training_repository.dart';
import '../../domain/training_day.dart';
import '../../domain/training_exercise_item.dart';
import '../training_controller.dart';

sealed class TrainingTemplateState {
  const TrainingTemplateState();
}

class TrainingTemplateLoading extends TrainingTemplateState {
  const TrainingTemplateLoading();
}

class TrainingTemplateFailure extends TrainingTemplateState {
  const TrainingTemplateFailure(this.message);

  final String message;
}

class TrainingTemplateReady extends TrainingTemplateState {
  const TrainingTemplateReady({
    required this.days,
    this.saving = false,
    this.syncing = false,
    this.hasSavedTemplate = false,
    this.hasUnsavedChanges = false,
  });

  final List<TrainingDay> days;
  final bool saving;
  final bool syncing;
  final bool hasSavedTemplate;
  final bool hasUnsavedChanges;

  bool get busy => saving || syncing;
  bool get canSync => hasSavedTemplate && !hasUnsavedChanges;
}

class TemplateActionResult {
  const TemplateActionResult.success() : errorMessage = null;
  const TemplateActionResult.failure(this.errorMessage);

  final String? errorMessage;
  bool get isSuccess => errorMessage == null;
}

final trainingTemplateControllerProvider =
    NotifierProvider<TrainingTemplateController, TrainingTemplateState>(
      TrainingTemplateController.new,
    );

class TrainingTemplateController extends Notifier<TrainingTemplateState> {
  late final TrainingRepository _repository;

  @override
  TrainingTemplateState build() {
    _repository = ref.watch(trainingRepositoryProvider);
    _load();
    return const TrainingTemplateLoading();
  }

  Future<void> _load() async {
    state = const TrainingTemplateLoading();
    try {
      final template = await _repository.getTemplate();
      state = TrainingTemplateReady(
        days: template?.days ?? _emptyWeek(),
        hasSavedTemplate: template != null,
      );
    } catch (error) {
      state = TrainingTemplateFailure(
        trainingErrorMessage(error, fallback: appL10n.trainingLoadFailed),
      );
    }
  }

  Future<void> refresh() => _load();

  String newItemId() => newTrainingTemplateItemId();

  void addExercise(int dayIndex, TrainingExerciseItem exercise) {
    final current = state;
    if (current is! TrainingTemplateReady || current.busy) return;
    _replaceDay(current, dayIndex, [
      ..._day(current.days, dayIndex).exercises,
      exercise,
    ]);
  }

  void updateExercise(int dayIndex, TrainingExerciseItem exercise) {
    final current = state;
    if (current is! TrainingTemplateReady || current.busy) return;
    final exercises = _day(current.days, dayIndex).exercises
        .map((value) => value.itemId == exercise.itemId ? exercise : value)
        .toList(growable: false);
    _replaceDay(current, dayIndex, exercises);
  }

  void deleteExercise(int dayIndex, String itemId) {
    final current = state;
    if (current is! TrainingTemplateReady || current.busy) return;
    final exercises = _day(current.days, dayIndex).exercises
        .where((value) => value.itemId != itemId)
        .toList(growable: false);
    _replaceDay(current, dayIndex, exercises);
  }

  Future<TemplateActionResult> save() async {
    final current = state;
    if (current is! TrainingTemplateReady || current.busy) {
      return TemplateActionResult.failure(appL10n.errorCannotSaveNow);
    }
    state = TrainingTemplateReady(
      days: current.days,
      saving: true,
      hasSavedTemplate: current.hasSavedTemplate,
      hasUnsavedChanges: current.hasUnsavedChanges,
    );
    try {
      final saved = await _repository.saveTemplate(current.days);
      state = TrainingTemplateReady(days: saved.days, hasSavedTemplate: true);
      return const TemplateActionResult.success();
    } catch (error) {
      state = TrainingTemplateReady(
        days: current.days,
        hasSavedTemplate: current.hasSavedTemplate,
        hasUnsavedChanges: current.hasUnsavedChanges,
      );
      return TemplateActionResult.failure(
        trainingErrorMessage(
          error,
          fallback: appL10n.trainingTemplateSaveFailed,
        ),
      );
    }
  }

  Future<TemplateActionResult> syncCurrentWeek() async {
    final current = state;
    if (current is! TrainingTemplateReady || current.busy || !current.canSync) {
      return TemplateActionResult.failure(
        appL10n.trainingTemplateSyncUnavailable,
      );
    }
    state = TrainingTemplateReady(
      days: current.days,
      syncing: true,
      hasSavedTemplate: true,
    );
    try {
      await _repository.syncCurrentWeek();
      state = TrainingTemplateReady(days: current.days, hasSavedTemplate: true);
      return const TemplateActionResult.success();
    } catch (error) {
      state = TrainingTemplateReady(days: current.days, hasSavedTemplate: true);
      return TemplateActionResult.failure(
        trainingErrorMessage(
          error,
          fallback: appL10n.trainingTemplateSyncFailed,
        ),
      );
    }
  }

  void _replaceDay(
    TrainingTemplateReady current,
    int dayIndex,
    List<TrainingExerciseItem> exercises,
  ) {
    final ordered = exercises
        .asMap()
        .entries
        .map((entry) => _copyWithOrder(entry.value, entry.key))
        .toList(growable: false);
    final days = current.days
        .map(
          (day) => day.dayIndex == dayIndex
              ? TrainingDay(dayIndex: dayIndex, exercises: ordered)
              : day,
        )
        .toList(growable: false);
    state = TrainingTemplateReady(
      days: days,
      hasSavedTemplate: current.hasSavedTemplate,
      hasUnsavedChanges: true,
    );
  }

  TrainingDay _day(List<TrainingDay> days, int dayIndex) {
    return days.firstWhere((day) => day.dayIndex == dayIndex);
  }

  List<TrainingDay> _emptyWeek() {
    return List.generate(
      7,
      (dayIndex) => TrainingDay(dayIndex: dayIndex, exercises: const []),
      growable: false,
    );
  }

  TrainingExerciseItem _copyWithOrder(TrainingExerciseItem item, int order) {
    return TrainingExerciseItem(
      itemId: item.itemId,
      exerciseId: item.exerciseId,
      exerciseName: item.exerciseName,
      itemType: item.itemType,
      category: item.category,
      targetSets: item.targetSets,
      targetReps: item.targetReps,
      targetWeight: item.targetWeight,
      targetDurationSeconds: item.targetDurationSeconds,
      order: order,
      completedSets: item.completedSets,
      setDetails: item.setDetails,
      removedFromTemplate: item.removedFromTemplate,
    );
  }
}

String newTrainingTemplateItemId() {
  final random = Random.secure().nextInt(0x7fffffff).toRadixString(36);
  final time = DateTime.now().microsecondsSinceEpoch.toRadixString(36);
  return 'item-$time-$random';
}
