import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bytesync/core/network/api_exception.dart';
import 'package:bytesync/features/body/data/body_providers.dart';
import 'package:bytesync/features/body/data/body_repository.dart';
import 'package:bytesync/features/body/domain/body_data.dart';
import 'package:bytesync/features/body/presentation/onboarding_page.dart';
import 'package:bytesync/features/profile/domain/user_profile.dart';
import 'package:bytesync/l10n/app_localizations.dart';

class _RecommendationUnavailableRepository implements BodyRepository {
  BodyInput? lastRecommendationInput;

  @override
  Future<CalorieRecommendation> recommend(BodyInput input) async {
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

class _OnboardingUnavailableRepository
    extends _RecommendationUnavailableRepository {
  int submitCount = 0;

  @override
  Future<CalorieRecommendation> recommend(BodyInput input) async =>
      const CalorieRecommendation(
        calories: 2181,
        protein: 117,
        carbs: 291,
        fat: 61,
      );

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

void main() {
  testWidgets(
    'recommendation 404 keeps onboarding draft and manual goals available',
    (tester) async {
      final repository = _RecommendationUnavailableRepository();
      await tester.pumpWidget(
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

      await tester.enterText(_field('出生年份'), '1990');
      await tester.tap(find.byType(DropdownButtonFormField<String>).first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('男性').last);
      await tester.pumpAndSettle();
      await tester.enterText(_field('身高'), '170');
      await tester.enterText(_field('当前体重'), '70');
      await tester.tap(find.widgetWithText(FilledButton, '继续'));
      await tester.pumpAndSettle();

      await tester.enterText(_field('目标体重'), '65');
      await tester.tap(find.text('请选择目标日期'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('确定'));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(DropdownButtonFormField<String>).first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('中等活动').last);
      await tester.pumpAndSettle();

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

      expect(find.textContaining('当前体重：70 kg'), findsOneWidget);
      expect(find.textContaining('目标体重：65 kg'), findsOneWidget);
      expect(find.text('准备好了'), findsOneWidget);
    },
  );

  testWidgets(
    'onboarding 503 keeps draft and restores a retryable submit button',
    (tester) async {
      final repository = _OnboardingUnavailableRepository();
      await tester.pumpWidget(
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

      await tester.enterText(_field('出生年份'), '1990');
      await tester.tap(find.byType(DropdownButtonFormField<String>).first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('男性').last);
      await tester.pumpAndSettle();
      await tester.enterText(_field('身高'), '170');
      await tester.enterText(_field('当前体重'), '70');
      await tester.tap(find.widgetWithText(FilledButton, '继续'));
      await tester.pumpAndSettle();

      await tester.enterText(_field('目标体重'), '65');
      await tester.tap(find.text('请选择目标日期'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('确定'));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(DropdownButtonFormField<String>).first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('中等活动').last);
      await tester.pumpAndSettle();
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
