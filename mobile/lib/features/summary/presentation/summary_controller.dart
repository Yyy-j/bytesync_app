import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../data/summary_providers.dart';
import '../data/summary_repository.dart';
import '../domain/daily_summary.dart';

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

  @override
  SummaryState build() {
    _repository = ref.watch(summaryRepositoryProvider);
    _load();
    return const SummaryLoading();
  }

  DateTime get _today {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  Future<void> _load() async {
    state = const SummaryLoading();
    try {
      final summary = await _repository.getDailySummary(_today);
      state = summary.mealCount == 0
          ? SummaryEmpty(summary)
          : SummaryLoaded(summary);
    } catch (e) {
      state = SummaryFailure(e is ApiException ? e.message : '加载失败，请重试');
    }
  }

  Future<void> refresh() => _load();
}
