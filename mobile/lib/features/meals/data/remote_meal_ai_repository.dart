import 'package:dio/dio.dart';

import '../../../core/network/api_endpoints.dart';
import '../../../core/network/dio_error_mapper.dart';
import '../domain/meal_ai_result.dart';
import 'dto/meal_ai_dto.dart';
import 'mappers/meal_ai_mapper.dart';
import 'meal_ai_repository.dart';

class RemoteMealAiRepository implements MealAiRepository, MealImageAiRepository {
  RemoteMealAiRepository(this._dio, this._errorMapper);

  final Dio _dio;
  final DioErrorMapper _errorMapper;

  @override
  Future<MealAiResult> analyzeText(String text) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        ApiEndpoints.analyzeMealText,
        data: {'text': text},
      );
      return MealAiMapper.fromDto(MealAiResultDto.fromJson(response.data!));
    } catch (error) {
      throw _errorMapper.map(error);
    }
  }

  @override
  Future<MealAiResult> analyzeImage(String imagePath, {String? hint}) async {
    try {
      final formData = FormData.fromMap({
        'image': await MultipartFile.fromFile(imagePath),
        if (hint != null && hint.trim().isNotEmpty) 'hint': hint.trim(),
      });
      final response = await _dio.post<Map<String, dynamic>>(
        ApiEndpoints.analyzeMealImage,
        data: formData,
      );
      return MealAiMapper.fromDto(MealAiResultDto.fromJson(response.data!));
    } catch (error) {
      throw _errorMapper.map(error);
    }
  }
}
