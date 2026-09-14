import 'package:flutter_test/flutter_test.dart';

import 'package:bytesync/features/training/data/dto/training_request_dtos.dart';
import 'package:bytesync/features/training/data/dto/training_dtos.dart';
import 'package:bytesync/features/training/data/mappers/training_mapper.dart';
import 'package:bytesync/features/training/domain/training_day.dart';
import 'package:bytesync/features/training/domain/training_exercise_item.dart';
import 'package:bytesync/features/training/exercises/data/fixed_training_exercises.dart';
import 'package:bytesync/features/training/presentation/template/training_template_controller.dart';

void main() {
  test('fixed exercise library contains the legacy 27 exercises', () {
    expect(fixedTrainingExercises, hasLength(27));
    expect(fixedTrainingExerciseCategories, hasLength(10));
  });

  test('every fixed exercise id is unique', () {
    final ids = fixedTrainingExercises.map((exercise) => exercise.id).toSet();

    expect(ids, hasLength(fixedTrainingExercises.length));
  });

  test('search matches Chinese names', () {
    final result = filterFixedTrainingExercises(query: '哑铃弯举');

    expect(result.map((exercise) => exercise.id), contains('dumbbell_curl'));
  });

  test('search matches English names ignoring case', () {
    final result = filterFixedTrainingExercises(query: 'SIDE PLANK');

    expect(result.map((exercise) => exercise.id), contains('side_plank'));
  });

  test('category filter keeps only the selected legacy category', () {
    final result = filterFixedTrainingExercises(category: '背部');

    expect(result, hasLength(5));
    expect(result.every((exercise) => exercise.category == '背部'), isTrue);
  });

  test('fixed exercise selection creates the expected template item', () {
    final exercise = fixedTrainingExercises.firstWhere(
      (value) => value.id == 'chest_press',
    );

    final item = exercise.toTemplateItem(itemId: 'item-new', order: 3);

    expect(item.itemId, 'item-new');
    expect(item.exerciseId, 'chest_press');
    expect(item.exerciseName, '器械胸推');
    expect(item.itemType, TrainingItemType.strength);
    expect(item.category, '胸部');
    expect(item.targetSets, 4);
    expect(item.targetReps, 12);
    expect(item.targetWeight, 20);
    expect(item.targetDurationSeconds, isNull);
    expect(item.order, 3);
  });

  test('fixed Side Plank snapshots its duration into the template item', () {
    final exercise = fixedTrainingExercises.firstWhere(
      (value) => value.id == 'side_plank',
    );

    final item = exercise.toTemplateItem(itemId: 'side-plank', order: 0);

    expect(item.itemType, TrainingItemType.cardio);
    expect(item.targetDurationSeconds, 30);
  });

  test('old exercise and set DTOs without duration map duration to null', () {
    final dto = TrainingExerciseItemDto.fromJson({
      'item_id': 'legacy-item',
      'exercise_id': null,
      'exercise_name': '旧动作',
      'item_type': 'duration',
      'category': '',
      'target_sets': 2,
      'target_reps': 0,
      'target_weight': 0,
      'order': 0,
      'set_details': [
        {
          'request_id': 'legacy-set',
          'set_index': 1,
          'weight': null,
          'reps': null,
          'rpe': 7,
          'remark': null,
          'completed_at': '2026-09-14T01:02:03Z',
        },
      ],
    });

    final item = TrainingMapper.exerciseFromDto(dto);

    expect(item.targetDurationSeconds, isNull);
    expect(item.setDetails.single.durationSeconds, isNull);
  });

  test('exercise and set DTOs map duration fields', () {
    final dto = TrainingExerciseItemDto.fromJson({
      'item_id': 'duration-item',
      'exercise_id': null,
      'exercise_name': '平板支撑',
      'item_type': 'duration',
      'category': '核心',
      'target_sets': 3,
      'target_reps': 0,
      'target_weight': 0,
      'target_duration_seconds': 90,
      'order': 0,
      'set_details': [
        {
          'request_id': 'duration-set',
          'set_index': 1,
          'weight': null,
          'reps': null,
          'duration_seconds': 75,
          'rpe': 7,
          'remark': null,
          'completed_at': '2026-09-14T01:02:03Z',
        },
      ],
    });

    final item = TrainingMapper.exerciseFromDto(dto);

    expect(item.targetDurationSeconds, 90);
    expect(item.setDetails.single.durationSeconds, 75);
  });

  test('duration and cardio template items use duration wire field', () {
    for (final type in [TrainingItemType.duration, TrainingItemType.cardio]) {
      final item = TrainingExerciseItem(
        itemId: 'item-${type.name}',
        exerciseId: null,
        exerciseName: type.name,
        itemType: type,
        category: '',
        targetSets: 3,
        targetReps: 0,
        targetWeight: 0,
        targetDurationSeconds: 90,
        order: 0,
      );
      final json = SaveTrainingTemplateRequestDto.fromDomain([
        TrainingDay(dayIndex: 0, exercises: [item]),
      ]).toJson();
      final days = json['days'] as List<dynamic>;
      final day = days.single as Map<String, dynamic>;
      final exercises = day['exercises'] as List<dynamic>;

      expect(
        (exercises.single as Map<String, dynamic>)['target_duration_seconds'],
        90,
      );
    }
  });

  test('new template item ids are unique', () {
    final first = newTrainingTemplateItemId();
    final second = newTrainingTemplateItemId();

    expect(first, isNot(second));
    expect(first, startsWith('item-'));
    expect(second, startsWith('item-'));
  });

  test('saving an existing exercise preserves its item id', () {
    const existing = TrainingExerciseItem(
      itemId: 'item-existing',
      exerciseId: 'chest_press',
      exerciseName: '器械胸推',
      itemType: TrainingItemType.strength,
      category: '胸部',
      targetSets: 5,
      targetReps: 8,
      targetWeight: 25,
      order: 0,
    );

    final json = SaveTrainingTemplateRequestDto.fromDomain(
      const [TrainingDay(dayIndex: 0, exercises: [existing])],
    ).toJson();
    final days = json['days'] as List<dynamic>;
    final day = days.single as Map<String, dynamic>;
    final exercises = day['exercises'] as List<dynamic>;
    final saved = exercises.single as Map<String, dynamic>;

    expect(saved['item_id'], existing.itemId);
  });
}
