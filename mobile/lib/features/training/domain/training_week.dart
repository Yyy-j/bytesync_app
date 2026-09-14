import 'training_day.dart';

class TrainingWeek {
  const TrainingWeek({
    required this.id,
    required this.weekId,
    required this.weekStart,
    required this.weekEnd,
    required this.templateVersion,
    required this.snapshotAt,
    required this.syncedAt,
    required this.days,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Backend-internal UUID, retained for diagnostics only.
  final String id;

  /// Public ISO week identifier, for example `2026-W38`.
  final String weekId;
  final DateTime weekStart;
  final DateTime weekEnd;
  final int? templateVersion;
  final DateTime snapshotAt;
  final DateTime? syncedAt;
  final List<TrainingDay> days;
  final DateTime createdAt;
  final DateTime updatedAt;
}

class CurrentTrainingWeekResult {
  const CurrentTrainingWeekResult({
    required this.week,
    required this.created,
  });

  final TrainingWeek week;
  final bool created;
}

class TrainingWeekHistory {
  const TrainingWeekHistory({required this.weeks, required this.total});

  final List<TrainingWeek> weeks;
  final int total;
}

class SyncTrainingWeekResult {
  const SyncTrainingWeekResult({
    required this.week,
    required this.created,
    required this.synced,
  });

  final TrainingWeek week;
  final bool created;
  final bool synced;
}
