import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:bytesync/l10n/l10n.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/state_views.dart';
import '../../domain/training_duration.dart';
import '../../domain/training_exercise_item.dart';
import '../../domain/training_set_detail.dart';
import '../../domain/training_week.dart';
import '../../videos/domain/training_exercise_video.dart';
import '../../videos/presentation/training_exercise_video_controller.dart';
import '../../videos/presentation/training_exercise_video_editor.dart';
import '../training_controller.dart';
import 'training_history_controller.dart';

class TrainingHistoryPage extends ConsumerWidget {
  const TrainingHistoryPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(trainingHistoryControllerProvider);
    return Scaffold(
      appBar: AppBar(title: Text(appL10n.trainingHistory)),
      body: SafeArea(
        child: switch (state) {
          TrainingHistoryLoading() => const LoadingView(),
          TrainingHistoryFailure(:final message) => ErrorView(
            message: message,
            onRetry: () =>
                ref.read(trainingHistoryControllerProvider.notifier).refresh(),
          ),
          TrainingHistoryLoaded(:final history) => _HistoryList(
            history: history,
          ),
        },
      ),
    );
  }
}

class _HistoryList extends ConsumerWidget {
  const _HistoryList({required this.history});

  final TrainingWeekHistory history;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    if (history.weeks.isEmpty) {
      return RefreshIndicator(
        color: theme.colorScheme.primary,
        onRefresh: () =>
            ref.read(trainingHistoryControllerProvider.notifier).refresh(),
        child: ListView(
          physics: AlwaysScrollableScrollPhysics(),
          children: [
            SizedBox(height: 180),
            EmptyView(message: appL10n.trainingHistoryEmpty, icon: '🏋️'),
          ],
        ),
      );
    }
    return RefreshIndicator(
      color: theme.colorScheme.primary,
      onRefresh: () =>
          ref.read(trainingHistoryControllerProvider.notifier).refresh(),
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(AppSpacing.pagePadding),
        itemCount: history.weeks.length,
        separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.md),
        itemBuilder: (context, index) {
          final week = history.weeks[index];
          final completed = _completedSets(week);
          final target = _targetSets(week);
          return InkWell(
            borderRadius: BorderRadius.circular(AppRadius.lg),
            onTap: () => context.push(
              '/training/history/${Uri.encodeComponent(week.weekId)}',
            ),
            child: AppCard(
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          appL10n.trainingDateRange(
                            DateFormat(appL10n.trainingShortDateFormat)
                                .format(week.weekStart),
                            DateFormat(appL10n.trainingShortDateFormat)
                                .format(week.weekEnd),
                          ),
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          appL10n.trainingSetsProgress(completed, target),
                          style: TextStyle(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.chevron_right,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class TrainingHistoryDetailPage extends ConsumerWidget {
  const TrainingHistoryDetailPage({required this.weekId, super.key});

  final String weekId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final week = ref.watch(trainingWeekDetailProvider(weekId));
    return Scaffold(
      appBar: AppBar(title: Text(appL10n.trainingDetails)),
      body: SafeArea(
        child: week.when(
          loading: () => LoadingView(),
          error: (error, _) => ErrorView(
            message: trainingErrorMessage(
              error,
              fallback: appL10n.trainingDetailsLoadFailed,
            ),
            onRetry: () => ref.invalidate(trainingWeekDetailProvider(weekId)),
          ),
          data: (value) => _WeekDetail(week: value),
        ),
      ),
    );
  }
}

class _WeekDetail extends ConsumerWidget {
  const _WeekDetail({required this.week});

  final TrainingWeek week;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final videoState = ref.watch(trainingExerciseVideoControllerProvider);
    final videos = videoState is TrainingExerciseVideoReady
        ? videoState.videos
        : const <String, TrainingExerciseVideo>{};
    return ListView(
      padding: EdgeInsets.all(AppSpacing.pagePadding),
      children: [
        Text(
          appL10n.trainingDateRange(
            DateFormat(appL10n.trainingShortDateFormat).format(week.weekStart),
            DateFormat(appL10n.trainingShortDateFormat).format(week.weekEnd),
          ),
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
        ),
        SizedBox(height: AppSpacing.xs),
        Text(
          appL10n.trainingSetsProgress(_completedSets(week), _targetSets(week)),
          style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
        ),
        SizedBox(height: AppSpacing.lg),
        ...week.days.map(
          (day) => Padding(
            padding: EdgeInsets.only(bottom: AppSpacing.md),
            child: AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${_weekdayNames[day.dayIndex]}'
                    '${day.date == null ? '' : appL10n.trainingDateSuffix(DateFormat(appL10n.trainingMonthDayFormat).format(day.date!))}',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
                  ),
                  SizedBox(height: AppSpacing.md),
                  if (day.exercises.isEmpty)
                    Text(
                      appL10n.trainingRestDay,
                      style: TextStyle(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    )
                  else
                    ...day.exercises.map(
                      (exercise) => _HistoryExercise(
                        exercise: exercise,
                        videoUrl: exercise.exerciseId == null
                            ? null
                            : videos[exercise.exerciseId]?.videoUrl,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _HistoryExercise extends StatelessWidget {
  const _HistoryExercise({required this.exercise, required this.videoUrl});

  final TrainingExerciseItem exercise;
  final Uri? videoUrl;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.only(bottom: AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            exercise.exerciseName,
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          if (videoUrl != null)
            TextButton.icon(
              onPressed: () => openTrainingVideoUrl(context, videoUrl!),
              icon: Icon(Icons.play_circle_outline, size: 18),
              label: Text(appL10n.trainingViewVideo),
            ),
          SizedBox(height: AppSpacing.xs),
          Text(
            trainingTargetText(
              itemType: exercise.itemType,
              targetSets: exercise.targetSets,
              targetReps: exercise.targetReps,
              targetWeight: exercise.targetWeight,
              targetDurationSeconds: exercise.targetDurationSeconds,
            ),
            style: TextStyle(
              fontSize: 13,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          if (exercise.removedFromTemplate) ...[
            SizedBox(height: AppSpacing.xs),
            Text(
              appL10n.trainingRemovedFromTemplate,
              style: TextStyle(
                fontSize: 12,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
          SizedBox(height: AppSpacing.sm),
          if (exercise.setDetails.isEmpty)
            Text(
              appL10n.trainingIncompleteSets,
              style: TextStyle(
                fontSize: 12,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            )
          else
            ...exercise.setDetails.map(
              (detail) =>
                  _SetDetailRow(detail: detail, itemType: exercise.itemType),
            ),
        ],
      ),
    );
  }
}

class _SetDetailRow extends StatelessWidget {
  const _SetDetailRow({required this.detail, required this.itemType});

  final TrainingSetDetail detail;
  final TrainingItemType itemType;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final values = <String>[
      if (itemType == TrainingItemType.strength) ...[
        if (detail.weight != null)
          appL10n.trainingWeightValue(_weight(detail.weight!)),
        if (detail.reps != null) appL10n.trainingRepsValue(detail.reps!),
      ] else if (detail.durationSeconds != null)
        formatTrainingDuration(detail.durationSeconds!),
      if (detail.rpe != null) appL10n.trainingRpeValue(_weight(detail.rpe!)),
    ];
    return Container(
      margin: EdgeInsets.only(top: AppSpacing.xs),
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            appL10n.trainingHistorySetTime(
              detail.setIndex,
              DateFormat(appL10n.trainingTimeFormat)
                  .format(detail.completedAt.toLocal()),
            ),
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  values.isEmpty
                      ? appL10n.trainingCompleted
                      : values.join(' · '),
                  style: const TextStyle(fontSize: 13),
                ),
                if (detail.remark?.isNotEmpty == true) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    detail.remark!,
                    style: TextStyle(
                      fontSize: 12,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

int _completedSets(TrainingWeek week) {
  return week.days.fold(
    0,
    (sum, day) =>
        sum +
        day.exercises.fold(0, (value, item) => value + item.completedSets),
  );
}

int _targetSets(TrainingWeek week) {
  return week.days.fold(
    0,
    (sum, day) =>
        sum + day.exercises.fold(0, (value, item) => value + item.targetSets),
  );
}

List<String> get _weekdayNames => [
  appL10n.trainingWeekdayMonday,
  appL10n.trainingWeekdayTuesday,
  appL10n.trainingWeekdayWednesday,
  appL10n.trainingWeekdayThursday,
  appL10n.trainingWeekdayFriday,
  appL10n.trainingWeekdaySaturday,
  appL10n.trainingWeekdaySunday,
];

String _weight(double value) {
  return value == value.roundToDouble()
      ? value.toInt().toString()
      : value.toStringAsFixed(1);
}
