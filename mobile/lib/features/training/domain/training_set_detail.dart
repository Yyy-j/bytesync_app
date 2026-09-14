class TrainingSetDetail {
  const TrainingSetDetail({
    required this.requestId,
    required this.setIndex,
    required this.weight,
    required this.reps,
    required this.rpe,
    required this.remark,
    required this.completedAt,
  });

  final String requestId;
  final int setIndex;
  final double? weight;
  final int? reps;
  final double? rpe;
  final String? remark;
  final DateTime completedAt;
}

class TrainingSetInput {
  const TrainingSetInput({
    required this.requestId,
    this.weight,
    this.reps,
    this.rpe,
    this.remark,
  });

  final String requestId;
  final double? weight;
  final int? reps;
  final double? rpe;
  final String? remark;
}

class TrainingPatchField<T> {
  const TrainingPatchField.absent() : isPresent = false, value = null;
  const TrainingPatchField.value(this.value) : isPresent = true;

  final bool isPresent;
  final T? value;
}

class TrainingSetDetailPatch {
  const TrainingSetDetailPatch({
    this.weight = const TrainingPatchField<double>.absent(),
    this.reps = const TrainingPatchField<int>.absent(),
    this.rpe = const TrainingPatchField<double>.absent(),
    this.remark = const TrainingPatchField<String>.absent(),
  });

  final TrainingPatchField<double> weight;
  final TrainingPatchField<int> reps;
  final TrainingPatchField<double> rpe;
  final TrainingPatchField<String> remark;
}

class TrainingSetCheckInResult {
  const TrainingSetCheckInResult({
    required this.duplicate,
    required this.completedSets,
    required this.targetSets,
    required this.setDetail,
  });

  final bool duplicate;
  final int completedSets;
  final int targetSets;
  final TrainingSetDetail setDetail;
}

class TrainingSetUpdateResult {
  const TrainingSetUpdateResult({
    required this.completedSets,
    required this.setDetail,
  });

  final int completedSets;
  final TrainingSetDetail setDetail;
}
