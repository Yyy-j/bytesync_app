import '../../../../../core/network/api_exception.dart';

class TrainingExerciseVideoDto {
  const TrainingExerciseVideoDto({
    required this.id,
    required this.exerciseId,
    required this.videoUrl,
    required this.createdAt,
    required this.updatedAt,
  });

  factory TrainingExerciseVideoDto.fromJson(Map<String, dynamic> json) {
    try {
      return TrainingExerciseVideoDto(
        id: json['id'] as String,
        exerciseId: json['exercise_id'] as String,
        videoUrl: json['video_url'] as String,
        createdAt: json['created_at'] as String,
        updatedAt: json['updated_at'] as String,
      );
    } on TypeError catch (error) {
      throw MalformedResponseException('教学视频数据解析失败: $error');
    }
  }

  final String id;
  final String exerciseId;
  final String videoUrl;
  final String createdAt;
  final String updatedAt;
}

class TrainingExerciseVideoListDto {
  const TrainingExerciseVideoListDto(this.videos);

  factory TrainingExerciseVideoListDto.fromJson(Map<String, dynamic> json) {
    final values = json['videos'];
    if (values is! List) {
      throw const MalformedResponseException('教学视频列表格式异常');
    }
    return TrainingExerciseVideoListDto(
      values
          .map(
            (value) => TrainingExerciseVideoDto.fromJson(
              Map<String, dynamic>.from(value as Map),
            ),
          )
          .toList(growable: false),
    );
  }

  final List<TrainingExerciseVideoDto> videos;
}

class PutTrainingExerciseVideoRequestDto {
  const PutTrainingExerciseVideoRequestDto(this.videoUrl);

  final String videoUrl;

  Map<String, dynamic> toJson() => {'video_url': videoUrl};
}
