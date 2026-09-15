import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bytesync/l10n/l10n.dart';

import '../../data/training_providers.dart';
import '../../data/training_repository.dart';
import '../../domain/training_week.dart';
import '../training_controller.dart';

sealed class TrainingHistoryState {
  const TrainingHistoryState();
}

class TrainingHistoryLoading extends TrainingHistoryState {
  const TrainingHistoryLoading();
}

class TrainingHistoryFailure extends TrainingHistoryState {
  const TrainingHistoryFailure(this.message);

  final String message;
}

class TrainingHistoryLoaded extends TrainingHistoryState {
  const TrainingHistoryLoaded(this.history);

  final TrainingWeekHistory history;
}

final trainingHistoryControllerProvider =
    NotifierProvider<TrainingHistoryController, TrainingHistoryState>(
      TrainingHistoryController.new,
    );

class TrainingHistoryController extends Notifier<TrainingHistoryState> {
  late final TrainingRepository _repository;

  @override
  TrainingHistoryState build() {
    _repository = ref.watch(trainingRepositoryProvider);
    _load();
    return const TrainingHistoryLoading();
  }

  Future<void> _load() async {
    state = const TrainingHistoryLoading();
    try {
      state = TrainingHistoryLoaded(await _repository.getWeekHistory());
    } catch (error) {
      state = TrainingHistoryFailure(
        trainingErrorMessage(
          error,
          fallback: appL10n.trainingHistoryLoadFailed,
        ),
      );
    }
  }

  Future<void> refresh() => _load();
}

final trainingWeekDetailProvider = FutureProvider.autoDispose
    .family<TrainingWeek, String>((ref, weekId) {
      return ref.watch(trainingRepositoryProvider).getWeek(weekId);
    });
