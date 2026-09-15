import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bytesync/features/meals/data/meal_ai_repository.dart';
import 'package:bytesync/features/meals/data/meals_providers.dart';
import 'package:bytesync/features/meals/data/meals_repository.dart';
import 'package:bytesync/features/meals/domain/meal.dart';
import 'package:bytesync/features/meals/domain/meal_ai_result.dart';
import 'package:bytesync/features/meals/domain/meal_patch.dart';
import 'package:bytesync/features/meals/domain/meal_share_mode.dart';
import 'package:bytesync/features/meals/domain/meal_source.dart';
import 'package:bytesync/features/meals/presentation/add_meal_page.dart';
import 'package:bytesync/features/meals/presentation/record_controller.dart';
import 'package:bytesync/features/pair/domain/pair.dart';
import 'package:bytesync/features/pair/domain/pair_state.dart';
import 'package:bytesync/features/pair/presentation/pair_controller.dart';
import 'package:bytesync/features/summary/domain/daily_summary.dart';
import 'package:bytesync/features/summary/presentation/summary_controller.dart';

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

class _FakeImageMealAiRepository
    implements MealAiRepository, MealImageAiRepository {
  String? lastImagePath;
  String? lastHint;

  @override
  Future<MealAiResult> analyzeText(String text) async => _result;

  @override
  Future<MealAiResult> analyzeImage(String imagePath, {String? hint}) async {
    lastImagePath = imagePath;
    lastHint = hint;
    return _result;
  }
}

class _PendingMealAiRepository implements MealAiRepository {
  final result = Completer<MealAiResult>();

  @override
  Future<MealAiResult> analyzeText(String text) => result.future;
}

class _SavingMealsRepository implements MealsRepository {
  _SavingMealsRepository({this.saveError});

  final Object? saveError;
  NewMealInput? savedInput;

  @override
  Future<Meal> addMeal(NewMealInput input) async {
    if (saveError != null) throw saveError!;
    savedInput = input;
    return _meal(name: input.name, source: input.source);
  }

  @override
  Future<void> deleteMeal(String id) => throw UnimplementedError();

  @override
  Future<Meal> getMealById(String id) => throw UnimplementedError();

  @override
  Future<List<Meal>> getMealsForDate(DateTime date) =>
      throw UnimplementedError();

  @override
  Future<List<Meal>> getMealsForReuse({
    required DateTime date,
    int limit = 3,
  }) => throw UnimplementedError();

  @override
  Future<List<Meal>> getRecentMealsForReuse({int limit = 3}) =>
      throw UnimplementedError();

  @override
  Future<Meal> updateMeal(String id, MealPatch patch) =>
      throw UnimplementedError();
}

class _FixedSummaryController extends SummaryController {
  @override
  SummaryState build() => SummaryLoaded(DailySummary.empty(DateTime(2026)));

  @override
  Future<void> refresh() async {}
}

Meal _meal({String name = '牛肉面套餐', MealSource source = MealSource.ai}) => Meal(
  id: 'meal-1',
  pairId: 'pair-1',
  userId: 'self-1',
  sharedMealId: null,
  name: name,
  source: source,
  baseCalories: 650,
  baseProtein: 32,
  baseCarbs: 78,
  baseFat: 22,
  calories: 650,
  protein: 32,
  carbs: 78,
  fat: 22,
  portionRatio: 1,
  shareRatio: 1,
  shareMode: MealShareMode.solo,
  mealDate: DateTime(2026, 9, 15),
  mealTime: '12:00',
  createdAt: DateTime(2026, 9, 15),
  updatedAt: DateTime(2026, 9, 15),
);

class _FixedPairController extends PairController {
  _FixedPairController({required this.withPartner});

  final bool withPartner;

  @override
  PairState build() => PairConnected(
    Pair(
      pairId: 'pair-1',
      inviteCode: 'ABC123',
      members: [
        const PairMember(userId: 'self-1', displayName: '我', isSelf: true),
        if (withPartner)
          const PairMember(
            userId: 'partner-1',
            displayName: 'Harper',
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

  test('image analysis forwards the unified input as hint', () async {
    final repository = _FakeImageMealAiRepository();
    final container = ProviderContainer(
      overrides: [mealAiRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(container.dispose);

    final submitted = await container
        .read(recordControllerProvider.notifier)
        .analyzeImage('/tmp/meal.jpg', hint: '米饭只有半碗');

    expect(submitted, isTrue);
    expect(repository.lastImagePath, '/tmp/meal.jpg');
    expect(repository.lastHint, '米饭只有半碗');
    expect(container.read(recordControllerProvider), isA<RecordResult>());
  });

  test('manual input becomes an editable solo draft', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    container
        .read(recordControllerProvider.notifier)
        .loadManual(
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
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('record-send-button')));
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
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('record-send-button')));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('record-unified-input')), findsNothing);
    expect(find.text('识别完成'), findsOneWidget);
    expect(find.text('菜品：牛肉面、煎蛋'), findsOneWidget);
    expect(find.text('AI 估算，仅供参考'), findsOneWidget);
    expect(find.text('只记录给我'), findsOneWidget);
    expect(find.text('只给 Ta 记'), findsNothing);
  });

  testWidgets('text analysis replaces idle with its loading page', (
    tester,
  ) async {
    final repository = _PendingMealAiRepository();
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

    await tester.enterText(find.byType(TextField).first, '鸡肉饭');
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('record-send-button')));
    await tester.pump();

    expect(find.text('查询中…'), findsOneWidget);
    expect(find.text('正在估算这份料理'), findsOneWidget);
    expect(find.byKey(const ValueKey('record-unified-input')), findsNothing);

    repository.result.complete(_result);
    await tester.pumpAndSettle();
  });

  testWidgets('tapping the record page dismisses the keyboard', (tester) async {
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
    await tester.enterText(input, '一份沙拉');
    await tester.showKeyboard(input);
    await tester.pump();
    expect(tester.binding.focusManager.primaryFocus, isNotNull);

    await tester.tap(find.text('拍一餐').first);
    await tester.pump();
    expect(
      tester.binding.focusManager.primaryFocus,
      isNot(isA<EditableTextState>()),
    );
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
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('record-send-button')));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('一起吃'));
    await tester.tap(find.text('一起吃'));
    await tester.pump();

    expect(find.text('只给 Ta 记'), findsOneWidget);
    expect(find.text('一人一半'), findsOneWidget);
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
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('record-send-button')));
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

    await tester.tap(find.text('手动记录一餐'));
    await tester.pumpAndSettle();

    final nameField = find.byWidgetPredicate(
      (widget) => widget is TextField && widget.decoration?.labelText == '食物名称',
    );
    final caloriesField = find.byWidgetPredicate(
      (widget) =>
          widget is TextField && widget.decoration?.labelText == '卡路里 *',
    );
    await tester.enterText(nameField, '鸡胸肉沙拉');
    await tester.enterText(caloriesField, '600');
    await tester.ensureVisible(find.text('生成记录'));
    await tester.tap(find.text('生成记录'));
    await tester.pump();

    expect(container.read(selectedRecordImagePathProvider), isNull);
    expect(find.text('手动记录'), findsOneWidget);
  });

  testWidgets('idle is minimal and manual form starts collapsed', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          yesterdayMealsProvider.overrideWith((ref) async => []),
          pairControllerProvider.overrideWith(
            () => _FixedPairController(withPartner: false),
          ),
        ],
        child: const MaterialApp(home: AddMealPage()),
      ),
    );

    expect(find.text('拍一餐'), findsNWidgets(2));
    expect(find.text('饭前拍一下，轻轻记录这一餐'), findsOneWidget);
    expect(find.text('记录饮食'), findsNothing);
    expect(find.text('AI 识别'), findsNothing);
    expect(find.byKey(const ValueKey('record-manual-form')), findsNothing);
    final input = tester.widget<TextField>(
      find.byKey(const ValueKey('record-unified-input')),
    );
    expect(input.maxLength, 80);
    expect(input.decoration?.counterText, '');

    await tester.tap(find.text('手动记录一餐'));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('record-manual-form')), findsOneWidget);
    expect(find.text('卡路里 *'), findsOneWidget);
  });

  testWidgets('empty text send is disabled and camera opens source sheet', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          yesterdayMealsProvider.overrideWith((ref) async => []),
          pairControllerProvider.overrideWith(
            () => _FixedPairController(withPartner: false),
          ),
        ],
        child: const MaterialApp(home: AddMealPage()),
      ),
    );

    final send = tester.widget<IconButton>(
      find.byKey(const ValueKey('record-send-button')),
    );
    expect(send.onPressed, isNull);

    await tester.tap(find.byKey(const ValueKey('record-camera-button')));
    await tester.pumpAndSettle();
    expect(find.text('拍照'), findsOneWidget);
    expect(find.text('从相册选择'), findsOneWidget);
    expect(find.text('取消'), findsOneWidget);
  });

  testWidgets('yesterday meal fills and expands manual form', (tester) async {
    final yesterday = Meal(
      id: 'meal-1',
      pairId: 'pair-1',
      userId: 'self-1',
      sharedMealId: null,
      name: '番茄炒蛋',
      source: MealSource.manual,
      baseCalories: 420,
      baseProtein: 18,
      baseCarbs: 32,
      baseFat: 21,
      calories: 420,
      protein: 18,
      carbs: 32,
      fat: 21,
      portionRatio: 1,
      shareRatio: 1,
      shareMode: MealShareMode.solo,
      mealDate: DateTime(2026, 9, 14),
      mealTime: '12:00',
      createdAt: DateTime(2026, 9, 14),
      updatedAt: DateTime(2026, 9, 14),
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          yesterdayMealsProvider.overrideWith((ref) async => [yesterday]),
          pairControllerProvider.overrideWith(
            () => _FixedPairController(withPartner: false),
          ),
        ],
        child: const MaterialApp(home: AddMealPage()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('昨天也吃了？'), findsOneWidget);
    await tester.tap(find.text('添加'));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('record-manual-form')), findsOneWidget);
    expect(find.text('番茄炒蛋'), findsWidgets);
    final caloriesField = tester.widget<TextField>(
      find.byWidgetPredicate(
        (widget) =>
            widget is TextField && widget.decoration?.labelText == '卡路里 *',
      ),
    );
    expect(caloriesField.controller?.text, '420');
  });

  testWidgets('light and dark modes select matching SVG assets', (
    tester,
  ) async {
    Widget page(ThemeData theme) => ProviderScope(
      overrides: [
        yesterdayMealsProvider.overrideWith((ref) async => []),
        pairControllerProvider.overrideWith(
          () => _FixedPairController(withPartner: false),
        ),
      ],
      child: MaterialApp(theme: theme, home: const AddMealPage()),
    );

    await tester.pumpWidget(page(ThemeData.light()));
    expect(find.byKey(const ValueKey('record-add-green-svg')), findsOneWidget);
    expect(find.byKey(const ValueKey('record-send-green-svg')), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpWidget(page(ThemeData.dark()));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('record-add-blue-svg')), findsOneWidget);
    expect(find.byKey(const ValueKey('record-send-blue-svg')), findsOneWidget);
  });

  testWidgets('successful image save returns to a fresh empty idle page', (
    tester,
  ) async {
    final aiRepository = _FakeImageMealAiRepository();
    final mealsRepository = _SavingMealsRepository();
    final container = ProviderContainer(
      overrides: [
        mealAiRepositoryProvider.overrideWithValue(aiRepository),
        mealsRepositoryProvider.overrideWithValue(mealsRepository),
        yesterdayMealsProvider.overrideWith((ref) async => []),
        pairControllerProvider.overrideWith(
          () => _FixedPairController(withPartner: false),
        ),
        summaryControllerProvider.overrideWith(_FixedSummaryController.new),
      ],
    );
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: AddMealPage()),
      ),
    );

    final inputFinder = find.byKey(const ValueKey('record-unified-input'));
    await tester.enterText(inputFinder, '米饭只有半碗');
    container.read(selectedRecordImagePathProvider.notifier).state =
        '/tmp/meal.jpg';
    await container
        .read(recordControllerProvider.notifier)
        .analyzeImage('/tmp/meal.jpg', hint: '米饭只有半碗');
    await tester.pumpAndSettle();

    expect(find.text('识别完成'), findsOneWidget);
    await tester.ensureVisible(
      find.byKey(const ValueKey('record-save-button')),
    );
    await tester.tap(find.byKey(const ValueKey('record-save-button')));
    await tester.pumpAndSettle();

    expect(container.read(recordControllerProvider), isA<RecordIdle>());
    expect(container.read(selectedRecordImagePathProvider), isNull);
    expect(mealsRepository.savedInput?.aiHint, '米饭只有半碗');
    final idleInput = tester.widget<TextField>(inputFinder);
    expect(idleInput.controller?.text, isEmpty);
  });

  testWidgets('failed image save keeps hint image and draft', (tester) async {
    final container = ProviderContainer(
      overrides: [
        mealAiRepositoryProvider.overrideWithValue(
          _FakeImageMealAiRepository(),
        ),
        mealsRepositoryProvider.overrideWithValue(
          _SavingMealsRepository(saveError: Exception('save failed')),
        ),
        yesterdayMealsProvider.overrideWith((ref) async => []),
        pairControllerProvider.overrideWith(
          () => _FixedPairController(withPartner: false),
        ),
        summaryControllerProvider.overrideWith(_FixedSummaryController.new),
      ],
    );
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: AddMealPage()),
      ),
    );

    await tester.enterText(
      find.byKey(const ValueKey('record-unified-input')),
      '少油少盐',
    );
    container.read(selectedRecordImagePathProvider.notifier).state =
        '/tmp/meal.jpg';
    await container
        .read(recordControllerProvider.notifier)
        .analyzeImage('/tmp/meal.jpg', hint: '少油少盐');
    await tester.pumpAndSettle();
    await tester.ensureVisible(
      find.byKey(const ValueKey('record-save-button')),
    );
    await tester.tap(find.byKey(const ValueKey('record-save-button')));
    await tester.pumpAndSettle();

    final failedState = container.read(recordControllerProvider);
    expect(failedState, isA<RecordError>());
    expect((failedState as RecordError).draft, isNotNull);
    expect(container.read(selectedRecordImagePathProvider), '/tmp/meal.jpg');

    container.read(recordControllerProvider.notifier).clear();
    await tester.pump();
    final idleInput = tester.widget<TextField>(
      find.byKey(const ValueKey('record-unified-input')),
    );
    expect(idleInput.controller?.text, '少油少盐');
  });
}
