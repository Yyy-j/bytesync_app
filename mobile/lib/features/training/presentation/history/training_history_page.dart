import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

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
      appBar: AppBar(title: const Text('训练历史')),
      body: SafeArea(
        child: switch (state) {
          TrainingHistoryLoading() => const LoadingView(),
          TrainingHistoryFailure(:final message) => ErrorView(
            message: message,
            onRetry: () => ref
                .read(trainingHistoryControllerProvider.notifier)
                .refresh(),
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
    if (history.weeks.isEmpty) {
      return RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () =>
            ref.read(trainingHistoryControllerProvider.notifier).refresh(),
        child: ListView(
          physics: AlwaysScrollableScrollPhysics(),
          children: [
            SizedBox(height: 180),
            EmptyView(message: '还没有训练历史', icon: '🏋️'),
          ],
        ),
      );
    }
    return RefreshIndicator(
      color: AppColors.primary,
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
                          '${DateFormat('M/d').format(week.weekStart)} - '
                          '${DateFormat('M/d').format(week.weekEnd)}',
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          '$completed / $target 组',
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.chevron_right,
                    color: AppColors.textTertiary,
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
      appBar: AppBar(title: const Text('训练详情')),
      body: SafeArea(
        child: week.when(
          loading: () => const LoadingView(),
          error: (error, _) => ErrorView(
            message: trainingErrorMessage(error, fallback: '训练详情加载失败，请重试'),
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
    final videoState = ref.watch(trainingExerciseVideoControllerProvider);
    final videos = videoState is TrainingExerciseVideoReady
        ? videoState.videos
        : const <String, TrainingExerciseVideo>{};
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.pagePadding),
      children: [
        Text(
          '${DateFormat('M/d').format(week.weekStart)} - '
          '${DateFormat('M/d').format(week.weekEnd)}',
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          '${_completedSets(week)} / ${_targetSets(week)} 组',
          style: const TextStyle(color: AppColors.textSecondary),
        ),
        const SizedBox(height: AppSpacing.lg),
        ...week.days.map(
          (day) => Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.md),
            child: AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${_weekdayNames[day.dayIndex]}'
                    '${day.date == null ? '' : ' · ${DateFormat('M月d日').format(day.date!)}'}',
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  if (day.exercises.isEmpty)
                    const Text(
                      '休息日',
                      style: TextStyle(color: AppColors.textSecondary),
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
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            exercise.exerciseName,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          if (videoUrl != null)
            TextButton.icon(
              onPressed: () => openTrainingVideoUrl(context, videoUrl!),
              icon: const Icon(Icons.play_circle_outline, size: 18),
              label: const Text('查看教学视频'),
            ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            trainingTargetText(
              itemType: exercise.itemType,
              targetSets: exercise.targetSets,
              targetReps: exercise.targetReps,
              targetWeight: exercise.targetWeight,
              targetDurationSeconds: exercise.targetDurationSeconds,
            ),
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
          if (exercise.removedFromTemplate) ...[
            const SizedBox(height: AppSpacing.xs),
            const Text(
              '已从当前模板移除',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.textTertiary,
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.sm),
          if (exercise.setDetails.isEmpty)
            const Text(
              '未完成训练组',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.textTertiary,
              ),
            )
          else
            ...exercise.setDetails.map(
              (detail) => _SetDetailRow(
                detail: detail,
                itemType: exercise.itemType,
              ),
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
    final values = <String>[
      if (itemType == TrainingItemType.strength) ...[
        if (detail.weight != null) '${_weight(detail.weight!)} kg',
        if (detail.reps != null) '${detail.reps} reps',
      ] else if (detail.durationSeconds != null)
        formatTrainingDuration(detail.durationSeconds!),
      if (detail.rpe != null) 'RPE ${_weight(detail.rpe!)}',
    ];
    return Container(
      margin: const EdgeInsets.only(top: AppSpacing.xs),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '第 ${detail.setIndex} 组 · '
            '${DateFormat('HH:mm').format(detail.completedAt.toLocal())}',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  values.isEmpty ? '已完成' : values.join(' · '),
                  style: const TextStyle(fontSize: 13),
                ),
                if (detail.remark?.isNotEmpty == true) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    detail.remark!,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
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
        day.exercises.fold(
          0,
          (value, item) => value + item.completedSets,
        ),
  );
}

int _targetSets(TrainingWeek week) {
  return week.days.fold(
    0,
    (sum, day) =>
        sum +
        day.exercises.fold(0, (value, item) => value + item.targetSets),
  );
}

const _weekdayNames = ['周一', '周二', '周三', '周四', '周五', '周六', '周日'];

String _weight(double value) {
  return value == value.roundToDouble()
      ? value.toInt().toString()
      : value.toStringAsFixed(1);
}
