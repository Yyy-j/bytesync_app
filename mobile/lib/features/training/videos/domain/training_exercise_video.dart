class TrainingExerciseVideo {
  const TrainingExerciseVideo({
    required this.id,
    required this.exerciseId,
    required this.videoUrl,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String exerciseId;
  final Uri videoUrl;
  final DateTime createdAt;
  final DateTime updatedAt;
}
