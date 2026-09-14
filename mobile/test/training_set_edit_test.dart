import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bytesync/features/training/data/dto/training_request_dtos.dart';
import 'package:bytesync/features/training/data/training_providers.dart';
import 'package:bytesync/features/training/data/training_repository.dart';
import 'package:bytesync/features/training/domain/training_day.dart';
import 'package:bytesync/features/training/domain/training_set_detail.dart';
import 'package:bytesync/features/training/domain/training_template.dart';
import 'package:bytesync/features/training/domain/training_week.dart';
import 'package:bytesync/features/training/presentation/training_controller.dart';

class _FakeTrainingRepository implements TrainingRepository {
  int currentWeekCalls = 0;
  String? updatedWeekId;
  String? updatedItemId;
  String? updatedRequestId;
  TrainingSetDetailPatch? updatedPatch;

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
    return TrainingSetUpdateResult(
      completedSets: 1,
      setDetail: _detail(),
    );
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
      rpe: TrainingPatchField<double>.value(null),
      remark: TrainingPatchField<String>.value(null),
    );

    expect(UpdateTrainingSetRequestDto(patch).toJson(), {
      'weight': null,
      'reps': null,
      'rpe': null,
      'remark': null,
    });
  });

  test('set edit uses public weekId and refreshes current week', () async {
    final repository = _FakeTrainingRepository();
    final container = ProviderContainer(
      overrides: [
        trainingRepositoryProvider.overrideWithValue(repository),
      ],
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
}
