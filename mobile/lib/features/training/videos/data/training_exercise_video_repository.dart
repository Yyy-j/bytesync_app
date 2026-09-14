import '../domain/training_exercise_video.dart';

abstract interface class TrainingExerciseVideoRepository {
  Future<List<TrainingExerciseVideo>> getVideos();

  Future<TrainingExerciseVideo> putVideo({
    required String exerciseId,
    required String videoUrl,
  });

  Future<void> deleteVideo(String exerciseId);
}
