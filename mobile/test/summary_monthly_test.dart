import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bytesync/core/network/api_exception.dart';
import 'package:bytesync/features/summary/data/summary_providers.dart';
import 'package:bytesync/features/summary/data/summary_repository.dart';
import 'package:bytesync/features/summary/domain/daily_summary.dart';
import 'package:bytesync/features/summary/presentation/summary_controller.dart';

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
      'days': [
        {
          'date':
              '${month.year.toString().padLeft(4, '0')}-${month.month.toString().padLeft(2, '0')}-01',
          'self_slice': {'calories': 0},
          'self_goals': {'calorie_goal': 2000},
          'partner_slice': null,
        },
      ],
    });
  }
}

void main() {
  test('monthly JSON parses zero calories and partner null', () {
    final summary = MonthlySummary.fromJson({
      'month': '2026-09',
      'days': [
        {
          'date': '2026-09-15',
          'self_slice': {'calories': 0},
          'self_goals': {'calorie_goal': 2000},
          'partner_slice': null,
        },
      ],
    });

    final day = summary.dayAt(DateTime(2026, 9, 15));
    expect(day?.selfCalories, 0);
    expect(day?.selfCalorieGoal, 2000);
    expect(day?.partnerCalories, isNull);
    expect(day?.partnerCalorieGoal, isNull);
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
