import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bytesync/features/training/data/dto/training_request_dtos.dart';
import 'package:bytesync/features/training/data/training_providers.dart';
import 'package:bytesync/features/training/data/training_repository.dart';
import 'package:bytesync/features/training/domain/training_day.dart';
import 'package:bytesync/features/training/domain/training_set_detail.dart';
import 'package:bytesync/features/training/domain/training_template.dart';
import 'package:bytesync/features/training/domain/training_week.dart';
import 'package:bytesync/features/training/exercises/domain/training_custom_exercise.dart';
import 'package:bytesync/features/training/presentation/training_controller.dart';

class _FakeTrainingRepository implements TrainingRepository {
  int currentWeekCalls = 0;
  String? updatedWeekId;
  String? updatedItemId;
  String? updatedRequestId;
  TrainingSetDetailPatch? updatedPatch;
  String? deletedWeekId;
  String? deletedItemId;
  String? deletedRequestId;

  @override
  Future<List<TrainingCustomExercise>> getCustomExercises() =>
      throw UnimplementedError();

  @override
  Future<TrainingCustomExercise> createCustomExercise(
    TrainingCustomExerciseInput input,
  ) => throw UnimplementedError();

  @override
  Future<TrainingCustomExercise> updateCustomExercise(
    String exerciseId,
    TrainingCustomExerciseInput input,
  ) => throw UnimplementedError();

  @override
  Future<void> deleteCustomExercise(String exerciseId) =>
      throw UnimplementedError();

  @override
  Future<CurrentTrainingWeekResult> getCurrentWeek() async {
    currentWeekCalls++;
    return CurrentTrainingWeekResult(week: _week(), created: false);
  }

  @override
  Future<TrainingSetUpdateResult> updateSetDetail({
    required String weekId,
    required String itemId,
    required String requestId,
    required TrainingSetDetailPatch patch,
  }) async {
    updatedWeekId = weekId;
    updatedItemId = itemId;
    updatedRequestId = requestId;
    updatedPatch = patch;
    return TrainingSetUpdateResult(completedSets: 1, setDetail: _detail());
  }

  @override
  Future<void> deleteSetDetail({
    required String weekId,
    required String itemId,
    required String requestId,
  }) async {
    deletedWeekId = weekId;
    deletedItemId = itemId;
    deletedRequestId = requestId;
  }

  @override
  Future<TrainingSetCheckInResult> checkInSet({
    required String weekId,
    required String itemId,
    required TrainingSetInput input,
  }) => throw UnimplementedError();

  @override
  Future<TrainingTemplate?> getTemplate() => throw UnimplementedError();

  @override
  Future<TrainingWeek> getWeek(String weekId) => throw UnimplementedError();

  @override
  Future<TrainingWeekHistory> getWeekHistory({
    int limit = 20,
    int offset = 0,
  }) => throw UnimplementedError();

  @override
  Future<TrainingTemplate> saveTemplate(List<TrainingDay> days) =>
      throw UnimplementedError();

  @override
  Future<SyncTrainingWeekResult> syncCurrentWeek() =>
      throw UnimplementedError();
}

TrainingSetDetail _detail() => TrainingSetDetail(
  requestId: 'request-1',
  setIndex: 1,
  weight: 60,
  reps: 10,
  durationSeconds: null,
  rpe: 8,
  remark: '状态不错',
  completedAt: DateTime.utc(2026, 9, 14, 3),
);

TrainingWeek _week() => TrainingWeek(
  id: 'internal-week-uuid',
  weekId: '2026-W38',
  weekStart: DateTime(2026, 9, 14),
  weekEnd: DateTime(2026, 9, 20),
  templateVersion: 1,
  snapshotAt: DateTime.utc(2026, 9, 14),
  syncedAt: null,
  days: const [TrainingDay(dayIndex: 0, exercises: [])],
  createdAt: DateTime.utc(2026, 9, 14),
  updatedAt: DateTime.utc(2026, 9, 14),
);

void main() {
  test('explicit null set fields serialize as null instead of absent', () {
    const patch = TrainingSetDetailPatch(
      weight: TrainingPatchField<double>.value(null),
      reps: TrainingPatchField<int>.value(null),
      durationSeconds: TrainingPatchField<int>.value(null),
      rpe: TrainingPatchField<double>.value(null),
      remark: TrainingPatchField<String>.value(null),
    );

    expect(UpdateTrainingSetRequestDto(patch).toJson(), {
      'weight': null,
      'reps': null,
      'duration_seconds': null,
      'rpe': null,
      'remark': null,
    });
  });

  test('set check-in sends duration without putting it in reps', () {
    const input = TrainingSetInput(
      requestId: 'request-duration',
      durationSeconds: 630,
      rpe: 7,
    );

    expect(CheckInTrainingSetRequestDto(input).toJson(), {
      'request_id': 'request-duration',
      'duration_seconds': 630,
      'rpe': 7,
    });
  });

  test('strength set check-in keeps weight and reps wire behavior', () {
    const input = TrainingSetInput(
      requestId: 'request-strength',
      weight: 60,
      reps: 10,
      rpe: 8,
      remark: '状态不错',
    );

    expect(CheckInTrainingSetRequestDto(input).toJson(), {
      'request_id': 'request-strength',
      'weight': 60,
      'reps': 10,
      'rpe': 8,
      'remark': '状态不错',
    });
  });

  test('set PATCH sends duration and supports explicit null', () {
    const valuePatch = TrainingSetDetailPatch(
      durationSeconds: TrainingPatchField<int>.value(90),
    );
    const nullPatch = TrainingSetDetailPatch(
      durationSeconds: TrainingPatchField<int>.value(null),
    );

    expect(UpdateTrainingSetRequestDto(valuePatch).toJson(), {
      'duration_seconds': 90,
    });
    expect(UpdateTrainingSetRequestDto(nullPatch).toJson(), {
      'duration_seconds': null,
    });
  });

  test('set edit uses public weekId and refreshes current week', () async {
    final repository = _FakeTrainingRepository();
    final container = ProviderContainer(
      overrides: [trainingRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(container.dispose);
    final controller = container.read(trainingControllerProvider.notifier);
    await controller.refresh();
    final callsBeforeUpdate = repository.currentWeekCalls;
    const patch = TrainingSetDetailPatch(
      weight: TrainingPatchField<double>.value(62.5),
      reps: TrainingPatchField<int>.value(9),
      rpe: TrainingPatchField<double>.value(8.5),
      remark: TrainingPatchField<String>.value('最后一组'),
    );

    final outcome = await controller.updateSetDetail(
      itemId: 'item-1',
      requestId: 'request-1',
      patch: patch,
    );

    expect(outcome.isSuccess, isTrue);
    expect(repository.updatedWeekId, '2026-W38');
    expect(repository.updatedWeekId, isNot('internal-week-uuid'));
    expect(repository.updatedItemId, 'item-1');
    expect(repository.updatedRequestId, 'request-1');
    expect(repository.updatedPatch, same(patch));
    expect(repository.currentWeekCalls, callsBeforeUpdate + 1);
  });

  test('set delete uses public weekId and preserves selected day', () async {
    final repository = _FakeTrainingRepository();
    final container = ProviderContainer(
      overrides: [trainingRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(container.dispose);
    final controller = container.read(trainingControllerProvider.notifier);
    await controller.refresh();

    final outcome = await controller.deleteSetDetail(
      itemId: 'item-1',
      requestId: 'request-1',
    );

    expect(outcome.isSuccess, isTrue);
    expect(repository.deletedWeekId, '2026-W38');
    expect(repository.deletedItemId, 'item-1');
    expect(repository.deletedRequestId, 'request-1');
    final state = container.read(trainingControllerProvider);
    expect(state, isA<TrainingReady>());
    expect((state as TrainingReady).selectedDayIndex, 0);
  });
}
