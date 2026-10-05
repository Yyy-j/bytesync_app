import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bytesync/core/network/api_exception.dart';
import 'package:bytesync/features/body/data/body_providers.dart';
import 'package:bytesync/features/body/data/body_repository.dart';
import 'package:bytesync/features/body/domain/body_data.dart';
import 'package:bytesync/features/body/domain/body_validation.dart';
import 'package:bytesync/features/body/presentation/onboarding_page.dart';
import 'package:bytesync/features/profile/domain/user_profile.dart';
import 'package:bytesync/l10n/app_localizations.dart';

class _RecommendationUnavailableRepository implements BodyRepository {
  BodyInput? lastRecommendationInput;
  int recommendCallCount = 0;

  @override
  Future<CalorieRecommendation> recommend(BodyInput input) async {
    recommendCallCount += 1;
    lastRecommendationInput = input;
    throw NotFoundException('当前服务器暂不支持热量推荐，请确认服务已更新后重试。你仍可手动设置目标并继续。');
  }

  @override
  Future<OnboardingResult> completeOnboarding(
    BodyInput input,
    NutritionGoals goals,
  ) => throw UnimplementedError();

  @override
  Future<WeightMeasurement> createWeight({
    required DateTime measuredOn,
    required double weightKg,
  }) => throw UnimplementedError();

  @override
  Future<void> deleteWeight(String id) => throw UnimplementedError();

  @override
  Future<BodyData> getBody() => throw UnimplementedError();

  @override
  Future<List<WeightMeasurement>> getWeights({int limit = 30}) =>
      throw UnimplementedError();

  @override
  Future<WeightMeasurement> updateWeight(
    String id, {
    required DateTime measuredOn,
    required double weightKg,
  }) => throw UnimplementedError();
}

class _SuccessfulRecommendationRepository
    extends _RecommendationUnavailableRepository {
  @override
  Future<CalorieRecommendation> recommend(BodyInput input) async {
    recommendCallCount += 1;
    lastRecommendationInput = input;
    return const CalorieRecommendation(
      calories: 2181,
      protein: 117,
      carbs: 291,
      fat: 61,
    );
  }
}

class _OnboardingUnavailableRepository
    extends _SuccessfulRecommendationRepository {
  int submitCount = 0;

  @override
  Future<OnboardingResult> completeOnboarding(
    BodyInput input,
    NutritionGoals goals,
  ) async {
    submitCount += 1;
    throw ServerException('Database unavailable', 503);
  }
}

Finder _field(String label) => find.widgetWithText(TextField, label);

Future<void> _pumpOnboarding(WidgetTester tester, BodyRepository repository) =>
    tester.pumpWidget(
      ProviderScope(
        overrides: [bodyRepositoryProvider.overrideWithValue(repository)],
        child: const MaterialApp(
          locale: Locale('zh'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: OnboardingPage(),
        ),
      ),
    );

Future<void> _enterBasic(
  WidgetTester tester, {
  String birthYear = '1990',
}) async {
  await tester.enterText(_field('出生年份'), birthYear);
  await tester.tap(find.byType(DropdownButtonFormField<String>).first);
  await tester.pumpAndSettle();
  await tester.tap(find.text('男性').last);
  await tester.pumpAndSettle();
  await tester.enterText(_field('身高'), '170');
  await tester.enterText(_field('当前体重'), '70');
  await tester.tap(find.widgetWithText(FilledButton, '继续'));
  await tester.pumpAndSettle();
}

Future<void> _enterGoal(WidgetTester tester) async {
  await tester.enterText(_field('目标体重'), '65');
  await tester.tap(find.text('请选择目标日期'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('确定'));
  await tester.pumpAndSettle();
  await tester.tap(find.byType(DropdownButtonFormField<String>).first);
  await tester.pumpAndSettle();
  await tester.tap(find.text('中等活动').last);
  await tester.pumpAndSettle();
}

Future<void> _enterGoals(
  WidgetTester tester, {
  String calories = '2000',
  String protein = '100',
  String carbs = '250',
  String fat = '60',
}) async {
  await tester.enterText(_field('推荐热量'), calories);
  await tester.enterText(_field('蛋白质'), protein);
  await tester.enterText(_field('碳水'), carbs);
  await tester.enterText(_field('脂肪'), fat);
}

Future<void> _saveGoals(WidgetTester tester) async {
  final save = find.widgetWithText(FilledButton, '保存');
  await tester.ensureVisible(save);
  await tester.tap(save);
  await tester.pumpAndSettle();
}

void main() {
  test('adult recommendation uses the backend birth-year boundary', () {
    final today = DateTime(2026, 10, 5);

    expect(canUseAdultRecommendation(2006, today: today), isTrue);
    expect(canUseAdultRecommendation(2007, today: today), isTrue);
    expect(canUseAdultRecommendation(2008, today: today), isFalse);
    expect(canUseAdultRecommendation(2009, today: today), isFalse);
  });

  testWidgets('recommendation 404 allows complete manual goals entry', (
    tester,
  ) async {
    final repository = _RecommendationUnavailableRepository();
    await _pumpOnboarding(tester, repository);
    await _enterBasic(tester);
    await _enterGoal(tester);

    final recommendButton = find.widgetWithText(FilledButton, '推荐每日目标');
    await tester.ensureVisible(recommendButton);
    await tester.tap(recommendButton);
    await tester.pumpAndSettle();

    expect(find.textContaining('当前服务器暂不支持热量推荐'), findsOneWidget);
    expect(find.text('Not Found'), findsNothing);
    expect(find.text('手动设置目标'), findsOneWidget);
    expect(repository.lastRecommendationInput?.currentWeightKg, 70);
    expect(repository.lastRecommendationInput?.targetWeightKg, 65);

    await tester.tap(find.text('手动设置目标'));
    await tester.pumpAndSettle();

    expect(_field('推荐热量'), findsOneWidget);
    expect(_field('蛋白质'), findsOneWidget);
    expect(_field('碳水'), findsOneWidget);
    expect(_field('脂肪'), findsOneWidget);
    await _enterGoals(tester);
    await _saveGoals(tester);

    expect(find.text('准备好了'), findsOneWidget);
    expect(
      find.text('每日目标：2000 kcal · P 100g · C 250g · F 60g'),
      findsOneWidget,
    );
  });

  testWidgets('manual goals reject zero and empty values', (tester) async {
    await _pumpOnboarding(tester, _RecommendationUnavailableRepository());
    await _enterBasic(tester);
    await _enterGoal(tester);
    await tester.tap(find.text('手动设置目标'));
    await tester.pumpAndSettle();

    await _enterGoals(tester, calories: '0');
    await _saveGoals(tester);
    expect(find.text('请填写有效的营养目标'), findsOneWidget);
    expect(_field('推荐热量'), findsOneWidget);
    expect(find.text('准备好了'), findsNothing);

    await tester.enterText(_field('推荐热量'), '');
    await _saveGoals(tester);
    expect(find.text('请填写有效的营养目标'), findsOneWidget);
    expect(_field('推荐热量'), findsOneWidget);
    expect(find.text('准备好了'), findsNothing);
  });

  testWidgets('recommended goals remain editable before confirmation', (
    tester,
  ) async {
    await _pumpOnboarding(tester, _SuccessfulRecommendationRepository());
    await _enterBasic(tester);
    await _enterGoal(tester);
    await tester.tap(find.widgetWithText(FilledButton, '推荐每日目标'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('调整目标'));
    await tester.pumpAndSettle();
    expect(tester.widget<TextField>(_field('推荐热量')).controller?.text, '2181');
    await tester.enterText(_field('推荐热量'), '2200');
    await _saveGoals(tester);

    expect(find.text('确认目标'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, '确认目标'));
    await tester.pumpAndSettle();
    expect(
      find.text('每日目标：2200 kcal · P 117g · C 291g · F 61g'),
      findsOneWidget,
    );
  });

  testWidgets('manual goals draft survives closing and reopening editor', (
    tester,
  ) async {
    await _pumpOnboarding(tester, _RecommendationUnavailableRepository());
    await _enterBasic(tester);
    await _enterGoal(tester);
    await tester.tap(find.text('手动设置目标'));
    await tester.pumpAndSettle();
    await _enterGoals(tester);

    tester.testTextInput.hide();
    await tester.pumpAndSettle();
    await tester.tapAt(const Offset(8, 8));
    await tester.pumpAndSettle();
    await tester.tap(find.text('手动设置目标'));
    await tester.pumpAndSettle();

    expect(tester.widget<TextField>(_field('推荐热量')).controller?.text, '2000');
    expect(tester.widget<TextField>(_field('蛋白质')).controller?.text, '100');
    expect(tester.widget<TextField>(_field('碳水')).controller?.text, '250');
    expect(tester.widget<TextField>(_field('脂肪')).controller?.text, '60');
  });

  testWidgets('18-year boundary skips recommendation but manual flow works', (
    tester,
  ) async {
    final repository = _SuccessfulRecommendationRepository();
    await _pumpOnboarding(tester, repository);
    await _enterBasic(tester, birthYear: '2008');
    await _enterGoal(tester);

    await tester.tap(find.widgetWithText(FilledButton, '推荐每日目标'));
    await tester.pumpAndSettle();
    expect(repository.recommendCallCount, 0);
    expect(find.textContaining('目前自动热量推荐仅适用于成年人'), findsWidgets);

    await tester.tap(find.text('手动设置目标'));
    await tester.pumpAndSettle();
    await _enterGoals(tester);
    await _saveGoals(tester);
    expect(find.text('准备好了'), findsOneWidget);
    expect(
      find.text('每日目标：2000 kcal · P 100g · C 250g · F 60g'),
      findsOneWidget,
    );
  });

  testWidgets(
    'onboarding 503 keeps draft and restores a retryable submit button',
    (tester) async {
      final repository = _OnboardingUnavailableRepository();
      await _pumpOnboarding(tester, repository);
      await _enterBasic(tester);
      await _enterGoal(tester);
      await tester.tap(find.widgetWithText(FilledButton, '推荐每日目标'));
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(FilledButton, '确认目标'));
      await tester.pumpAndSettle();
      expect(find.textContaining('当前体重：70 kg'), findsOneWidget);
      expect(find.textContaining('目标体重：65 kg'), findsOneWidget);

      final submit = find.widgetWithText(FilledButton, '开始使用 BiteSync');
      await tester.ensureVisible(submit);
      await tester.tap(submit);
      await tester.pumpAndSettle();

      expect(repository.submitCount, 1);
      expect(find.text('服务暂时不可用，请稍后重试。'), findsOneWidget);
      expect(find.text('Database unavailable'), findsNothing);
      expect(find.textContaining('当前体重：70 kg'), findsOneWidget);
      expect(find.textContaining('目标体重：65 kg'), findsOneWidget);
      expect(tester.widget<FilledButton>(submit).onPressed, isNotNull);
    },
  );
}
