import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_exception.dart';
import '../data/training_exercise_video_providers.dart';
import '../data/training_exercise_video_repository.dart';
import '../domain/training_exercise_video.dart';

sealed class TrainingExerciseVideoState {
  const TrainingExerciseVideoState();
}

class TrainingExerciseVideoLoading extends TrainingExerciseVideoState {
  const TrainingExerciseVideoLoading();
}

class TrainingExerciseVideoFailure extends TrainingExerciseVideoState {
  const TrainingExerciseVideoFailure(this.message);

  final String message;
}

class TrainingExerciseVideoReady extends TrainingExerciseVideoState {
  const TrainingExerciseVideoReady({required this.videos, this.mutating = false});

  final Map<String, TrainingExerciseVideo> videos;
  final bool mutating;
}

class TrainingExerciseVideoActionResult {
  const TrainingExerciseVideoActionResult.success() : errorMessage = null;
  const TrainingExerciseVideoActionResult.failure(this.errorMessage);

  final String? errorMessage;
  bool get isSuccess => errorMessage == null;
}

final trainingExerciseVideoControllerProvider = NotifierProvider.autoDispose<
  TrainingExerciseVideoController,
  TrainingExerciseVideoState
>(TrainingExerciseVideoController.new);

class TrainingExerciseVideoController
    extends AutoDisposeNotifier<TrainingExerciseVideoState> {
  late final TrainingExerciseVideoRepository _repository;

  @override
  TrainingExerciseVideoState build() {
    _repository = ref.watch(trainingExerciseVideoRepositoryProvider);
    _load();
    return const TrainingExerciseVideoLoading();
  }

  Future<void> refresh() => _load();

  Future<void> _load() async {
    try {
      final videos = await _repository.getVideos();
      state = TrainingExerciseVideoReady(
        videos: {for (final video in videos) video.exerciseId: video},
      );
    } catch (error) {
      state = TrainingExerciseVideoFailure(_message(error));
    }
  }

  Future<TrainingExerciseVideoActionResult> save(
    String exerciseId,
    String videoUrl,
  ) async {
    final current = state;
    if (current is! TrainingExerciseVideoReady || current.mutating) {
      return const TrainingExerciseVideoActionResult.failure('视频列表尚未就绪');
    }
    state = TrainingExerciseVideoReady(videos: current.videos, mutating: true);
    try {
      final saved = await _repository.putVideo(
        exerciseId: exerciseId,
        videoUrl: videoUrl,
      );
      state = TrainingExerciseVideoReady(
        videos: {...current.videos, exerciseId: saved},
      );
      return const TrainingExerciseVideoActionResult.success();
    } catch (error) {
      state = TrainingExerciseVideoReady(videos: current.videos);
      return TrainingExerciseVideoActionResult.failure(_message(error));
    }
  }

  Future<TrainingExerciseVideoActionResult> delete(String exerciseId) async {
    final current = state;
    if (current is! TrainingExerciseVideoReady || current.mutating) {
      return const TrainingExerciseVideoActionResult.failure('视频列表尚未就绪');
    }
    state = TrainingExerciseVideoReady(videos: current.videos, mutating: true);
    try {
      await _repository.deleteVideo(exerciseId);
      final videos = Map<String, TrainingExerciseVideo>.from(current.videos)
        ..remove(exerciseId);
      state = TrainingExerciseVideoReady(videos: videos);
      return const TrainingExerciseVideoActionResult.success();
    } catch (error) {
      state = TrainingExerciseVideoReady(videos: current.videos);
      return TrainingExerciseVideoActionResult.failure(_message(error));
    }
  }

  String _message(Object error) {
    return error is ApiException ? error.message : '教学视频操作失败，请重试';
  }
}
