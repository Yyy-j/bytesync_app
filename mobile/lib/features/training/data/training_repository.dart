import '../domain/training_day.dart';
import '../domain/training_set_detail.dart';
import '../domain/training_template.dart';
import '../domain/training_week.dart';
import '../exercises/domain/training_custom_exercise.dart';

abstract interface class TrainingRepository {
  Future<List<TrainingCustomExercise>> getCustomExercises();

  Future<TrainingCustomExercise> createCustomExercise(
    TrainingCustomExerciseInput input,
  );

  Future<TrainingCustomExercise> updateCustomExercise(
    String exerciseId,
    TrainingCustomExerciseInput input,
  );

  Future<void> deleteCustomExercise(String exerciseId);

  Future<TrainingTemplate?> getTemplate();

  Future<TrainingTemplate> saveTemplate(List<TrainingDay> days);

  Future<CurrentTrainingWeekResult> getCurrentWeek();

  Future<TrainingWeek> getWeek(String weekId);

  Future<TrainingWeekHistory> getWeekHistory({int limit = 20, int offset = 0});

  Future<SyncTrainingWeekResult> syncCurrentWeek();

  Future<TrainingSetCheckInResult> checkInSet({
    required String weekId,
    required String itemId,
    required TrainingSetInput input,
  });

  Future<TrainingSetUpdateResult> updateSetDetail({
    required String weekId,
    required String itemId,
    required String requestId,
    required TrainingSetDetailPatch patch,
  });
}
