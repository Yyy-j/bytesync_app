import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bytesync/features/meals/data/meal_ai_repository.dart';
import 'package:bytesync/features/meals/data/meals_providers.dart';
import 'package:bytesync/features/meals/domain/meal_ai_result.dart';
import 'package:bytesync/features/meals/domain/meal_share_mode.dart';
import 'package:bytesync/features/meals/domain/meal_source.dart';
import 'package:bytesync/features/meals/presentation/add_meal_page.dart';
import 'package:bytesync/features/meals/presentation/record_controller.dart';
import 'package:bytesync/features/pair/domain/pair.dart';
import 'package:bytesync/features/pair/domain/pair_state.dart';
import 'package:bytesync/features/pair/presentation/pair_controller.dart';

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

class _FixedPairController extends PairController {
  _FixedPairController({required this.withPartner});

  final bool withPartner;

  @override
  PairState build() => PairConnected(
        Pair(
          pairId: 'pair-1',
          inviteCode: 'ABC123',
          members: [
            const PairMember(
              userId: 'self-1',
              displayName: '我',
              avatarUrl: null,
              isSelf: true,
            ),
            if (withPartner)
              const PairMember(
                userId: 'partner-1',
                displayName: 'Harper',
                avatarUrl: null,
                isSelf: false,
              ),
          ],
          createdAt: DateTime(2026),
        ),
      );
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
    expect(state.draft.shareMode, MealShareMode.solo);
  });

  test('manual input becomes an editable solo draft', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    container.read(recordControllerProvider.notifier).loadManual(
          name: '鸡胸肉沙拉',
          calories: 600,
          protein: 50,
          carbs: 30,
          fat: 20,
        );
    container
        .read(recordControllerProvider.notifier)
        .setShareMode(MealShareMode.sharedMeOneThird);
    container.read(recordControllerProvider.notifier).setPortion(1.5);

    final state = container.read(recordControllerProvider) as RecordResult;
    expect(state.draft.source, MealSource.manual);
    expect(state.draft.baseCalories, 600);
    expect(state.draft.calories, 900);
    expect(state.draft.shareMode, MealShareMode.sharedMeOneThird);
  });

  testWidgets('error keeps the original input', (tester) async {
    final repository = _FakeMealAiRepository(error: Exception('network'));
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          mealAiRepositoryProvider.overrideWithValue(repository),
          yesterdayMealsProvider.overrideWith((ref) async => []),
          pairControllerProvider.overrideWith(
            () => _FixedPairController(withPartner: false),
          ),
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
          yesterdayMealsProvider.overrideWith((ref) async => []),
          pairControllerProvider.overrideWith(
            () => _FixedPairController(withPartner: false),
          ),
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
    expect(find.text('我吃'), findsOneWidget);
    expect(find.text('Ta 吃'), findsNothing);
  });

  testWidgets('paired result offers partner and shared allocation', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          mealAiRepositoryProvider.overrideWithValue(_FakeMealAiRepository()),
          yesterdayMealsProvider.overrideWith((ref) async => []),
          pairControllerProvider.overrideWith(
            () => _FixedPairController(withPartner: true),
          ),
        ],
        child: const MaterialApp(home: AddMealPage()),
      ),
    );

    await tester.enterText(find.byType(TextField).first, '600 kcal 晚餐');
    await tester.tap(find.text('AI 估算'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('一起吃'));
    await tester.tap(find.text('一起吃'));
    await tester.pump();

    expect(find.text('Ta 吃'), findsOneWidget);
    expect(find.text('1 : 1'), findsOneWidget);
    expect(find.text('分配预览：我 325 kcal  Harper 325 kcal'), findsOneWidget);
  });

  testWidgets('new text draft clears a stale selected image path', (
    tester,
  ) async {
    final container = ProviderContainer(
      overrides: [
        mealAiRepositoryProvider.overrideWithValue(_FakeMealAiRepository()),
        yesterdayMealsProvider.overrideWith((ref) async => []),
        pairControllerProvider.overrideWith(
          () => _FixedPairController(withPartner: false),
        ),
      ],
    );
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: AddMealPage()),
      ),
    );
    container.read(selectedRecordImagePathProvider.notifier).state =
        '/tmp/stale-meal.jpg';

    await tester.enterText(find.byType(TextField).first, '一碗牛肉面');
    await tester.tap(find.text('AI 估算'));
    await tester.pumpAndSettle();

    expect(container.read(selectedRecordImagePathProvider), isNull);
  });

  testWidgets('new manual draft clears a stale selected image path', (
    tester,
  ) async {
    final container = ProviderContainer(
      overrides: [
        yesterdayMealsProvider.overrideWith((ref) async => []),
        pairControllerProvider.overrideWith(
          () => _FixedPairController(withPartner: false),
        ),
      ],
    );
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: AddMealPage()),
      ),
    );
    container.read(selectedRecordImagePathProvider.notifier).state =
        '/tmp/stale-meal.jpg';

    final nameField = find.byWidgetPredicate(
      (widget) =>
          widget is TextField && widget.decoration?.labelText == '食物名称',
    );
    final caloriesField = find.byWidgetPredicate(
      (widget) =>
          widget is TextField && widget.decoration?.labelText == '卡路里',
    );
    await tester.enterText(nameField, '鸡胸肉沙拉');
    await tester.enterText(caloriesField, '600');
    await tester.ensureVisible(find.text('生成记录预览'));
    await tester.tap(find.text('生成记录预览'));
    await tester.pump();

    expect(container.read(selectedRecordImagePathProvider), isNull);
  });
}
