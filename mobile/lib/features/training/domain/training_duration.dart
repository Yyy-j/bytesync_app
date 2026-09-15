import 'package:bytesync/l10n/l10n.dart';

import 'training_exercise_item.dart';

const maxTrainingDurationSeconds = 86400;

String formatTrainingDuration(int seconds) {
  final minutes = seconds ~/ 60;
  final remainingSeconds = seconds % 60;
  if (minutes == 0) return appL10n.trainingDurationSeconds(remainingSeconds);
  if (remainingSeconds == 0) {
    return appL10n.trainingDurationMinutesValue(minutes);
  }
  return appL10n.trainingDurationMinutesSeconds(minutes, remainingSeconds);
}

String trainingTargetText({
  required TrainingItemType itemType,
  required int targetSets,
  required int targetReps,
  required double targetWeight,
  required int? targetDurationSeconds,
}) {
  if (itemType == TrainingItemType.strength) {
    return appL10n.trainingTargetStrength(
      targetSets,
      targetReps,
      formatTrainingWeight(targetWeight),
    );
  }
  final duration = targetDurationSeconds;
  if (duration == null) return appL10n.trainingTargetSetsOnly(targetSets);
  final durationText = formatTrainingDuration(duration);
  return itemType == TrainingItemType.cardio
      ? appL10n.trainingTargetCardio(targetSets, durationText)
      : appL10n.trainingTargetPerSetDuration(targetSets, durationText);
}

String formatTrainingWeight(double value) {
  return value == value.roundToDouble()
      ? value.toInt().toString()
      : value.toStringAsFixed(1);
}
