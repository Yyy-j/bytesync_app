import 'package:flutter_test/flutter_test.dart';

import 'package:bytesync/features/training/domain/training_duration.dart';
import 'package:bytesync/features/training/domain/training_exercise_item.dart';

void main() {
  test('formats training durations in compact Chinese', () {
    expect(formatTrainingDuration(30), '30秒');
    expect(formatTrainingDuration(60), '1分钟');
    expect(formatTrainingDuration(90), '1分30秒');
    expect(formatTrainingDuration(1200), '20分钟');
  });

  test('strength target formatting remains weight and reps based', () {
    expect(
      trainingTargetText(
        itemType: TrainingItemType.strength,
        targetSets: 4,
        targetReps: 12,
        targetWeight: 20,
        targetDurationSeconds: null,
      ),
      '目标：4 × 12 · 20 kg',
    );
  });

  test('duration target formatting has a safe legacy fallback', () {
    expect(
      trainingTargetText(
        itemType: TrainingItemType.duration,
        targetSets: 3,
        targetReps: 0,
        targetWeight: 0,
        targetDurationSeconds: 30,
      ),
      '目标：3 组 · 每组 30秒',
    );
    expect(
      trainingTargetText(
        itemType: TrainingItemType.cardio,
        targetSets: 1,
        targetReps: 0,
        targetWeight: 0,
        targetDurationSeconds: 1200,
      ),
      '目标：1 组 · 20分钟',
    );
    expect(
      trainingTargetText(
        itemType: TrainingItemType.cardio,
        targetSets: 1,
        targetReps: 0,
        targetWeight: 0,
        targetDurationSeconds: null,
      ),
      '目标：1 组',
    );
  });
}
