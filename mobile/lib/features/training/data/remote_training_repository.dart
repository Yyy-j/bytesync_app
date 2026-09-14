import 'package:dio/dio.dart';

import '../../../core/network/api_endpoints.dart';
import '../../../core/network/dio_error_mapper.dart';
import '../domain/training_day.dart';
import '../domain/training_set_detail.dart';
import '../domain/training_template.dart';
import '../domain/training_week.dart';
import '../exercises/domain/training_custom_exercise.dart';
import 'dto/training_dtos.dart';
import 'dto/training_request_dtos.dart';
import 'mappers/training_mapper.dart';
import 'training_repository.dart';

class RemoteTrainingRepository implements TrainingRepository {
  RemoteTrainingRepository(this._dio, this._errorMapper);

  final Dio _dio;
  final DioErrorMapper _errorMapper;

  @override
  Future<List<TrainingCustomExercise>> getCustomExercises() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        ApiEndpoints.trainingCustomExercises,
      );
      final dto = TrainingCustomExerciseListResponseDto.fromJson(
        response.data!,
      );
      return dto.exercises
          .map(TrainingMapper.customExerciseFromDto)
          .toList(growable: false);
    } catch (error) {
      throw _errorMapper.map(error);
    }
  }

  @override
  Future<TrainingCustomExercise> createCustomExercise(
    TrainingCustomExerciseInput input,
  ) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        ApiEndpoints.trainingCustomExercises,
        data: CreateTrainingCustomExerciseRequestDto(input).toJson(),
      );
      return TrainingMapper.customExerciseFromDto(
        TrainingCustomExerciseDto.fromJson(response.data!),
      );
    } catch (error) {
      throw _errorMapper.map(error);
    }
  }

  @override
  Future<TrainingCustomExercise> updateCustomExercise(
    String exerciseId,
    TrainingCustomExerciseInput input,
  ) async {
    try {
      final response = await _dio.patch<Map<String, dynamic>>(
        ApiEndpoints.trainingCustomExerciseById(exerciseId),
        data: UpdateTrainingCustomExerciseRequestDto(input).toJson(),
      );
      return TrainingMapper.customExerciseFromDto(
        TrainingCustomExerciseDto.fromJson(response.data!),
      );
    } catch (error) {
      throw _errorMapper.map(error);
    }
  }

  @override
  Future<void> deleteCustomExercise(String exerciseId) async {
    try {
      await _dio.delete<void>(
        ApiEndpoints.trainingCustomExerciseById(exerciseId),
      );
    } catch (error) {
      throw _errorMapper.map(error);
    }
  }

  @override
  Future<TrainingTemplate?> getTemplate() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        ApiEndpoints.trainingTemplate,
      );
      final dto = TrainingTemplateResponseDto.fromJson(response.data!);
      return dto.template == null
          ? null
          : TrainingMapper.templateFromDto(dto.template!);
    } catch (error) {
      throw _errorMapper.map(error);
    }
  }

  @override
  Future<TrainingTemplate> saveTemplate(List<TrainingDay> days) async {
    try {
      final response = await _dio.put<Map<String, dynamic>>(
        ApiEndpoints.trainingTemplate,
        data: SaveTrainingTemplateRequestDto.fromDomain(days).toJson(),
      );
      return TrainingMapper.templateFromDto(
        TrainingTemplateDto.fromJson(response.data!),
      );
    } catch (error) {
      throw _errorMapper.map(error);
    }
  }

  @override
  Future<CurrentTrainingWeekResult> getCurrentWeek() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        ApiEndpoints.trainingWeeksCurrent,
      );
      final dto = TrainingCurrentWeekResponseDto.fromJson(response.data!);
      return CurrentTrainingWeekResult(
        week: TrainingMapper.weekFromDto(dto.week),
        created: dto.created,
      );
    } catch (error) {
      throw _errorMapper.map(error);
    }
  }

  @override
  Future<TrainingWeek> getWeek(String weekId) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        ApiEndpoints.trainingWeekById(weekId),
      );
      return TrainingMapper.weekFromDto(
        TrainingWeekDto.fromJson(response.data!),
      );
    } catch (error) {
      throw _errorMapper.map(error);
    }
  }

  @override
  Future<TrainingWeekHistory> getWeekHistory({
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        ApiEndpoints.trainingWeeks,
        queryParameters: {'limit': limit, 'offset': offset},
      );
      final dto = TrainingWeekHistoryResponseDto.fromJson(response.data!);
      return TrainingWeekHistory(
        weeks: dto.weeks
            .map(TrainingMapper.weekFromDto)
            .toList(growable: false),
        total: dto.total,
      );
    } catch (error) {
      throw _errorMapper.map(error);
    }
  }

  @override
  Future<SyncTrainingWeekResult> syncCurrentWeek() async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        ApiEndpoints.trainingWeeksCurrentSync,
      );
      final dto = TrainingSyncResponseDto.fromJson(response.data!);
      return SyncTrainingWeekResult(
        week: TrainingMapper.weekFromDto(dto.week),
        created: dto.created,
        synced: dto.synced,
      );
    } catch (error) {
      throw _errorMapper.map(error);
    }
  }

  @override
  Future<TrainingSetCheckInResult> checkInSet({
    required String weekId,
    required String itemId,
    required TrainingSetInput input,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        ApiEndpoints.trainingItemSets(weekId, itemId),
        data: CheckInTrainingSetRequestDto(input).toJson(),
      );
      return TrainingMapper.checkInFromDto(
        TrainingSetCheckInResponseDto.fromJson(response.data!),
      );
    } catch (error) {
      throw _errorMapper.map(error);
    }
  }

  @override
  Future<TrainingSetUpdateResult> updateSetDetail({
    required String weekId,
    required String itemId,
    required String requestId,
    required TrainingSetDetailPatch patch,
  }) async {
    try {
      final response = await _dio.patch<Map<String, dynamic>>(
        ApiEndpoints.trainingSetDetail(weekId, itemId, requestId),
        data: UpdateTrainingSetRequestDto(patch).toJson(),
      );
      return TrainingMapper.updateFromDto(
        TrainingSetUpdateResponseDto.fromJson(response.data!),
      );
    } catch (error) {
      throw _errorMapper.map(error);
    }
  }
}
