import '../../domain/training_day.dart';
import '../../domain/training_exercise_item.dart';
import '../../domain/training_set_detail.dart';
import '../../exercises/domain/training_custom_exercise.dart';

class CreateTrainingCustomExerciseRequestDto {
  const CreateTrainingCustomExerciseRequestDto(this.input);

  final TrainingCustomExerciseInput input;

  Map<String, dynamic> toJson() => _trainingCustomExerciseJson(input);
}

class UpdateTrainingCustomExerciseRequestDto {
  const UpdateTrainingCustomExerciseRequestDto(this.input);

  final TrainingCustomExerciseInput input;

  Map<String, dynamic> toJson() => _trainingCustomExerciseJson(input);
}

Map<String, dynamic> _trainingCustomExerciseJson(
  TrainingCustomExerciseInput input,
) => {
  'name': input.name,
  'category': input.category,
  'item_type': input.itemType.toWire(),
  'default_sets': input.defaultSets,
  'default_reps': input.defaultReps,
  'default_weight': input.defaultWeight,
  'default_duration_seconds': input.defaultDurationSeconds,
};

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
            'exercises': day.exercises
                .map(_exerciseJson)
                .toList(growable: false),
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
    'target_duration_seconds': exercise.targetDurationSeconds,
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
    if (input.durationSeconds != null)
      'duration_seconds': input.durationSeconds,
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
    if (patch.durationSeconds.isPresent)
      'duration_seconds': patch.durationSeconds.value,
    if (patch.rpe.isPresent) 'rpe': patch.rpe.value,
    if (patch.remark.isPresent) 'remark': patch.remark.value,
  };
}
