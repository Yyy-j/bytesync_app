import 'package:dio/dio.dart';

import '../../../core/network/api_endpoints.dart';
import '../../../core/network/dio_error_mapper.dart';
import '../domain/meal.dart';
import '../domain/meal_patch.dart';
import 'dto/meal_dto.dart';
import 'dto/meal_request_dtos.dart';
import 'mappers/meal_mapper.dart';
import 'meals_repository.dart';

/// Real implementation of [MealsRepository], calling the FastAPI backend.
///
class RemoteMealsRepository implements MealsRepository {
  RemoteMealsRepository(this._dio, this._errorMapper);

  final Dio _dio;
  final DioErrorMapper _errorMapper;

  @override
  Future<Meal> addMeal(NewMealInput input) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        ApiEndpoints.meals,
        data: CreateMealRequestDto.fromInput(input).toJson(),
      );
      return MealMapper.fromDto(MealDto.fromJson(response.data!));
    } catch (e) {
      throw _errorMapper.map(e);
    }
  }

  @override
  Future<List<Meal>> getMealsForDate(DateTime date) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        ApiEndpoints.meals,
        queryParameters: {'date': _dateOnly(date)},
      );
      return _mapList(response.data!);
    } catch (e) {
      throw _errorMapper.map(e);
    }
  }

  @override
  Future<Meal> getMealById(String id) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        ApiEndpoints.mealById(id),
      );
      return MealMapper.fromDto(MealDto.fromJson(response.data!));
    } catch (e) {
      throw _errorMapper.map(e);
    }
  }

  @override
  Future<Meal> updateMeal(String id, MealPatch patch) async {
    try {
      final response = await _dio.patch<Map<String, dynamic>>(
        ApiEndpoints.mealById(id),
        data: UpdateMealRequestDto.fromPatch(patch).toJson(),
      );
      return MealMapper.fromDto(MealDto.fromJson(response.data!));
    } catch (e) {
      throw _errorMapper.map(e);
    }
  }

  @override
  Future<void> deleteMeal(String id) async {
    try {
      await _dio.delete<void>(ApiEndpoints.mealById(id));
    } catch (e) {
      throw _errorMapper.map(e);
    }
  }

  @override
  Future<List<Meal>> getRecentMealsForReuse({int limit = 3}) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        ApiEndpoints.mealsRecent,
        queryParameters: {'limit': limit.clamp(1, 10)},
      );
      return _mapList(response.data!);
    } catch (e) {
      throw _errorMapper.map(e);
    }
  }

  List<Meal> _mapList(Map<String, dynamic> json) {
    return MealListResponseDto.fromJson(json).meals
        .map(MealMapper.fromDto)
        .toList(growable: false);
  }

  String _dateOnly(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';
}
