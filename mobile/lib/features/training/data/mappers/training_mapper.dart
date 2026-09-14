import '../../../../core/network/api_exception.dart';
import '../../domain/training_day.dart';
import '../../domain/training_exercise_item.dart';
import '../../domain/training_set_detail.dart';
import '../../domain/training_template.dart';
import '../../domain/training_week.dart';
import '../dto/training_dtos.dart';

class TrainingMapper {
  const TrainingMapper._();

  static TrainingTemplate templateFromDto(TrainingTemplateDto dto) {
    try {
      return TrainingTemplate(
        id: dto.id,
        version: dto.version,
        days: dto.days.map(dayFromDto).toList(growable: false),
        createdAt: DateTime.parse(dto.createdAt),
        updatedAt: DateTime.parse(dto.updatedAt),
      );
    } on FormatException catch (error) {
      throw MalformedResponseException('Training template 值格式异常: $error');
    }
  }

  static TrainingWeek weekFromDto(TrainingWeekDto dto) {
    try {
      return TrainingWeek(
        id: dto.id,
        weekId: dto.weekId,
        weekStart: DateTime.parse(dto.weekStart),
        weekEnd: DateTime.parse(dto.weekEnd),
        templateVersion: dto.templateVersion,
        snapshotAt: DateTime.parse(dto.snapshotAt),
        syncedAt: dto.syncedAt == null ? null : DateTime.parse(dto.syncedAt!),
        days: dto.days.map(dayFromDto).toList(growable: false),
        createdAt: DateTime.parse(dto.createdAt),
        updatedAt: DateTime.parse(dto.updatedAt),
      );
    } on FormatException catch (error) {
      throw MalformedResponseException('Training week 值格式异常: $error');
    }
  }

  static TrainingDay dayFromDto(TrainingDayDto dto) {
    return TrainingDay(
      dayIndex: dto.dayIndex,
      date: dto.date == null ? null : DateTime.parse(dto.date!),
      exercises: dto.exercises.map(exerciseFromDto).toList(growable: false),
    );
  }

  static TrainingExerciseItem exerciseFromDto(TrainingExerciseItemDto dto) {
    try {
      return TrainingExerciseItem(
        itemId: dto.itemId,
        exerciseId: dto.exerciseId,
        exerciseName: dto.exerciseName,
        itemType: TrainingItemType.fromWire(dto.itemType),
        category: dto.category,
        targetSets: dto.targetSets,
        targetReps: dto.targetReps,
        targetWeight: dto.targetWeight,
        order: dto.order,
        completedSets: dto.completedSets,
        setDetails: dto.setDetails.map(setDetailFromDto).toList(growable: false),
        removedFromTemplate: dto.removedFromTemplate,
      );
    } on FormatException catch (error) {
      throw MalformedResponseException('Training exercise 值格式异常: $error');
    }
  }

  static TrainingSetDetail setDetailFromDto(TrainingSetDetailDto dto) {
    try {
      return TrainingSetDetail(
        requestId: dto.requestId,
        setIndex: dto.setIndex,
        weight: dto.weight,
        reps: dto.reps,
        rpe: dto.rpe,
        remark: dto.remark,
        completedAt: DateTime.parse(dto.completedAt),
      );
    } on FormatException catch (error) {
      throw MalformedResponseException('Training set 值格式异常: $error');
    }
  }

  static TrainingSetCheckInResult checkInFromDto(
    TrainingSetCheckInResponseDto dto,
  ) {
    return TrainingSetCheckInResult(
      duplicate: dto.duplicate,
      completedSets: dto.completedSets,
      targetSets: dto.targetSets,
      setDetail: setDetailFromDto(dto.setDetail),
    );
  }

  static TrainingSetUpdateResult updateFromDto(
    TrainingSetUpdateResponseDto dto,
  ) {
    return TrainingSetUpdateResult(
      completedSets: dto.completedSets,
      setDetail: setDetailFromDto(dto.setDetail),
    );
  }
}
