import 'training_exercise_item.dart';

class TrainingDay {
  const TrainingDay({
    required this.dayIndex,
    required this.exercises,
    this.date,
  });

  final int dayIndex;
  final DateTime? date;
  final List<TrainingExerciseItem> exercises;
}
