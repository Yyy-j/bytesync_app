import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/core_providers.dart';
import 'remote_training_repository.dart';
import 'training_repository.dart';

final trainingRepositoryProvider = Provider<TrainingRepository>((ref) {
  return RemoteTrainingRepository(
    ref.watch(dioProvider),
    ref.watch(dioErrorMapperProvider),
  );
});
