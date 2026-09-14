import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/state_views.dart';
import '../domain/training_day.dart';
import '../domain/training_duration.dart';
import '../domain/training_exercise_item.dart';
import '../domain/training_set_detail.dart';
import 'training_controller.dart';

class TrainingPage extends ConsumerWidget {
  const TrainingPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(trainingControllerProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('训练')),
      body: SafeArea(
        child: switch (state) {
          TrainingLoading() => const LoadingView(message: '正在加载本周训练'),
          TrainingFailure(:final message) => ErrorView(
            message: message,
            onRetry: () =>
                ref.read(trainingControllerProvider.notifier).refresh(),
          ),
          TrainingReady() => _TrainingBody(state: state),
        },
      ),
    );
  }
}

class _TrainingBody extends ConsumerWidget {
  const _TrainingBody({required this.state});

  final TrainingReady state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final week = state.week;
    final selectedDay = _findDay(week.days, state.selectedDayIndex);

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: () => ref.read(trainingControllerProvider.notifier).refresh(),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(AppSpacing.pagePadding),
        children: [
          Text(
            '本周 ${DateFormat('M/d').format(week.weekStart)} - '
            '${DateFormat('M/d').format(week.weekEnd)}',
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          _WeekSelector(
            weekStart: week.weekStart,
            selectedDayIndex: state.selectedDayIndex,
            onSelected: (dayIndex) => ref
                .read(trainingControllerProvider.notifier)
                .selectDay(dayIndex),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => context.push('/training/template'),
                  icon: const Icon(Icons.edit_calendar_outlined),
                  label: const Text('编辑训练计划'),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => context.push('/training/history'),
                  icon: const Icon(Icons.history),
                  label: const Text('训练历史'),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
          Text(
            _dayHeading(selectedDay, state.selectedDayIndex),
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: AppSpacing.md),
          if (selectedDay == null || selectedDay.exercises.isEmpty)
            const Padding(
              padding: EdgeInsets.only(top: AppSpacing.xxl),
              child: EmptyView(message: '这天没有训练计划', icon: '🏋️'),
            )
          else
            ...selectedDay.exercises.map(
              (exercise) => Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.md),
                child: _ExerciseCard(exercise: exercise),
              ),
            ),
        ],
      ),
    );
  }

  String _dayHeading(TrainingDay? day, int dayIndex) {
    final date = day?.date;
    final dateText = date == null ? '' : ' · ${DateFormat('M月d日').format(date)}';
    return '${_weekdayNames[dayIndex]}$dateText';
  }
}

class _WeekSelector extends StatelessWidget {
  const _WeekSelector({
    required this.weekStart,
    required this.selectedDayIndex,
    required this.onSelected,
  });

  final DateTime weekStart;
  final int selectedDayIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    return Row(
      children: List.generate(7, (index) {
        final date = weekStart.add(Duration(days: index));
        final selected = index == selectedDayIndex;
        final isToday = date.year == now.year &&
            date.month == now.month &&
            date.day == now.day;
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(right: index == 6 ? 0 : AppSpacing.xs),
            child: InkWell(
              borderRadius: BorderRadius.circular(AppRadius.md),
              onTap: () => onSelected(index),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                decoration: BoxDecoration(
                  color: selected
                      ? AppColors.primary
                      : AppColors.cardBackground,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  border: Border.all(
                    color: isToday && !selected
                        ? AppColors.primary
                        : AppColors.border,
                  ),
                ),
                child: Column(
                  children: [
                    Text(
                      _weekdayNames[index],
                      style: TextStyle(
                        fontSize: 12,
                        color: selected
                            ? Colors.white
                            : AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      '${date.day}',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: selected ? Colors.white : AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }),
    );
  }
}

class _ExerciseCard extends StatelessWidget {
  const _ExerciseCard({required this.exercise});

  final TrainingExerciseItem exercise;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: exercise.removedFromTemplate ? 0.62 : 1,
      child: AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    exercise.exerciseName,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                if (exercise.category.isNotEmpty)
                  Text(
                    exercise.category,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textTertiary,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              trainingTargetText(
                itemType: exercise.itemType,
                targetSets: exercise.targetSets,
                targetReps: exercise.targetReps,
                targetWeight: exercise.targetWeight,
                targetDurationSeconds: exercise.targetDurationSeconds,
              ),
              style: const TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              '进度：${exercise.completedSets} / ${exercise.targetSets} 组',
              style: const TextStyle(
                color: AppColors.primaryDark,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (exercise.setDetails.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.sm),
              ...exercise.setDetails.map(
                (detail) => _CompletedSetRow(
                  itemType: exercise.itemType,
                  detail: detail,
                  onTap: () => _openSetEditSheet(context, detail),
                ),
              ),
            ],
            if (exercise.removedFromTemplate) ...[
              const SizedBox(height: AppSpacing.sm),
              const Text(
                '已从当前模板移除',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
            const SizedBox(height: AppSpacing.md),
            SizedBox(
              width: double.infinity,
              child: FilledButton.tonal(
                onPressed: exercise.removedFromTemplate ||
                        exercise.completedSets >= exercise.targetSets
                    ? null
                    : () => _openCheckInSheet(context),
                child: const Text('完成一组'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openCheckInSheet(BuildContext context) async {
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => _CheckInSheet(exercise: exercise),
    );
    if (saved == true && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('已完成一组')),
      );
    }
  }

  Future<void> _openSetEditSheet(
    BuildContext context,
    TrainingSetDetail detail,
  ) async {
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => _SetEditSheet(exercise: exercise, detail: detail),
    );
    if (saved == true && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('该组记录已更新')),
      );
    }
  }
}

class _CompletedSetRow extends StatelessWidget {
  const _CompletedSetRow({
    required this.itemType,
    required this.detail,
    required this.onTap,
  });

  final TrainingItemType itemType;
  final TrainingSetDetail detail;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final performance = <String>[
      if (itemType == TrainingItemType.strength) ...[
        if (detail.weight != null && detail.reps != null)
          '${_weight(detail.weight!)} kg × ${detail.reps}'
        else ...[
          if (detail.weight != null) '${_weight(detail.weight!)} kg',
          if (detail.reps != null) '${detail.reps} reps',
        ],
      ] else if (detail.durationSeconds != null)
        formatTrainingDuration(detail.durationSeconds!),
      if (detail.rpe != null) 'RPE ${_weight(detail.rpe!)}',
    ];
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.md),
        onTap: onTap,
        child: Container(
          width: double.infinity,
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
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '第 ${detail.setIndex} 组  '
                      '${performance.isEmpty ? '已完成' : performance.join('  ')}',
                      style: const TextStyle(fontWeight: FontWeight.w600),
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
              const Icon(
                Icons.edit_outlined,
                size: 18,
                color: AppColors.textTertiary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SetEditSheet extends ConsumerStatefulWidget {
  const _SetEditSheet({required this.exercise, required this.detail});

  final TrainingExerciseItem exercise;
  final TrainingSetDetail detail;

  @override
  ConsumerState<_SetEditSheet> createState() => _SetEditSheetState();
}

class _SetEditSheetState extends ConsumerState<_SetEditSheet> {
  late final TextEditingController _weightController;
  late final TextEditingController _repsController;
  late final TextEditingController _durationMinutesController;
  late final TextEditingController _durationSecondsController;
  late final TextEditingController _rpeController;
  late final TextEditingController _remarkController;
  bool _submitting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final detail = widget.detail;
    _weightController = TextEditingController(
      text: detail.weight == null ? '' : _weight(detail.weight!),
    );
    _repsController = TextEditingController(
      text: detail.reps?.toString() ?? '',
    );
    _durationMinutesController = TextEditingController(
      text: detail.durationSeconds == null
          ? ''
          : '${detail.durationSeconds! ~/ 60}',
    );
    _durationSecondsController = TextEditingController(
      text: detail.durationSeconds == null
          ? ''
          : '${detail.durationSeconds! % 60}',
    );
    _rpeController = TextEditingController(
      text: detail.rpe == null ? '' : _weight(detail.rpe!),
    );
    _remarkController = TextEditingController(text: detail.remark ?? '');
  }

  @override
  void dispose() {
    _weightController.dispose();
    _repsController.dispose();
    _durationMinutesController.dispose();
    _durationSecondsController.dispose();
    _rpeController.dispose();
    _remarkController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    final weightText = _weightController.text.trim();
    final repsText = _repsController.text.trim();
    final rpeText = _rpeController.text.trim();
    final isStrength = widget.exercise.itemType == TrainingItemType.strength;
    final weight = weightText.isEmpty ? null : double.tryParse(weightText);
    final reps = repsText.isEmpty ? null : int.tryParse(repsText);
    final rpe = rpeText.isEmpty ? null : double.tryParse(rpeText);

    if (isStrength &&
        weightText.isNotEmpty &&
        (weight == null || !weight.isFinite || weight < 0 || weight > 10000)) {
      setState(() => _error = '重量请输入 0 到 10000，或留空');
      return;
    }
    if (isStrength &&
        repsText.isNotEmpty &&
        (reps == null || reps < 0 || reps > 9999)) {
      setState(() => _error = '次数请输入 0 到 9999，或留空');
      return;
    }
    final duration = isStrength ? null : _readDuration();
    if (!isStrength && duration == -1) return;
    if (rpeText.isNotEmpty &&
        (rpe == null || !rpe.isFinite || rpe < 1 || rpe > 10)) {
      setState(() => _error = 'RPE 请输入 1 到 10，或留空');
      return;
    }

    setState(() {
      _submitting = true;
      _error = null;
    });
    final remark = _remarkController.text.trim();
    final outcome = await ref
        .read(trainingControllerProvider.notifier)
        .updateSetDetail(
          itemId: widget.exercise.itemId,
          requestId: widget.detail.requestId,
          patch: TrainingSetDetailPatch(
            weight: isStrength
                ? TrainingPatchField<double>.value(weight)
                : const TrainingPatchField<double>.absent(),
            reps: isStrength
                ? TrainingPatchField<int>.value(reps)
                : const TrainingPatchField<int>.absent(),
            durationSeconds: isStrength
                ? const TrainingPatchField<int>.absent()
                : TrainingPatchField<int>.value(duration),
            rpe: TrainingPatchField<double>.value(rpe),
            remark: TrainingPatchField<String>.value(
              remark.isEmpty ? null : remark,
            ),
          ),
        );
    if (!mounted) return;
    if (outcome.isSuccess) {
      Navigator.pop(context, true);
    } else {
      setState(() {
        _submitting = false;
        _error = outcome.errorMessage;
      });
    }
  }

  int? _readDuration() {
    final minutesText = _durationMinutesController.text.trim();
    final secondsText = _durationSecondsController.text.trim();
    if (minutesText.isEmpty && secondsText.isEmpty) return null;
    final minutes = minutesText.isEmpty ? 0 : int.tryParse(minutesText);
    final seconds = secondsText.isEmpty ? 0 : int.tryParse(secondsText);
    if (minutes == null ||
        seconds == null ||
        minutes < 0 ||
        seconds < 0 ||
        seconds > 59) {
      setState(() => _error = '时长请输入有效的分钟和 0 到 59 秒');
      return -1;
    }
    final total = minutes * 60 + seconds;
    if (total < 1 || total > maxTrainingDurationSeconds) {
      setState(() => _error = '时长需为 1 秒到 1440 分钟，或全部清空');
      return -1;
    }
    return total;
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedPadding(
      duration: const Duration(milliseconds: 150),
      padding: EdgeInsets.only(
        bottom: MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '编辑第 ${widget.detail.setIndex} 组 · '
              '${widget.exercise.exerciseName}',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: AppSpacing.xs),
            const Text(
              '清空字段后保存，会删除该项记录值。',
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
            const SizedBox(height: AppSpacing.lg),
            if (widget.exercise.itemType == TrainingItemType.strength)
              Row(
                children: [
                  Expanded(
                    child: _editField(
                      controller: _weightController,
                      label: '重量 kg',
                      decimal: true,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: _editField(
                      controller: _repsController,
                      label: '次数 reps',
                    ),
                  ),
                ],
              )
            else
              Row(
                children: [
                  Expanded(
                    child: _editField(
                      controller: _durationMinutesController,
                      label: '时长（分钟）',
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: _editField(
                      controller: _durationSecondsController,
                      label: '秒',
                    ),
                  ),
                ],
              ),
            const SizedBox(height: AppSpacing.md),
            _editField(
              controller: _rpeController,
              label: 'RPE',
              decimal: true,
            ),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: _remarkController,
              enabled: !_submitting,
              maxLength: 500,
              minLines: 2,
              maxLines: 3,
              decoration: const InputDecoration(labelText: '备注'),
            ),
            if (_error != null) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(_error!, style: const TextStyle(color: AppColors.warning)),
            ],
            const SizedBox(height: AppSpacing.md),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _submitting ? null : _submit,
                child: Text(_submitting ? '保存中…' : '保存修改'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _editField({
    required TextEditingController controller,
    required String label,
    bool decimal = false,
  }) {
    return TextField(
      controller: controller,
      enabled: !_submitting,
      keyboardType: TextInputType.numberWithOptions(decimal: decimal),
      decoration: InputDecoration(labelText: label),
    );
  }
}

class _CheckInSheet extends ConsumerStatefulWidget {
  const _CheckInSheet({required this.exercise});

  final TrainingExerciseItem exercise;

  @override
  ConsumerState<_CheckInSheet> createState() => _CheckInSheetState();
}

class _CheckInSheetState extends ConsumerState<_CheckInSheet> {
  late final TextEditingController _weightController;
  late final TextEditingController _repsController;
  late final TextEditingController _durationMinutesController;
  late final TextEditingController _durationSecondsController;
  final _rpeController = TextEditingController();
  final _remarkController = TextEditingController();
  final _requestId = _newClientId('set');
  bool _submitting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _weightController = TextEditingController(
      text: _weight(widget.exercise.targetWeight),
    );
    _repsController = TextEditingController(
      text: '${widget.exercise.targetReps}',
    );
    final duration = widget.exercise.targetDurationSeconds;
    _durationMinutesController = TextEditingController(
      text: duration == null ? '' : '${duration ~/ 60}',
    );
    _durationSecondsController = TextEditingController(
      text: duration == null ? '' : '${duration % 60}',
    );
  }

  @override
  void dispose() {
    _weightController.dispose();
    _repsController.dispose();
    _durationMinutesController.dispose();
    _durationSecondsController.dispose();
    _rpeController.dispose();
    _remarkController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    final isStrength = widget.exercise.itemType == TrainingItemType.strength;
    final weight = double.tryParse(_weightController.text.trim());
    final reps = int.tryParse(_repsController.text.trim());
    final rpeText = _rpeController.text.trim();
    final rpe = rpeText.isEmpty ? null : double.tryParse(rpeText);
    if (isStrength &&
        (weight == null || !weight.isFinite || weight < 0 || weight > 10000)) {
      setState(() => _error = '请输入 0 到 10000 之间的重量');
      return;
    }
    if (isStrength && (reps == null || reps < 0 || reps > 9999)) {
      setState(() => _error = '请输入 0 到 9999 之间的次数');
      return;
    }
    final duration = isStrength ? null : _readDuration();
    if (!isStrength && duration == -1) return;
    if (rpeText.isNotEmpty &&
        (rpe == null || !rpe.isFinite || rpe < 1 || rpe > 10)) {
      setState(() => _error = 'RPE 请输入 1 到 10 之间的数值');
      return;
    }

    setState(() {
      _submitting = true;
      _error = null;
    });
    final remark = _remarkController.text.trim();
    final outcome = await ref
        .read(trainingControllerProvider.notifier)
        .checkInSet(
          itemId: widget.exercise.itemId,
          input: TrainingSetInput(
            requestId: _requestId,
            weight: isStrength ? weight : null,
            reps: isStrength ? reps : null,
            durationSeconds: duration,
            rpe: rpe,
            remark: remark.isEmpty ? null : remark,
          ),
        );
    if (!mounted) return;
    if (outcome.isSuccess) {
      Navigator.pop(context, true);
    } else {
      setState(() {
        _submitting = false;
        _error = outcome.errorMessage;
      });
    }
  }

  int? _readDuration() {
    final minutesText = _durationMinutesController.text.trim();
    final secondsText = _durationSecondsController.text.trim();
    if (minutesText.isEmpty && secondsText.isEmpty) return null;
    final minutes = minutesText.isEmpty ? 0 : int.tryParse(minutesText);
    final seconds = secondsText.isEmpty ? 0 : int.tryParse(secondsText);
    if (minutes == null ||
        seconds == null ||
        minutes < 0 ||
        seconds < 0 ||
        seconds > 59) {
      setState(() => _error = '时长请输入有效的分钟和 0 到 59 秒');
      return -1;
    }
    final total = minutes * 60 + seconds;
    if (total < 1 || total > maxTrainingDurationSeconds) {
      setState(() => _error = '时长需为 1 秒到 1440 分钟，或全部留空');
      return -1;
    }
    return total;
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedPadding(
      duration: const Duration(milliseconds: 150),
      padding: EdgeInsets.only(
        bottom: MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '完成一组 · ${widget.exercise.exerciseName}',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: AppSpacing.lg),
            if (widget.exercise.itemType == TrainingItemType.strength)
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _weightController,
                      enabled: !_submitting,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(labelText: '重量 kg'),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: TextField(
                      controller: _repsController,
                      enabled: !_submitting,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: '次数 reps',
                      ),
                    ),
                  ),
                ],
              )
            else
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _durationMinutesController,
                      enabled: !_submitting,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: '时长（分钟）',
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: TextField(
                      controller: _durationSecondsController,
                      enabled: !_submitting,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: '秒'),
                    ),
                  ),
                ],
              ),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: _rpeController,
              enabled: !_submitting,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(
                labelText: 'RPE（可选）',
                hintText: '1 - 10',
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: _remarkController,
              enabled: !_submitting,
              maxLength: 500,
              minLines: 2,
              maxLines: 3,
              decoration: const InputDecoration(labelText: '备注（可选）'),
            ),
            if (_error != null) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(_error!, style: const TextStyle(color: AppColors.warning)),
            ],
            const SizedBox(height: AppSpacing.md),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _submitting ? null : _submit,
                child: Text(_submitting ? '保存中…' : '确认完成'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

const _weekdayNames = ['周一', '周二', '周三', '周四', '周五', '周六', '周日'];

String _weight(double value) {
  return value == value.roundToDouble()
      ? value.toInt().toString()
      : value.toStringAsFixed(1);
}

String _newClientId(String prefix) {
  final random = Random.secure().nextInt(0x7fffffff).toRadixString(36);
  final time = DateTime.now().microsecondsSinceEpoch.toRadixString(36);
  return '$prefix-$time-$random';
}

TrainingDay? _findDay(List<TrainingDay> days, int dayIndex) {
  for (final day in days) {
    if (day.dayIndex == dayIndex) return day;
  }
  return null;
}
