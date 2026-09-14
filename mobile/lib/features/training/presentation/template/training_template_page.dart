import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/state_views.dart';
import '../../domain/training_duration.dart';
import '../../domain/training_exercise_item.dart';
import '../../exercises/presentation/training_exercise_picker.dart';
import '../training_controller.dart';
import 'training_template_controller.dart';

class TrainingTemplatePage extends ConsumerWidget {
  const TrainingTemplatePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(trainingTemplateControllerProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('编辑训练计划')),
      body: SafeArea(
        child: switch (state) {
          TrainingTemplateLoading() => const LoadingView(),
          TrainingTemplateFailure(:final message) => ErrorView(
            message: message,
            onRetry: () => ref
                .read(trainingTemplateControllerProvider.notifier)
                .refresh(),
          ),
          TrainingTemplateReady() => _TemplateBody(state: state),
        },
      ),
    );
  }
}

class _TemplateBody extends ConsumerWidget {
  const _TemplateBody({required this.state});

  final TrainingTemplateReady state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.pagePadding),
      children: [
        const Text(
          '设置每周固定训练。保存模板后，可由你决定是否同步到本周。',
          style: TextStyle(color: AppColors.textSecondary),
        ),
        const SizedBox(height: AppSpacing.lg),
        ...state.days.map(
          (day) => Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.md),
            child: AppCard(
              padding: EdgeInsets.zero,
              child: ExpansionTile(
                initiallyExpanded: day.exercises.isNotEmpty || day.dayIndex == 0,
                shape: const Border(),
                collapsedShape: const Border(),
                title: Text(
                  _weekdayNames[day.dayIndex],
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                subtitle: Text(
                  day.exercises.isEmpty
                      ? '休息日'
                      : '${day.exercises.length} 个动作',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
                childrenPadding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  0,
                  AppSpacing.lg,
                  AppSpacing.lg,
                ),
                children: [
                  if (day.exercises.isNotEmpty)
                    ...day.exercises.map(
                      (exercise) => _ExerciseRow(
                        exercise: exercise,
                        enabled: !state.busy,
                        onEdit: () => _openEditor(
                          context,
                          ref,
                          day.dayIndex,
                          exercise,
                        ),
                        onDelete: () => ref
                            .read(trainingTemplateControllerProvider.notifier)
                            .deleteExercise(day.dayIndex, exercise.itemId),
                      ),
                    ),
                  const SizedBox(height: AppSpacing.sm),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: state.busy
                          ? null
                          : () => _openNewExercise(
                              context,
                              ref,
                              day.dayIndex,
                              day.exercises.length,
                            ),
                      icon: const Icon(Icons.add),
                      label: const Text('新增动作'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: state.busy ? null : () => _save(context, ref),
            child: Text(state.saving ? '保存中…' : '保存训练计划'),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: state.busy || !state.canSync
                ? null
                : () => _sync(context, ref),
            child: Text(
              state.syncing
                  ? '同步中…'
                  : !state.canSync
                  ? '请先保存再同步'
                  : '同步到本周',
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
      ],
    );
  }

  Future<void> _openNewExercise(
    BuildContext context,
    WidgetRef ref,
    int dayIndex,
    int order,
  ) async {
    final selection = await showModalBottomSheet<TrainingExercisePickerResult>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (sheetContext) => SizedBox(
        height: MediaQuery.sizeOf(sheetContext).height * 0.88,
        child: const TrainingExercisePicker(),
      ),
    );
    if (selection == null || !context.mounted) return;

    final controller = ref.read(trainingTemplateControllerProvider.notifier);
    switch (selection) {
      case FixedTrainingExerciseSelection(:final exercise):
        controller.addExercise(
          dayIndex,
          exercise.toTemplateItem(
            itemId: controller.newItemId(),
            order: order,
          ),
        );
        break;
      case CustomTrainingExerciseSelection(:final exercise):
        controller.addExercise(
          dayIndex,
          exercise.toTemplateItem(
            itemId: controller.newItemId(),
            order: order,
          ),
        );
        break;
      case ManualTrainingExerciseSelection():
        await _openEditor(context, ref, dayIndex, null);
        break;
    }
  }

  Future<void> _openEditor(
    BuildContext context,
    WidgetRef ref,
    int dayIndex,
    TrainingExerciseItem? exercise,
  ) async {
    final result = await showModalBottomSheet<TrainingExerciseItem>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => _ExerciseEditorSheet(
        initial: exercise,
        newItemId: exercise == null
            ? ref
                  .read(trainingTemplateControllerProvider.notifier)
                  .newItemId()
            : exercise.itemId,
      ),
    );
    if (result == null) return;
    final controller = ref.read(trainingTemplateControllerProvider.notifier);
    if (exercise == null) {
      controller.addExercise(dayIndex, result);
    } else {
      controller.updateExercise(dayIndex, result);
    }
  }

  Future<void> _save(BuildContext context, WidgetRef ref) async {
    final result = await ref
        .read(trainingTemplateControllerProvider.notifier)
        .save();
    if (!context.mounted) return;
    if (!result.isSuccess) {
      _snack(context, result.errorMessage!);
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('训练计划已保存'),
        action: SnackBarAction(
          label: '同步到本周',
          onPressed: () => _sync(context, ref),
        ),
      ),
    );
  }

  Future<void> _sync(BuildContext context, WidgetRef ref) async {
    final result = await ref
        .read(trainingTemplateControllerProvider.notifier)
        .syncCurrentWeek();
    if (!context.mounted) return;
    if (!result.isSuccess) {
      _snack(context, result.errorMessage!);
      return;
    }
    await ref.read(trainingControllerProvider.notifier).refresh();
    if (context.mounted) _snack(context, '已同步到本周');
  }

  void _snack(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}

class _ExerciseRow extends StatelessWidget {
  const _ExerciseRow({
    required this.exercise,
    required this.enabled,
    required this.onEdit,
    required this.onDelete,
  });

  final TrainingExerciseItem exercise;
  final bool enabled;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  exercise.exerciseName,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  '${trainingTargetText(
                    itemType: exercise.itemType,
                    targetSets: exercise.targetSets,
                    targetReps: exercise.targetReps,
                    targetWeight: exercise.targetWeight,
                    targetDurationSeconds: exercise.targetDurationSeconds,
                  ).replaceFirst('目标：', '')}'
                  '${exercise.category.isEmpty ? '' : ' · ${exercise.category}'}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: '编辑动作',
            onPressed: enabled ? onEdit : null,
            icon: const Icon(Icons.edit_outlined, size: 20),
          ),
          IconButton(
            tooltip: '删除动作',
            onPressed: enabled ? onDelete : null,
            icon: const Icon(Icons.delete_outline, size: 20),
          ),
        ],
      ),
    );
  }
}

class _ExerciseEditorSheet extends StatefulWidget {
  const _ExerciseEditorSheet({required this.initial, required this.newItemId});

  final TrainingExerciseItem? initial;
  final String newItemId;

  @override
  State<_ExerciseEditorSheet> createState() => _ExerciseEditorSheetState();
}

class _ExerciseEditorSheetState extends State<_ExerciseEditorSheet> {
  late final TextEditingController _nameController;
  late final TextEditingController _categoryController;
  late final TextEditingController _setsController;
  late final TextEditingController _repsController;
  late final TextEditingController _weightController;
  late final TextEditingController _durationMinutesController;
  late final TextEditingController _durationSecondsController;
  late TrainingItemType _itemType;
  String? _error;

  bool get _isFixed => widget.initial?.exerciseId != null;

  @override
  void initState() {
    super.initState();
    final value = widget.initial;
    _nameController = TextEditingController(text: value?.exerciseName ?? '');
    _categoryController = TextEditingController(text: value?.category ?? '力量');
    _setsController = TextEditingController(text: '${value?.targetSets ?? 3}');
    _repsController = TextEditingController(text: '${value?.targetReps ?? 10}');
    _weightController = TextEditingController(
      text: _weight(value?.targetWeight ?? 0),
    );
    final duration = value?.targetDurationSeconds;
    _durationMinutesController = TextEditingController(
      text: duration == null ? '' : '${duration ~/ 60}',
    );
    _durationSecondsController = TextEditingController(
      text: duration == null ? '' : '${duration % 60}',
    );
    _itemType = value?.itemType ?? TrainingItemType.strength;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _categoryController.dispose();
    _setsController.dispose();
    _repsController.dispose();
    _weightController.dispose();
    _durationMinutesController.dispose();
    _durationSecondsController.dispose();
    super.dispose();
  }

  void _submit() {
    final name = _nameController.text.trim();
    final category = _categoryController.text.trim();
    final sets = int.tryParse(_setsController.text.trim());
    final isStrength = _itemType == TrainingItemType.strength;
    final reps = int.tryParse(_repsController.text.trim());
    final weight = double.tryParse(_weightController.text.trim());
    if (name.isEmpty || name.length > 100) {
      setState(() => _error = '动作名称需为 1 到 100 个字符');
      return;
    }
    if (category.length > 50) {
      setState(() => _error = '分类不能超过 50 个字符');
      return;
    }
    if (sets == null || sets < 1 || sets > 50) {
      setState(() => _error = '目标组数请输入 1 到 50');
      return;
    }
    if (isStrength && (reps == null || reps < 0 || reps > 999)) {
      setState(() => _error = '目标次数请输入 0 到 999');
      return;
    }
    if (isStrength &&
        (weight == null || !weight.isFinite || weight < 0 || weight > 10000)) {
      setState(() => _error = '目标重量请输入 0 到 10000');
      return;
    }

    final duration = isStrength ? null : _readDuration();
    if (!isStrength && duration == -1) return;

    final initial = widget.initial;
    Navigator.pop(
      context,
      TrainingExerciseItem(
        itemId: initial?.itemId ?? widget.newItemId,
        exerciseId: initial?.exerciseId,
        exerciseName: name,
        itemType: _itemType,
        category: category,
        targetSets: sets,
        targetReps: reps ?? initial?.targetReps ?? 0,
        targetWeight: weight ?? initial?.targetWeight ?? 0,
        targetDurationSeconds: duration,
        order: initial?.order ?? 0,
      ),
    );
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
      setState(() => _error = '目标时长需为 1 秒到 1440 分钟');
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
              widget.initial == null ? '新增动作' : '编辑动作',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: AppSpacing.lg),
            if (_isFixed) ...[
              Text(
                _nameController.text,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                _categoryController.text,
                style: const TextStyle(color: AppColors.textSecondary),
              ),
            ] else ...[
              TextField(
                controller: _nameController,
                autofocus: widget.initial == null,
                maxLength: 100,
                decoration: const InputDecoration(labelText: '动作名称'),
              ),
              const SizedBox(height: AppSpacing.md),
              TextField(
                controller: _categoryController,
                maxLength: 50,
                decoration: const InputDecoration(labelText: '分类'),
              ),
              const SizedBox(height: AppSpacing.md),
              DropdownButtonFormField<TrainingItemType>(
                initialValue: _itemType,
                decoration: const InputDecoration(labelText: '类型'),
                items: TrainingItemType.values
                    .map(
                      (type) => DropdownMenuItem(
                        value: type,
                        child: Text(_typeLabel(type)),
                      ),
                    )
                    .toList(growable: false),
                onChanged: (value) {
                  if (value != null) setState(() => _itemType = value);
                },
              ),
            ],
            const SizedBox(height: AppSpacing.md),
            if (_isFixed)
              Text(
                '类型：${_typeLabel(_itemType)}',
                style: const TextStyle(color: AppColors.textSecondary),
              ),
            if (_isFixed) const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Expanded(child: _numberField('目标组数', _setsController)),
                if (_itemType == TrainingItemType.strength) ...[
                  const SizedBox(width: AppSpacing.md),
                  Expanded(child: _numberField('目标次数', _repsController)),
                ],
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            if (_itemType == TrainingItemType.strength)
              TextField(
                controller: _weightController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(labelText: '目标重量 kg'),
              )
            else
              Row(
                children: [
                  Expanded(
                    child: _numberField(
                      '目标时长（分钟）',
                      _durationMinutesController,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: _numberField('秒', _durationSecondsController),
                  ),
                ],
              ),
            if (_error != null) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(_error!, style: const TextStyle(color: AppColors.warning)),
            ],
            const SizedBox(height: AppSpacing.lg),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _submit,
                child: const Text('保存动作'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _numberField(String label, TextEditingController controller) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.number,
      decoration: InputDecoration(labelText: label),
    );
  }
}

String _typeLabel(TrainingItemType type) => switch (type) {
  TrainingItemType.strength => '力量',
  TrainingItemType.duration => '时长',
  TrainingItemType.cardio => '有氧',
};

const _weekdayNames = ['周一', '周二', '周三', '周四', '周五', '周六', '周日'];

String _weight(double value) {
  return value == value.roundToDouble()
      ? value.toInt().toString()
      : value.toStringAsFixed(1);
}
