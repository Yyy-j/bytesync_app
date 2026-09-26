import 'package:flutter_test/flutter_test.dart';

import 'package:bytesync/features/meals/data/dto/meal_dto.dart';
import 'package:bytesync/features/meals/data/mappers/meal_mapper.dart';

void main() {
  test('Single Meal accepts a null pair_id', () {
    final dto = MealDto.fromJson({
      'id': 'meal-1',
      'pair_id': null,
      'user_id': 'user-1',
      'shared_meal_id': null,
      'name': '鸡肉饭',
      'source': 'manual',
      'dishes': [],
      'ai_hint': null,
      'original_input': null,
      'base_calories': 500,
      'base_protein': 30,
      'base_carbs': 60,
      'base_fat': 12,
      'calories': 500,
      'protein': 30,
      'carbs': 60,
      'fat': 12,
      'portion_ratio': 1,
      'share_ratio': 1,
      'share_mode': 'solo',
      'meal_date': '2026-09-26',
      'meal_time': '12:00',
      'created_at': '2026-09-26T12:00:00Z',
      'updated_at': '2026-09-26T12:00:00Z',
    });

    expect(dto.pairId, isNull);
    expect(MealMapper.fromDto(dto).pairId, isNull);
  });
}
