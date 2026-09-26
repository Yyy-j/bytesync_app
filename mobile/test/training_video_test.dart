import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bytesync/core/network/api_endpoints.dart';
import 'package:bytesync/features/training/videos/data/dto/training_exercise_video_dtos.dart';
import 'package:bytesync/features/training/videos/data/training_exercise_video_providers.dart';
import 'package:bytesync/features/training/videos/data/training_exercise_video_repository.dart';
import 'package:bytesync/features/training/videos/domain/training_exercise_video.dart';
import 'package:bytesync/features/training/videos/presentation/training_exercise_video_controller.dart';

final _video = TrainingExerciseVideo(
  id: 'video-1',
  exerciseId: 'chest_press',
  videoUrl: Uri.parse('https://example.com/video'),
  createdAt: DateTime.utc(2026, 9, 14),
  updatedAt: DateTime.utc(2026, 9, 14),
);

class _FakeVideoRepository implements TrainingExerciseVideoRepository {
  final videos = <TrainingExerciseVideo>[_video];

  @override
  Future<List<TrainingExerciseVideo>> getVideos() async => List.of(videos);

  @override
  Future<TrainingExerciseVideo> putVideo({
    required String exerciseId,
    required String videoUrl,
  }) async {
    final value = TrainingExerciseVideo(
      id: 'video-1',
      exerciseId: exerciseId,
      videoUrl: Uri.parse(videoUrl),
      createdAt: _video.createdAt,
      updatedAt: DateTime.utc(2026, 9, 15),
    );
    videos
      ..removeWhere((video) => video.exerciseId == exerciseId)
      ..add(value);
    return value;
  }

  @override
  Future<void> deleteVideo(String exerciseId) async {
    videos.removeWhere((video) => video.exerciseId == exerciseId);
  }
}

void main() {
  test('video DTO and PUT request use frozen backend wire fields', () {
    final dto = TrainingExerciseVideoDto.fromJson({
      'id': 'video-1',
      'exercise_id': 'custom-uuid',
      'video_url': 'https://example.com/tutorial',
      'created_at': '2026-09-14T00:00:00Z',
      'updated_at': '2026-09-14T01:00:00Z',
    });
    expect(dto.exerciseId, 'custom-uuid');
    expect(dto.videoUrl, 'https://example.com/tutorial');
    expect(
      const PutTrainingExerciseVideoRequestDto('https://example.com/tutorial')
          .toJson(),
      {'video_url': 'https://example.com/tutorial'},
    );
  });

  test('exerciseId is URL encoded and remains the video map key', () async {
    expect(
      ApiEndpoints.trainingExerciseVideo('custom/id'),
      '/training/exercises/custom%2Fid/video',
    );
    final container = ProviderContainer(
      overrides: [
        trainingExerciseVideoRepositoryProvider.overrideWithValue(
          _FakeVideoRepository(),
        ),
      ],
    );
    addTearDown(container.dispose);
    await container
        .read(trainingExerciseVideoControllerProvider.notifier)
        .refresh();
    final ready = container.read(
      trainingExerciseVideoControllerProvider,
    ) as TrainingExerciseVideoReady;
    expect(ready.videos['chest_press']?.videoUrl, _video.videoUrl);
  });

  test('video controller upserts and deletes one exercise reference', () async {
    final repository = _FakeVideoRepository();
    final container = ProviderContainer(
      overrides: [
        trainingExerciseVideoRepositoryProvider.overrideWithValue(repository),
      ],
    );
    addTearDown(container.dispose);
    final controller = container.read(
      trainingExerciseVideoControllerProvider.notifier,
    );
    await controller.refresh();
    expect(
      (await controller.save(
        'chest_press',
        'https://example.com/new',
      )).isSuccess,
      isTrue,
    );
    expect(
      (container.read(
        trainingExerciseVideoControllerProvider,
      ) as TrainingExerciseVideoReady).videos['chest_press']?.videoUrl,
      Uri.parse('https://example.com/new'),
    );
    expect((await controller.delete('chest_press')).isSuccess, isTrue);
    expect(
      (container.read(
        trainingExerciseVideoControllerProvider,
      ) as TrainingExerciseVideoReady).videos,
      isEmpty,
    );
  });
}
