import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/core_providers.dart';
import 'remote_training_exercise_video_repository.dart';
import 'training_exercise_video_repository.dart';

final trainingExerciseVideoRepositoryProvider =
    Provider<TrainingExerciseVideoRepository>((ref) {
      return RemoteTrainingExerciseVideoRepository(
        ref.watch(dioProvider),
        ref.watch(dioErrorMapperProvider),
      );
    });
