import 'training_exercise_item.dart';

const maxTrainingDurationSeconds = 86400;

String formatTrainingDuration(int seconds) {
  final minutes = seconds ~/ 60;
  final remainingSeconds = seconds % 60;
  if (minutes == 0) return '$remainingSeconds秒';
  if (remainingSeconds == 0) return '$minutes分钟';
  return '$minutes分$remainingSeconds秒';
}

String trainingTargetText({
  required TrainingItemType itemType,
  required int targetSets,
  required int targetReps,
  required double targetWeight,
  required int? targetDurationSeconds,
}) {
  if (itemType == TrainingItemType.strength) {
    return '目标：$targetSets × $targetReps · ${formatTrainingWeight(targetWeight)} kg';
  }
  final duration = targetDurationSeconds;
  if (duration == null) return '目标：$targetSets 组';
  final durationText = formatTrainingDuration(duration);
  return itemType == TrainingItemType.cardio
      ? '目标：$targetSets 组 · $durationText'
      : '目标：$targetSets 组 · 每组 $durationText';
}

String formatTrainingWeight(double value) {
  return value == value.roundToDouble()
      ? value.toInt().toString()
      : value.toStringAsFixed(1);
}
