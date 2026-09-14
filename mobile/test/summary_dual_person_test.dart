import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'package:bytesync/features/meals/domain/meal.dart';
import 'package:bytesync/features/meals/domain/meal_share_mode.dart';
import 'package:bytesync/features/meals/domain/meal_source.dart';
import 'package:bytesync/features/summary/domain/daily_summary.dart';
import 'package:bytesync/features/summary/presentation/summary_controller.dart';
import 'package:bytesync/features/summary/presentation/summary_page.dart';

class _FixedSummaryController extends SummaryController {
  _FixedSummaryController(this.summary);

  final DailySummary summary;

  @override
  SummaryState build() => SummaryLoaded(summary);
}

Meal _meal({
  required String id,
  required String userId,
  required String name,
  required num calories,
  required String mealTime,
  num? baseCalories,
}) {
  final timestamp = DateTime(2026, 9, 14, 12);
  return Meal(
    id: id,
    pairId: 'pair-1',
    userId: userId,
    sharedMealId: null,
    name: name,
    source: MealSource.manual,
    baseCalories: baseCalories ?? calories,
    baseProtein: 30,
    baseCarbs: 40,
    baseFat: 10,
    calories: calories,
    protein: 30,
    carbs: 40,
    fat: 10,
    portionRatio: 1,
    shareRatio: 1,
    shareMode: MealShareMode.solo,
    mealDate: timestamp,
    mealTime: mealTime,
    createdAt: timestamp,
    updatedAt: timestamp,
  );
}

void main() {
  setUpAll(() async {
    await initializeDateFormatting('zh_CN');
  });

  testWidgets('Today uses per-person slices and labels meal owners', (
    tester,
  ) async {
    final summary = DailySummary(
      date: DateTime(2026, 9, 14),
      calories: 2230,
      protein: 150,
      carbs: 230,
      fat: 70,
      mealCount: 2,
      meals: [
        _meal(
          id: 'meal-self',
          userId: 'self-1',
          name: '鸡胸肉沙拉',
          calories: 420,
          baseCalories: 840,
          mealTime: '12:30',
        ),
        _meal(
          id: 'meal-partner',
          userId: 'partner-1',
          name: '意大利面',
          calories: 650,
          mealTime: '19:20',
        ),
      ],
      selfSlice: const UserDailySlice(
        userId: 'self-1',
        displayName: 'Self',
        calories: 1250,
        protein: 80,
        carbs: 130,
        fat: 35,
      ),
      partnerSlice: const UserDailySlice(
        userId: 'partner-1',
        displayName: 'Harper',
        calories: 980,
        protein: 70,
        carbs: 100,
        fat: 35,
      ),
      selfGoals: const DailyGoals(calorieGoal: 2000),
      partnerGoals: const DailyGoals(calorieGoal: 1800),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          summaryControllerProvider.overrideWith(
            () => _FixedSummaryController(summary),
          ),
        ],
        child: const MaterialApp(home: SummaryPage()),
      ),
    );
    await tester.pump();

    expect(find.text('我 1250'), findsOneWidget);
    expect(find.text('/ 2000 kcal'), findsOneWidget);
    expect(find.text('Harper 980'), findsOneWidget);
    expect(find.text('/ 1800 kcal'), findsOneWidget);
    expect(find.text('2230'), findsNothing);
    expect(find.text('我'), findsOneWidget);
    expect(find.text('Harper'), findsOneWidget);
    expect(find.byTooltip('管理鸡胸肉沙拉'), findsOneWidget);
    expect(find.byTooltip('管理意大利面'), findsNothing);

    await tester.tap(find.byTooltip('管理鸡胸肉沙拉'));
    await tester.pumpAndSettle();
    expect(find.text('补充说明再估算'), findsNothing);

    await tester.tap(find.text('直接编辑'));
    await tester.pumpAndSettle();
    final baseCaloriesField = tester.widget<TextField>(
      find.byWidgetPredicate(
        (widget) =>
            widget is TextField &&
            widget.decoration?.labelText == '基础卡路里',
      ),
    );
    expect(baseCaloriesField.controller?.text, '840');
  });
}
