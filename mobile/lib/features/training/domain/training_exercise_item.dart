import 'training_set_detail.dart';

enum TrainingItemType {
  strength,
  duration,
  cardio;

  static TrainingItemType fromWire(String value) {
    return switch (value) {
      'strength' => TrainingItemType.strength,
      'duration' => TrainingItemType.duration,
      'cardio' => TrainingItemType.cardio,
      _ => throw FormatException('Unknown training item type: $value'),
    };
  }

  String toWire() => name;
}

class TrainingExerciseItem {
  const TrainingExerciseItem({
    required this.itemId,
    required this.exerciseId,
    required this.exerciseName,
    required this.itemType,
    required this.category,
    required this.targetSets,
    required this.targetReps,
    required this.targetWeight,
    required this.order,
    this.completedSets = 0,
    this.setDetails = const [],
    this.removedFromTemplate = false,
  });

  final String itemId;
  final String? exerciseId;
  final String exerciseName;
  final TrainingItemType itemType;
  final String category;
  final int targetSets;
  final int targetReps;
  final double targetWeight;
  final int order;
  final int completedSets;
  final List<TrainingSetDetail> setDetails;
  final bool removedFromTemplate;
}
