import '../../domain/training_day.dart';
import '../../domain/training_exercise_item.dart';
import '../../domain/training_set_detail.dart';

class SaveTrainingTemplateRequestDto {
  const SaveTrainingTemplateRequestDto(this.days);

  factory SaveTrainingTemplateRequestDto.fromDomain(List<TrainingDay> days) {
    return SaveTrainingTemplateRequestDto(days);
  }

  final List<TrainingDay> days;

  Map<String, dynamic> toJson() => {
    'days': days
        .map(
          (day) => {
            'day_index': day.dayIndex,
            'exercises': day.exercises.map(_exerciseJson).toList(growable: false),
          },
        )
        .toList(growable: false),
  };

  static Map<String, dynamic> _exerciseJson(TrainingExerciseItem exercise) => {
    'item_id': exercise.itemId,
    'exercise_id': exercise.exerciseId,
    'exercise_name': exercise.exerciseName,
    'item_type': exercise.itemType.toWire(),
    'category': exercise.category,
    'target_sets': exercise.targetSets,
    'target_reps': exercise.targetReps,
    'target_weight': exercise.targetWeight,
    'order': exercise.order,
  };
}

class CheckInTrainingSetRequestDto {
  const CheckInTrainingSetRequestDto(this.input);

  final TrainingSetInput input;

  Map<String, dynamic> toJson() => {
    'request_id': input.requestId,
    if (input.weight != null) 'weight': input.weight,
    if (input.reps != null) 'reps': input.reps,
    if (input.rpe != null) 'rpe': input.rpe,
    if (input.remark != null) 'remark': input.remark,
  };
}

class UpdateTrainingSetRequestDto {
  const UpdateTrainingSetRequestDto(this.patch);

  final TrainingSetDetailPatch patch;

  Map<String, dynamic> toJson() => {
    if (patch.weight.isPresent) 'weight': patch.weight.value,
    if (patch.reps.isPresent) 'reps': patch.reps.value,
    if (patch.rpe.isPresent) 'rpe': patch.rpe.value,
    if (patch.remark.isPresent) 'remark': patch.remark.value,
  };
}
