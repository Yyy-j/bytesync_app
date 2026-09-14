import 'package:flutter_test/flutter_test.dart';

import 'package:bytesync/features/training/data/dto/training_request_dtos.dart';
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
    expect(item.order, 3);
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
