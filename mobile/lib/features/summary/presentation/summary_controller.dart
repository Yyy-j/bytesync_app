import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bytesync/l10n/l10n.dart';

import '../../../core/network/api_exception.dart';
import '../data/summary_providers.dart';
import '../data/summary_repository.dart';
import '../domain/daily_summary.dart';
import '../../pair/domain/pair_state.dart';
import '../../pair/presentation/pair_controller.dart';

/// UI state for the summary page: the four states required by the project
/// brief (loading / empty / success / error).
sealed class SummaryState {
  const SummaryState();
}

class SummaryLoading extends SummaryState {
  const SummaryLoading();
}

class SummaryEmpty extends SummaryState {
  const SummaryEmpty(this.summary);

  final DailySummary summary;
}

class SummaryLoaded extends SummaryState {
  const SummaryLoaded(this.summary);

  final DailySummary summary;
}

class SummaryFailure extends SummaryState {
  const SummaryFailure(this.message);

  final String message;
}

final summaryControllerProvider =
    NotifierProvider<SummaryController, SummaryState>(SummaryController.new);

/// Loads today's [DailySummary] and exposes it as one of the four states
/// above. [refresh] is called after a meal is successfully saved so the
/// summary page reflects it immediately, regardless of whether the mock or
/// real repository is in use.
class SummaryController extends Notifier<SummaryState> {
  late final SummaryRepository _repository;
  DateTime selectedDate = DateTime(
    DateTime.now().year,
    DateTime.now().month,
    DateTime.now().day,
  );
  DateTime focusedMonth = DateTime(DateTime.now().year, DateTime.now().month);
  final Map<DateTime, MonthlySummary> _monthlyCache = {};
  bool dailyLoading = false;
  String? dailyError;
  bool monthlyLoading = false;
  String? monthlyError;
  String? _pairScopeKey;
  MonthlySummary? get monthlySummary => _monthlyCache[_monthKey(focusedMonth)];

  @override
  SummaryState build() {
    _repository = ref.watch(summaryRepositoryProvider);
    ref.listen<PairState>(pairControllerProvider, (previous, next) {
      final nextScope = _scopeKey(next);
      if (_pairScopeKey != nextScope) {
        _pairScopeKey = nextScope;
        refresh();
      }
    });
    _pairScopeKey = _scopeKey(ref.read(pairControllerProvider));
    selectedDate = _dateOnly(DateTime.now());
    focusedMonth = DateTime(selectedDate.year, selectedDate.month);
    _loadInitial();
    return const SummaryLoading();
  }

  Future<void> _loadInitial() async {
    await Future.wait([
      _loadDaily(showLoading: true),
      _loadMonthly(focusedMonth),
    ]);
  }

  Future<void> _loadDaily({required bool showLoading}) async {
    if (showLoading) state = const SummaryLoading();
    dailyLoading = true;
    dailyError = null;
    _notify();
    try {
      final summary = await _repository.getDailySummary(selectedDate);
      state = summary.mealCount == 0
          ? SummaryEmpty(summary)
          : SummaryLoaded(summary);
    } catch (e) {
      final message = e is ApiException ? e.message : appL10n.todayLoadFailed;
      if (state is SummaryLoaded || state is SummaryEmpty) {
        dailyError = message;
        _notify();
      } else {
        state = SummaryFailure(message);
      }
    } finally {
      dailyLoading = false;
      _notify();
    }
  }

  Future<void> _loadMonthly(DateTime month, {bool force = false}) async {
    final key = _monthKey(month);
    if (!force && _monthlyCache.containsKey(key)) {
      monthlyError = null;
      return;
    }
    monthlyLoading = true;
    monthlyError = null;
    _notify();
    try {
      _monthlyCache[key] = await _repository.getMonthlySummary(month);
    } catch (error) {
      monthlyError = error is ApiException
          ? error.message
          : appL10n.todayLoadFailed;
    } finally {
      monthlyLoading = false;
      _notify();
    }
  }

  Future<void> selectDate(DateTime date) async {
    final next = _dateOnly(date);
    selectedDate = next;
    if (next.month != focusedMonth.month || next.year != focusedMonth.year) {
      focusedMonth = DateTime(next.year, next.month);
      await _loadMonthly(focusedMonth);
    }
    await _loadDaily(showLoading: false);
  }

  Future<void> changeMonth(DateTime month) async {
    final next = DateTime(month.year, month.month);
    focusedMonth = next;
    if (selectedDate.year != next.year || selectedDate.month != next.month) {
      selectedDate = DateTime(next.year, next.month, 1);
      await Future.wait([_loadMonthly(next), _loadDaily(showLoading: false)]);
      return;
    }
    await _loadMonthly(next);
  }

  Future<void> goToToday() async {
    final today = _dateOnly(DateTime.now());
    focusedMonth = DateTime(today.year, today.month);
    selectedDate = today;
    await Future.wait([
      _loadMonthly(focusedMonth),
      _loadDaily(showLoading: false),
    ]);
  }

  Future<void> refresh() async {
    _monthlyCache.remove(_monthKey(selectedDate));
    await Future.wait([
      _loadDaily(showLoading: false),
      _loadMonthly(focusedMonth, force: true),
    ]);
  }

  void _notify() {
    if (state is SummaryLoaded) {
      state = SummaryLoaded((state as SummaryLoaded).summary);
    } else if (state is SummaryEmpty) {
      state = SummaryEmpty((state as SummaryEmpty).summary);
    }
  }

  static DateTime _dateOnly(DateTime value) =>
      DateTime(value.year, value.month, value.day);
  static DateTime _monthKey(DateTime value) =>
      DateTime(value.year, value.month);

  static String _scopeKey(PairState state) {
    if (state is PairConnected && state.pair.isConnected) {
      return 'pair:${state.pair.pairId}';
    }
    return 'single';
  }
}
