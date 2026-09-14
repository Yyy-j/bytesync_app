import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../data/training_providers.dart';
import '../data/training_repository.dart';
import '../domain/training_set_detail.dart';
import '../domain/training_week.dart';

sealed class TrainingState {
  const TrainingState();
}

class TrainingLoading extends TrainingState {
  const TrainingLoading();
}

class TrainingFailure extends TrainingState {
  const TrainingFailure(this.message);

  final String message;
}

class TrainingReady extends TrainingState {
  const TrainingReady({required this.week, required this.selectedDayIndex});

  final TrainingWeek week;
  final int selectedDayIndex;

  TrainingReady copyWith({TrainingWeek? week, int? selectedDayIndex}) {
    return TrainingReady(
      week: week ?? this.week,
      selectedDayIndex: selectedDayIndex ?? this.selectedDayIndex,
    );
  }
}

class TrainingCheckInOutcome {
  const TrainingCheckInOutcome.success({required this.duplicate})
    : errorMessage = null;
  const TrainingCheckInOutcome.failure(this.errorMessage) : duplicate = false;

  final bool duplicate;
  final String? errorMessage;
  bool get isSuccess => errorMessage == null;
}

class TrainingSetEditOutcome {
  const TrainingSetEditOutcome.success() : errorMessage = null;
  const TrainingSetEditOutcome.failure(this.errorMessage);

  final String? errorMessage;
  bool get isSuccess => errorMessage == null;
}

final trainingControllerProvider =
    NotifierProvider<TrainingController, TrainingState>(TrainingController.new);

class TrainingController extends Notifier<TrainingState> {
  late final TrainingRepository _repository;

  @override
  TrainingState build() {
    _repository = ref.watch(trainingRepositoryProvider);
    _load();
    return const TrainingLoading();
  }

  Future<bool> _load({bool preserveSelection = false}) async {
    final previous = preserveSelection ? state : null;
    if (!preserveSelection) state = const TrainingLoading();
    try {
      final result = await _repository.getCurrentWeek();
      final selectedDayIndex = preserveSelection && previous is TrainingReady
          ? previous.selectedDayIndex
          : _initialDayIndex(result.week);
      state = TrainingReady(
        week: result.week,
        selectedDayIndex: selectedDayIndex,
      );
      return true;
    } catch (error) {
      if (preserveSelection && previous is TrainingReady) {
        state = previous;
      } else {
        state = TrainingFailure(_message(error, fallback: '训练计划加载失败，请重试'));
      }
      return false;
    }
  }

  Future<void> refresh() async {
    await _load(preserveSelection: true);
  }

  void selectDay(int dayIndex) {
    final current = state;
    if (current is TrainingReady && dayIndex != current.selectedDayIndex) {
      state = current.copyWith(selectedDayIndex: dayIndex);
    }
  }

  Future<TrainingCheckInOutcome> checkInSet({
    required String itemId,
    required TrainingSetInput input,
  }) async {
    final current = state;
    if (current is! TrainingReady) {
      return const TrainingCheckInOutcome.failure('训练数据尚未加载，请稍后重试');
    }

    try {
      final result = await _repository.checkInSet(
        weekId: current.week.weekId,
        itemId: itemId,
        input: input,
      );
      final refreshed = await _load(preserveSelection: true);
      if (!refreshed) {
        return const TrainingCheckInOutcome.failure(
          '该组已记录，但刷新失败。请保持当前内容并重试',
        );
      }
      return TrainingCheckInOutcome.success(duplicate: result.duplicate);
    } catch (error) {
      return TrainingCheckInOutcome.failure(
        error is ConflictException
            ? '目标组数已完成，请刷新后查看最新进度'
            : _message(error, fallback: '打卡失败，请检查网络后重试'),
      );
    }
  }

  Future<TrainingSetEditOutcome> updateSetDetail({
    required String itemId,
    required String requestId,
    required TrainingSetDetailPatch patch,
  }) async {
    final current = state;
    if (current is! TrainingReady) {
      return const TrainingSetEditOutcome.failure('训练数据尚未加载，请稍后重试');
    }

    try {
      await _repository.updateSetDetail(
        weekId: current.week.weekId,
        itemId: itemId,
        requestId: requestId,
        patch: patch,
      );
      final refreshed = await _load(preserveSelection: true);
      if (!refreshed) {
        return const TrainingSetEditOutcome.failure(
          '该组已更新，但刷新失败。请保持当前内容并重试',
        );
      }
      return const TrainingSetEditOutcome.success();
    } catch (error) {
      return TrainingSetEditOutcome.failure(
        _message(error, fallback: '修改失败，请检查网络后重试'),
      );
    }
  }

  int _initialDayIndex(TrainingWeek week) {
    final now = DateTime.now();
    for (final day in week.days) {
      final date = day.date;
      if (date != null &&
          date.year == now.year &&
          date.month == now.month &&
          date.day == now.day) {
        return day.dayIndex;
      }
    }
    final today = DateTime(now.year, now.month, now.day);
    final start = DateTime(
      week.weekStart.year,
      week.weekStart.month,
      week.weekStart.day,
    );
    final offset = today.difference(start).inDays;
    return offset >= 0 && offset <= 6 ? offset : 0;
  }
}

String trainingErrorMessage(Object error, {required String fallback}) {
  return _message(error, fallback: fallback);
}

String _message(Object error, {required String fallback}) {
  return error is ApiException ? error.message : fallback;
}
