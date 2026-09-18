import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'package:bytesync/core/network/api_exception.dart';
import 'package:bytesync/features/summary/data/summary_providers.dart';
import 'package:bytesync/features/summary/data/summary_repository.dart';
import 'package:bytesync/features/summary/domain/daily_summary.dart';
import 'package:bytesync/features/summary/presentation/summary_controller.dart';
import 'package:bytesync/features/summary/presentation/summary_page.dart';

class _FakeSummaryRepository implements SummaryRepository {
  int monthlyCalls = 0;
  final List<DateTime> dailyDates = [];
  bool failMonthly = false;

  @override
  Future<DailySummary> getDailySummary(DateTime date) async {
    dailyDates.add(date);
    return DailySummary.empty(date);
  }

  @override
  Future<MonthlySummary> getMonthlySummary(DateTime month) async {
    monthlyCalls++;
    if (failMonthly) throw NetworkException();
    return MonthlySummary.fromJson({
      'month':
          '${month.year.toString().padLeft(4, '0')}-${month.month.toString().padLeft(2, '0')}',
      'self': {'calorie_goal': 2000},
      'partner': null,
      'days': [
        {
          'date':
              '${month.year.toString().padLeft(4, '0')}-${month.month.toString().padLeft(2, '0')}-01',
          'self_calories': 0,
          'partner_calories': null,
        },
      ],
    });
  }
}

class _FixedSummaryController extends SummaryController {
  _FixedSummaryController(this.monthly);

  final MonthlySummary monthly;

  @override
  MonthlySummary? get monthlySummary => monthly;

  @override
  SummaryState build() {
    focusedMonth = DateTime(2026, 9);
    selectedDate = DateTime(2026, 9, 15);
    return SummaryLoaded(DailySummary.empty(selectedDate));
  }
}

Future<void> _pumpSummaryPage(
  WidgetTester tester,
  MonthlySummary monthly,
) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        summaryControllerProvider.overrideWith(
          () => _FixedSummaryController(monthly),
        ),
      ],
      child: const MaterialApp(home: SummaryPage()),
    ),
  );
  await tester.pump();
}

void main() {
  setUpAll(() async {
    await initializeDateFormatting('zh_CN');
  });

  test('monthly JSON parses goals and calories from the backend contract', () {
    final summary = MonthlySummary.fromJson({
      'month': '2026-09',
      'self': {'calorie_goal': 2000},
      'partner': {'display_name': 'hh', 'calorie_goal': 1700},
      'days': [
        {
          'date': '2026-09-15',
          'self_calories': 385,
          'partner_calories': 2532,
        },
      ],
    });

    final day = summary.dayAt(DateTime(2026, 9, 15));
    expect(summary.self.calorieGoal, 2000);
    expect(summary.partner?.calorieGoal, 1700);
    expect(day?.selfCalories, 385);
    expect(day?.partnerCalories, 2532);
    expect(
      (day!.selfCalories / summary.self.calorieGoal).clamp(0.0, 1.0),
      closeTo(0.1925, 0.0001),
    );
    expect(
      (day.partnerCalories! / summary.partner!.calorieGoal).clamp(0.0, 1.0),
      1.0,
    );
  });

  test('monthly JSON without partner only provides self data', () {
    final summary = MonthlySummary.fromJson({
      'month': '2026-09',
      'self': {'calorie_goal': 2000},
      'partner': null,
      'days': [
        {
          'date': '2026-09-15',
          'self_calories': 385,
          'partner_calories': null,
        },
      ],
    });

    expect(summary.partner, isNull);
    expect(summary.dayAt(DateTime(2026, 9, 15))?.partnerCalories, isNull);
  });

  testWidgets('Calendar shows only Self bar without a monthly partner', (
    tester,
  ) async {
    final summary = MonthlySummary.fromJson({
      'month': '2026-09',
      'self': {'calorie_goal': 2000},
      'partner': null,
      'days': [
        {
          'date': '2026-09-15',
          'self_calories': 385,
          'partner_calories': null,
        },
      ],
    });

    await _pumpSummaryPage(tester, summary);

    expect(
      tester.widgetList<LinearProgressIndicator>(
        find.byType(LinearProgressIndicator),
      ),
      hasLength(30),
    );
  });

  testWidgets('Calendar uses monthly goals and clamps partner progress', (
    tester,
  ) async {
    final summary = MonthlySummary.fromJson({
      'month': '2026-09',
      'self': {'calorie_goal': 2000},
      'partner': {'display_name': 'hh', 'calorie_goal': 1700},
      'days': [
        {
          'date': '2026-09-17',
          'self_calories': 385,
          'partner_calories': 2532,
        },
      ],
    });

    await _pumpSummaryPage(tester, summary);

    final progress = tester
        .widgetList<LinearProgressIndicator>(
          find.byType(LinearProgressIndicator),
        )
        .map((indicator) => indicator.value)
        .whereType<double>()
        .toList();
    expect(progress, contains(closeTo(0.1925, 0.0001)));
    expect(progress, contains(1.0));
  });

  test('malformed monthly JSON throws FormatException', () {
    expect(
      () => MonthlySummary.fromJson({'month': '2026-09'}),
      throwsFormatException,
    );
  });

  test('controller selects dates and reuses monthly cache', () async {
    final repository = _FakeSummaryRepository();
    final container = ProviderContainer(
      overrides: [summaryRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(container.dispose);

    final controller = container.read(summaryControllerProvider.notifier);
    await Future<void>.delayed(const Duration(milliseconds: 10));
    expect(controller.selectedDate.day, DateTime.now().day);
    final initialMonthlyCalls = repository.monthlyCalls;

    await controller.selectDate(DateTime(2026, 9, 15));
    expect(controller.selectedDate, DateTime(2026, 9, 15));
    expect(repository.dailyDates.last, DateTime(2026, 9, 15));

    await controller.changeMonth(DateTime(2026, 8));
    await controller.changeMonth(DateTime(2026, 9));
    expect(repository.monthlyCalls, initialMonthlyCalls + 1);

    await controller.goToToday();
    expect(controller.selectedDate.day, DateTime.now().day);
  });

  test('monthly failure stays separate from daily state', () async {
    final repository = _FakeSummaryRepository()..failMonthly = true;
    final container = ProviderContainer(
      overrides: [summaryRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(container.dispose);

    final controller = container.read(summaryControllerProvider.notifier);
    await Future<void>.delayed(const Duration(milliseconds: 10));

    expect(controller.monthlyError, isNotNull);
    expect(controller.dailyError, isNull);
  });
}
