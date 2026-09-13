import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bytesync/features/meals/data/meal_ai_repository.dart';
import 'package:bytesync/features/meals/data/meals_providers.dart';
import 'package:bytesync/features/meals/domain/meal_ai_result.dart';
import 'package:bytesync/features/meals/presentation/add_meal_page.dart';
import 'package:bytesync/features/meals/presentation/record_controller.dart';

const _result = MealAiResult(
  name: '牛肉面套餐',
  calories: 650,
  protein: 32,
  carbs: 78,
  fat: 22,
  dishes: ['牛肉面', '煎蛋'],
);

class _FakeMealAiRepository implements MealAiRepository {
  _FakeMealAiRepository({this.error});

  final Object? error;
  String? lastText;

  @override
  Future<MealAiResult> analyzeText(String text) async {
    lastText = text;
    if (error != null) throw error!;
    return _result;
  }
}

void main() {
  test('empty input cannot submit', () async {
    final repository = _FakeMealAiRepository();
    final container = ProviderContainer(
      overrides: [mealAiRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(container.dispose);

    final submitted = await container
        .read(recordControllerProvider.notifier)
        .analyze('   ');

    expect(submitted, isFalse);
    expect(container.read(recordControllerProvider), isA<RecordIdle>());
    expect(repository.lastText, isNull);
  });

  test('success enters result state', () async {
    final container = ProviderContainer(
      overrides: [
        mealAiRepositoryProvider.overrideWithValue(_FakeMealAiRepository()),
      ],
    );
    addTearDown(container.dispose);

    final submitted = await container
        .read(recordControllerProvider.notifier)
        .analyze('一碗牛肉面和一个煎蛋');

    expect(submitted, isTrue);
    final state = container.read(recordControllerProvider);
    expect(state, isA<RecordResult>());
    expect((state as RecordResult).result.dishes, ['牛肉面', '煎蛋']);
  });

  testWidgets('error keeps the original input', (tester) async {
    final repository = _FakeMealAiRepository(error: Exception('network'));
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          mealAiRepositoryProvider.overrideWithValue(repository),
        ],
        child: const MaterialApp(home: AddMealPage()),
      ),
    );

    final input = find.byType(TextField).first;
    await tester.enterText(input, '一份鸡肉沙拉');
    await tester.tap(find.text('AI 估算'));
    await tester.pumpAndSettle();

    expect(find.text('AI 估算失败，请稍后重试'), findsOneWidget);
    expect(find.text('一份鸡肉沙拉'), findsOneWidget);
  });

  testWidgets('success displays dishes', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          mealAiRepositoryProvider.overrideWithValue(_FakeMealAiRepository()),
        ],
        child: const MaterialApp(home: AddMealPage()),
      ),
    );

    final input = find.byType(TextField).first;
    await tester.enterText(input, '牛肉面和煎蛋');
    await tester.tap(find.text('AI 估算'));
    await tester.pumpAndSettle();

    expect(find.text('菜品：牛肉面、煎蛋'), findsOneWidget);
    expect(find.text('AI 估算，仅供参考'), findsOneWidget);
  });
}
