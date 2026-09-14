import '../../../../core/network/api_exception.dart';

class TrainingSetDetailDto {
  const TrainingSetDetailDto({
    required this.requestId,
    required this.setIndex,
    required this.weight,
    required this.reps,
    required this.rpe,
    required this.remark,
    required this.completedAt,
  });

  factory TrainingSetDetailDto.fromJson(Map<String, dynamic> json) {
    try {
      return TrainingSetDetailDto(
        requestId: json['request_id'] as String,
        setIndex: json['set_index'] as int,
        weight: (json['weight'] as num?)?.toDouble(),
        reps: json['reps'] as int?,
        rpe: (json['rpe'] as num?)?.toDouble(),
        remark: json['remark'] as String?,
        completedAt: json['completed_at'] as String,
      );
    } on TypeError catch (error) {
      throw MalformedResponseException('Training set 格式异常: $error');
    }
  }

  final String requestId;
  final int setIndex;
  final double? weight;
  final int? reps;
  final double? rpe;
  final String? remark;
  final String completedAt;
}

class TrainingExerciseItemDto {
  const TrainingExerciseItemDto({
    required this.itemId,
    required this.exerciseId,
    required this.exerciseName,
    required this.itemType,
    required this.category,
    required this.targetSets,
    required this.targetReps,
    required this.targetWeight,
    required this.order,
    required this.completedSets,
    required this.setDetails,
    required this.removedFromTemplate,
  });

  factory TrainingExerciseItemDto.fromJson(Map<String, dynamic> json) {
    final rawSetDetails = json['set_details'] ?? const <dynamic>[];
    if (rawSetDetails is! List) {
      throw const MalformedResponseException('Training set_details 格式异常');
    }
    try {
      return TrainingExerciseItemDto(
        itemId: json['item_id'] as String,
        exerciseId: json['exercise_id'] as String?,
        exerciseName: json['exercise_name'] as String,
        itemType: json['item_type'] as String,
        category: json['category'] as String,
        targetSets: json['target_sets'] as int,
        targetReps: json['target_reps'] as int,
        targetWeight: (json['target_weight'] as num).toDouble(),
        order: json['order'] as int,
        completedSets: (json['completed_sets'] as int?) ?? 0,
        setDetails: rawSetDetails
            .map((value) => TrainingSetDetailDto.fromJson(_jsonMap(value)))
            .toList(growable: false),
        removedFromTemplate:
            (json['removed_from_template'] as bool?) ?? false,
      );
    } on TypeError catch (error) {
      throw MalformedResponseException('Training exercise 格式异常: $error');
    }
  }

  final String itemId;
  final String? exerciseId;
  final String exerciseName;
  final String itemType;
  final String category;
  final int targetSets;
  final int targetReps;
  final double targetWeight;
  final int order;
  final int completedSets;
  final List<TrainingSetDetailDto> setDetails;
  final bool removedFromTemplate;
}

class TrainingDayDto {
  const TrainingDayDto({
    required this.dayIndex,
    required this.date,
    required this.exercises,
  });

  factory TrainingDayDto.fromJson(Map<String, dynamic> json) {
    final rawExercises = json['exercises'];
    if (rawExercises is! List) {
      throw const MalformedResponseException('Training exercises 格式异常');
    }
    try {
      return TrainingDayDto(
        dayIndex: json['day_index'] as int,
        date: json['date'] as String?,
        exercises: rawExercises
            .map((value) => TrainingExerciseItemDto.fromJson(_jsonMap(value)))
            .toList(growable: false),
      );
    } on TypeError catch (error) {
      throw MalformedResponseException('Training day 格式异常: $error');
    }
  }

  final int dayIndex;
  final String? date;
  final List<TrainingExerciseItemDto> exercises;
}

class TrainingTemplateDto {
  const TrainingTemplateDto({
    required this.id,
    required this.version,
    required this.days,
    required this.createdAt,
    required this.updatedAt,
  });

  factory TrainingTemplateDto.fromJson(Map<String, dynamic> json) {
    try {
      return TrainingTemplateDto(
        id: json['id'] as String,
        version: json['version'] as int,
        days: _days(json['days']),
        createdAt: json['created_at'] as String,
        updatedAt: json['updated_at'] as String,
      );
    } on TypeError catch (error) {
      throw MalformedResponseException('Training template 格式异常: $error');
    }
  }

  final String id;
  final int version;
  final List<TrainingDayDto> days;
  final String createdAt;
  final String updatedAt;
}

class TrainingTemplateResponseDto {
  const TrainingTemplateResponseDto({required this.template});

  factory TrainingTemplateResponseDto.fromJson(Map<String, dynamic> json) {
    final value = json['template'];
    return TrainingTemplateResponseDto(
      template: value == null
          ? null
          : TrainingTemplateDto.fromJson(_jsonMap(value)),
    );
  }

  final TrainingTemplateDto? template;
}

class TrainingWeekDto {
  const TrainingWeekDto({
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

  factory TrainingWeekDto.fromJson(Map<String, dynamic> json) {
    try {
      return TrainingWeekDto(
        id: json['id'] as String,
        weekId: json['week_id'] as String,
        weekStart: json['week_start'] as String,
        weekEnd: json['week_end'] as String,
        templateVersion: json['template_version'] as int?,
        snapshotAt: json['snapshot_at'] as String,
        syncedAt: json['synced_at'] as String?,
        days: _days(json['days']),
        createdAt: json['created_at'] as String,
        updatedAt: json['updated_at'] as String,
      );
    } on TypeError catch (error) {
      throw MalformedResponseException('Training week 格式异常: $error');
    }
  }

  final String id;
  final String weekId;
  final String weekStart;
  final String weekEnd;
  final int? templateVersion;
  final String snapshotAt;
  final String? syncedAt;
  final List<TrainingDayDto> days;
  final String createdAt;
  final String updatedAt;
}

class TrainingCurrentWeekResponseDto {
  const TrainingCurrentWeekResponseDto({
    required this.week,
    required this.created,
  });

  factory TrainingCurrentWeekResponseDto.fromJson(Map<String, dynamic> json) {
    try {
      return TrainingCurrentWeekResponseDto(
        week: TrainingWeekDto.fromJson(_jsonMap(json['week'])),
        created: json['created'] as bool,
      );
    } on TypeError catch (error) {
      throw MalformedResponseException('Current training week 格式异常: $error');
    }
  }

  final TrainingWeekDto week;
  final bool created;
}

class TrainingSyncResponseDto {
  const TrainingSyncResponseDto({
    required this.week,
    required this.created,
    required this.synced,
  });

  factory TrainingSyncResponseDto.fromJson(Map<String, dynamic> json) {
    try {
      return TrainingSyncResponseDto(
        week: TrainingWeekDto.fromJson(_jsonMap(json['week'])),
        created: json['created'] as bool,
        synced: json['synced'] as bool,
      );
    } on TypeError catch (error) {
      throw MalformedResponseException('Training sync 格式异常: $error');
    }
  }

  final TrainingWeekDto week;
  final bool created;
  final bool synced;
}

class TrainingWeekHistoryResponseDto {
  const TrainingWeekHistoryResponseDto({
    required this.weeks,
    required this.total,
  });

  factory TrainingWeekHistoryResponseDto.fromJson(Map<String, dynamic> json) {
    final rawWeeks = json['weeks'];
    if (rawWeeks is! List) {
      throw const MalformedResponseException('Training weeks 格式异常');
    }
    try {
      return TrainingWeekHistoryResponseDto(
        weeks: rawWeeks
            .map((value) => TrainingWeekDto.fromJson(_jsonMap(value)))
            .toList(growable: false),
        total: json['total'] as int,
      );
    } on TypeError catch (error) {
      throw MalformedResponseException('Training history 格式异常: $error');
    }
  }

  final List<TrainingWeekDto> weeks;
  final int total;
}

class TrainingSetCheckInResponseDto {
  const TrainingSetCheckInResponseDto({
    required this.duplicate,
    required this.completedSets,
    required this.targetSets,
    required this.setDetail,
  });

  factory TrainingSetCheckInResponseDto.fromJson(Map<String, dynamic> json) {
    try {
      return TrainingSetCheckInResponseDto(
        duplicate: json['duplicate'] as bool,
        completedSets: json['completed_sets'] as int,
        targetSets: json['target_sets'] as int,
        setDetail: TrainingSetDetailDto.fromJson(_jsonMap(json['set'])),
      );
    } on TypeError catch (error) {
      throw MalformedResponseException('Training check-in 格式异常: $error');
    }
  }

  final bool duplicate;
  final int completedSets;
  final int targetSets;
  final TrainingSetDetailDto setDetail;
}

class TrainingSetUpdateResponseDto {
  const TrainingSetUpdateResponseDto({
    required this.completedSets,
    required this.setDetail,
  });

  factory TrainingSetUpdateResponseDto.fromJson(Map<String, dynamic> json) {
    try {
      return TrainingSetUpdateResponseDto(
        completedSets: json['completed_sets'] as int,
        setDetail: TrainingSetDetailDto.fromJson(_jsonMap(json['set'])),
      );
    } on TypeError catch (error) {
      throw MalformedResponseException('Training set update 格式异常: $error');
    }
  }

  final int completedSets;
  final TrainingSetDetailDto setDetail;
}

List<TrainingDayDto> _days(dynamic value) {
  if (value is! List) {
    throw const MalformedResponseException('Training days 格式异常');
  }
  return value
      .map((day) => TrainingDayDto.fromJson(_jsonMap(day)))
      .toList(growable: false);
}

Map<String, dynamic> _jsonMap(dynamic value) {
  if (value is! Map) {
    throw const MalformedResponseException('Training object 格式异常');
  }
  return Map<String, dynamic>.from(value);
}
