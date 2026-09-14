import '../../domain/training_exercise_item.dart';

class FixedTrainingExercise {
  const FixedTrainingExercise({
    required this.id,
    required this.name,
    required this.englishName,
    required this.category,
    required this.itemType,
    required this.defaultSets,
    required this.defaultReps,
    required this.defaultWeight,
    this.defaultDuration = 0,
  });

  final String id;
  final String name;
  final String englishName;
  final String category;
  final TrainingItemType itemType;
  final int defaultSets;
  final int defaultReps;
  final double defaultWeight;
  final int defaultDuration;

  TrainingExerciseItem toTemplateItem({
    required String itemId,
    required int order,
  }) {
    return TrainingExerciseItem(
      itemId: itemId,
      exerciseId: id,
      exerciseName: name,
      itemType: itemType,
      category: category,
      targetSets: defaultSets,
      targetReps: defaultReps,
      targetWeight: defaultWeight,
      order: order,
    );
  }
}
