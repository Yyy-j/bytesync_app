import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bytesync/core/network/api_exception.dart';
import 'package:bytesync/features/training/data/dto/training_dtos.dart';
import 'package:bytesync/features/training/data/dto/training_request_dtos.dart';
import 'package:bytesync/features/training/data/mappers/training_mapper.dart';
import 'package:bytesync/features/training/data/training_providers.dart';
import 'package:bytesync/features/training/data/training_repository.dart';
import 'package:bytesync/features/training/domain/training_day.dart';
import 'package:bytesync/features/training/domain/training_exercise_item.dart';
import 'package:bytesync/features/training/domain/training_set_detail.dart';
import 'package:bytesync/features/training/domain/training_template.dart';
import 'package:bytesync/features/training/domain/training_week.dart';
import 'package:bytesync/features/training/exercises/domain/training_custom_exercise.dart';
import 'package:bytesync/features/training/exercises/presentation/training_custom_exercise_controller.dart';

const _uuid = '56b54aa7-ec2d-41a3-891f-ff9ca15e9012';
const _secondUuid = 'bd4ab1d6-e3bd-449c-a695-740b98722eb8';

TrainingCustomExercise _exercise({
  String id = _uuid,
  String name = '保加利亚分腿蹲',
  String category = '腿部',
  TrainingItemType itemType = TrainingItemType.strength,
  int defaultSets = 3,
  int defaultReps = 10,
  double defaultWeight = 10,
  int? defaultDurationSeconds,
}) {
  return TrainingCustomExercise(
    id: id,
    name: name,
    category: category,
    itemType: itemType,
    defaultSets: defaultSets,
    defaultReps: defaultReps,
    defaultWeight: defaultWeight,
    defaultDurationSeconds: defaultDurationSeconds,
    createdAt: DateTime.utc(2026, 9, 14),
    updatedAt: DateTime.utc(2026, 9, 14),
  );
}

const _input = TrainingCustomExerciseInput(
  name: '划船机',
  category: '有氧',
  itemType: TrainingItemType.cardio,
  defaultSets: 4,
  defaultReps: 20,
  defaultWeight: 12.5,
  defaultDurationSeconds: 1200,
);

class _FakeTrainingRepository implements TrainingRepository {
  final exercises = <TrainingCustomExercise>[_exercise()];
  int getCustomExercisesCalls = 0;
  int createCalls = 0;
  int updateCalls = 0;
  int deleteCalls = 0;
  bool deleteAsNotFound = false;

  @override
  Future<List<TrainingCustomExercise>> getCustomExercises() async {
    getCustomExercisesCalls++;
    return List.unmodifiable(exercises);
  }

  @override
  Future<TrainingCustomExercise> createCustomExercise(
    TrainingCustomExerciseInput input,
  ) async {
    createCalls++;
    final created = _fromInput(_secondUuid, input);
    exercises.insert(0, created);
    return created;
  }

  @override
  Future<TrainingCustomExercise> updateCustomExercise(
    String exerciseId,
    TrainingCustomExerciseInput input,
  ) async {
    updateCalls++;
    final updated = _fromInput(exerciseId, input);
    final index = exercises.indexWhere((value) => value.id == exerciseId);
    exercises[index] = updated;
    return updated;
  }

  @override
  Future<void> deleteCustomExercise(String exerciseId) async {
    deleteCalls++;
    if (deleteAsNotFound) throw NotFoundException();
    exercises.removeWhere((value) => value.id == exerciseId);
  }

  TrainingCustomExercise _fromInput(
    String id,
    TrainingCustomExerciseInput input,
  ) {
    return _exercise(
      id: id,
      name: input.name,
      category: input.category,
      itemType: input.itemType,
      defaultSets: input.defaultSets,
      defaultReps: input.defaultReps,
      defaultWeight: input.defaultWeight,
      defaultDurationSeconds: input.defaultDurationSeconds,
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
  Future<CurrentTrainingWeekResult> getCurrentWeek() =>
      throw UnimplementedError();

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

  @override
  Future<TrainingSetUpdateResult> updateSetDetail({
    required String weekId,
    required String itemId,
    required String requestId,
    required TrainingSetDetailPatch patch,
  }) => throw UnimplementedError();

  @override
  Future<void> deleteSetDetail({
    required String weekId,
    required String itemId,
    required String requestId,
  }) => throw UnimplementedError();
}

void main() {
  test('custom exercise list DTO parses every wire field', () {
    final response = TrainingCustomExerciseListResponseDto.fromJson({
      'exercises': [
        {
          'id': _uuid,
          'name': '保加利亚分腿蹲',
          'category': '腿部',
          'item_type': 'duration',
          'default_sets': 3,
          'default_reps': 10,
          'default_weight': 12.5,
          'default_duration_seconds': 90,
          'created_at': '2026-09-14T01:02:03Z',
          'updated_at': '2026-09-14T04:05:06Z',
        },
      ],
    });
    final exercise = TrainingMapper.customExerciseFromDto(
      response.exercises.single,
    );

    expect(exercise.id, _uuid);
    expect(exercise.name, '保加利亚分腿蹲');
    expect(exercise.category, '腿部');
    expect(exercise.itemType, TrainingItemType.duration);
    expect(exercise.defaultSets, 3);
    expect(exercise.defaultReps, 10);
    expect(exercise.defaultWeight, 12.5);
    expect(exercise.defaultDurationSeconds, 90);
    expect(exercise.createdAt, DateTime.utc(2026, 9, 14, 1, 2, 3));
    expect(exercise.updatedAt, DateTime.utc(2026, 9, 14, 4, 5, 6));
  });

  test('old custom exercise DTO without duration maps it to null', () {
    final dto = TrainingCustomExerciseDto.fromJson({
      'id': _uuid,
      'name': '旧动作',
      'category': '核心',
      'item_type': 'duration',
      'default_sets': 3,
      'default_reps': 0,
      'default_weight': 0,
      'created_at': '2026-09-14T01:02:03Z',
      'updated_at': '2026-09-14T04:05:06Z',
    });

    expect(
      TrainingMapper.customExerciseFromDto(dto).defaultDurationSeconds,
      isNull,
    );
  });

  test('create and update requests use backend wire names', () {
    final expected = {
      'name': '划船机',
      'category': '有氧',
      'item_type': 'cardio',
      'default_sets': 4,
      'default_reps': 20,
      'default_weight': 12.5,
      'default_duration_seconds': 1200,
    };

    expect(CreateTrainingCustomExerciseRequestDto(_input).toJson(), expected);
    expect(UpdateTrainingCustomExerciseRequestDto(_input).toJson(), expected);
  });

  test(
    'custom exercise maps UUID and snapshots catalog fields to template',
    () {
      final catalogExercise = _exercise(
        itemType: TrainingItemType.cardio,
        defaultSets: 2,
        defaultReps: 30,
        defaultWeight: 5,
        defaultDurationSeconds: 600,
      );
      final item = catalogExercise.toTemplateItem(itemId: 'item-new', order: 4);

      expect(item.itemId, 'item-new');
      expect(item.exerciseId, _uuid);
      expect(item.exerciseId, isNot(startsWith('custom:')));
      expect(item.exerciseName, catalogExercise.name);
      expect(item.itemType, TrainingItemType.cardio);
      expect(item.category, catalogExercise.category);
      expect(item.targetSets, 2);
      expect(item.targetReps, 30);
      expect(item.targetWeight, 5);
      expect(item.targetDurationSeconds, 600);
      expect(item.order, 4);
    },
  );

  test('custom search matches name and category', () {
    final exercises = [
      _exercise(),
      _exercise(id: _secondUuid, name: '划船机', category: '有氧'),
    ];

    expect(
      filterTrainingCustomExercises(exercises, query: '分腿').single.id,
      _uuid,
    );
    expect(
      filterTrainingCustomExercises(exercises, query: '有氧').single.id,
      _secondUuid,
    );
  });

  test('custom categories include new values once and omit empty category', () {
    final categories = trainingCustomExerciseCategories([
      _exercise(category: '腿部'),
      _exercise(id: _secondUuid, category: '新分类'),
      _exercise(id: 'third', category: '腿部'),
      _exercise(id: 'fourth', category: ''),
    ]);

    expect(categories, ['腿部', '新分类']);
  });

  test(
    'create update and delete each refresh the catalog after mutation',
    () async {
      final repository = _FakeTrainingRepository();
      final container = ProviderContainer(
        overrides: [trainingRepositoryProvider.overrideWithValue(repository)],
      );
      addTearDown(container.dispose);
      final controller = container.read(
        trainingCustomExerciseControllerProvider.notifier,
      );
      await controller.refresh();

      var getsBefore = repository.getCustomExercisesCalls;
      expect((await controller.create(_input)).isSuccess, isTrue);
      expect(repository.createCalls, 1);
      expect(repository.getCustomExercisesCalls, getsBefore + 1);

      getsBefore = repository.getCustomExercisesCalls;
      expect((await controller.update(_secondUuid, _input)).isSuccess, isTrue);
      expect(repository.updateCalls, 1);
      expect(repository.getCustomExercisesCalls, getsBefore + 1);

      getsBefore = repository.getCustomExercisesCalls;
      expect((await controller.delete(_secondUuid)).isSuccess, isTrue);
      expect(repository.deleteCalls, 1);
      expect(repository.getCustomExercisesCalls, getsBefore + 1);
    },
  );

  test('delete 404 reports missing exercise and refreshes catalog', () async {
    final repository = _FakeTrainingRepository()..deleteAsNotFound = true;
    final container = ProviderContainer(
      overrides: [trainingRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(container.dispose);
    final controller = container.read(
      trainingCustomExerciseControllerProvider.notifier,
    );
    await controller.refresh();
    final getsBefore = repository.getCustomExercisesCalls;

    final result = await controller.delete(_uuid);

    expect(result.isSuccess, isFalse);
    expect(result.isNotFound, isTrue);
    expect(result.errorMessage, contains('已不存在'));
    expect(repository.getCustomExercisesCalls, getsBefore + 1);
  });

  test(
    'deleting catalog entry does not mutate an existing template snapshot',
    () {
      final catalog = <TrainingCustomExercise>[_exercise()];
      final existingItem = catalog.single.toTemplateItem(
        itemId: 'item-existing',
        order: 0,
      );

      catalog.clear();

      final json = SaveTrainingTemplateRequestDto.fromDomain([
        TrainingDay(dayIndex: 0, exercises: [existingItem]),
      ]).toJson();
      final days = json['days'] as List<dynamic>;
      final day = days.single as Map<String, dynamic>;
      final exercises = day['exercises'] as List<dynamic>;
      final saved = exercises.single as Map<String, dynamic>;

      expect(existingItem.itemId, 'item-existing');
      expect(existingItem.exerciseId, _uuid);
      expect(existingItem.exerciseName, '保加利亚分腿蹲');
      expect(existingItem.category, '腿部');
      expect(existingItem.targetSets, 3);
      expect(existingItem.targetReps, 10);
      expect(existingItem.targetWeight, 10);
      expect(existingItem.targetDurationSeconds, isNull);
      expect(saved['item_id'], 'item-existing');
      expect(saved['exercise_id'], _uuid);
      expect(saved['exercise_name'], '保加利亚分腿蹲');
      expect(saved['category'], '腿部');
      expect(saved['target_sets'], 3);
      expect(saved['target_reps'], 10);
      expect(saved['target_weight'], 10);
      expect(saved['target_duration_seconds'], isNull);
    },
  );
}
