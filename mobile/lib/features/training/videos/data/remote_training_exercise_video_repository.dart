import 'package:dio/dio.dart';

import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/network/dio_error_mapper.dart';
import '../domain/training_exercise_video.dart';
import 'dto/training_exercise_video_dtos.dart';
import 'training_exercise_video_repository.dart';

class RemoteTrainingExerciseVideoRepository
    implements TrainingExerciseVideoRepository {
  RemoteTrainingExerciseVideoRepository(this._dio, this._errorMapper);

  final Dio _dio;
  final DioErrorMapper _errorMapper;

  @override
  Future<List<TrainingExerciseVideo>> getVideos() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        ApiEndpoints.trainingExerciseVideos,
      );
      return TrainingExerciseVideoListDto.fromJson(response.data!).videos
          .map(_toDomain)
          .toList(growable: false);
    } catch (error) {
      throw _errorMapper.map(error);
    }
  }

  @override
  Future<TrainingExerciseVideo> putVideo({
    required String exerciseId,
    required String videoUrl,
  }) async {
    try {
      final response = await _dio.put<Map<String, dynamic>>(
        ApiEndpoints.trainingExerciseVideo(exerciseId),
        data: PutTrainingExerciseVideoRequestDto(videoUrl).toJson(),
      );
      return _toDomain(TrainingExerciseVideoDto.fromJson(response.data!));
    } catch (error) {
      throw _errorMapper.map(error);
    }
  }

  @override
  Future<void> deleteVideo(String exerciseId) async {
    try {
      await _dio.delete<void>(ApiEndpoints.trainingExerciseVideo(exerciseId));
    } catch (error) {
      throw _errorMapper.map(error);
    }
  }

  TrainingExerciseVideo _toDomain(TrainingExerciseVideoDto dto) {
    try {
      final videoUrl = Uri.parse(dto.videoUrl);
      if (!videoUrl.hasAuthority ||
          (videoUrl.scheme != 'http' && videoUrl.scheme != 'https')) {
        throw const FormatException('invalid video URL');
      }
      return TrainingExerciseVideo(
        id: dto.id,
        exerciseId: dto.exerciseId,
        videoUrl: videoUrl,
        createdAt: DateTime.parse(dto.createdAt),
        updatedAt: DateTime.parse(dto.updatedAt),
      );
    } on FormatException catch (error) {
      throw MalformedResponseException('教学视频数据格式异常: $error');
    }
  }
}
