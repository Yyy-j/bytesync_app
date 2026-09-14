import '../../domain/training_exercise_item.dart';

class TrainingCustomExercise {
  const TrainingCustomExercise({
    required this.id,
    required this.name,
    required this.category,
    required this.itemType,
    required this.defaultSets,
    required this.defaultReps,
    required this.defaultWeight,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String name;
  final String category;
  final TrainingItemType itemType;
  final int defaultSets;
  final int defaultReps;
  final double defaultWeight;
  final DateTime createdAt;
  final DateTime updatedAt;

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

class TrainingCustomExerciseInput {
  const TrainingCustomExerciseInput({
    required this.name,
    required this.category,
    required this.itemType,
    required this.defaultSets,
    required this.defaultReps,
    required this.defaultWeight,
  });

  final String name;
  final String category;
  final TrainingItemType itemType;
  final int defaultSets;
  final int defaultReps;
  final double defaultWeight;
}

List<TrainingCustomExercise> filterTrainingCustomExercises(
  List<TrainingCustomExercise> exercises, {
  String query = '',
  String? category,
}) {
  final normalizedQuery = query.trim().toLowerCase();
  return exercises
      .where(
        (exercise) =>
            (category == null || exercise.category == category) &&
            (normalizedQuery.isEmpty ||
                exercise.name.toLowerCase().contains(normalizedQuery) ||
                exercise.category.toLowerCase().contains(normalizedQuery)),
      )
      .toList(growable: false);
}

List<String> trainingCustomExerciseCategories(
  List<TrainingCustomExercise> exercises,
) {
  final categories = <String>{};
  for (final exercise in exercises) {
    if (exercise.category.isNotEmpty) categories.add(exercise.category);
  }
  return categories.toList(growable: false);
}
