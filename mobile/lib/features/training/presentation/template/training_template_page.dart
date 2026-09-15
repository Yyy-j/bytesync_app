import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bytesync/l10n/l10n.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/state_views.dart';
import '../../domain/training_duration.dart';
import '../../domain/training_exercise_item.dart';
import '../../exercises/presentation/training_exercise_picker.dart';
import '../../videos/presentation/training_exercise_video_controller.dart';
import '../../videos/presentation/training_exercise_video_editor.dart';
import '../training_controller.dart';
import 'training_template_controller.dart';

class TrainingTemplatePage extends ConsumerWidget {
  const TrainingTemplatePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(trainingTemplateControllerProvider);
    return Scaffold(
      appBar: AppBar(title: Text(appL10n.trainingEditPlan)),
      body: SafeArea(
        child: switch (state) {
          TrainingTemplateLoading() => const LoadingView(),
          TrainingTemplateFailure(:final message) => ErrorView(
            message: message,
            onRetry: () =>
                ref.read(trainingTemplateControllerProvider.notifier).refresh(),
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
    final theme = Theme.of(context);
    ref.watch(trainingExerciseVideoControllerProvider);
    return ListView(
      padding: EdgeInsets.all(AppSpacing.pagePadding),
      children: [
        Text(
          appL10n.trainingTemplateDescription,
          style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
        ),
        SizedBox(height: AppSpacing.lg),
        ...state.days.map(
          (day) => Padding(
            padding: EdgeInsets.only(bottom: AppSpacing.md),
            child: AppCard(
              padding: EdgeInsets.zero,
              child: ExpansionTile(
                initiallyExpanded:
                    day.exercises.isNotEmpty || day.dayIndex == 0,
                shape: Border(),
                collapsedShape: Border(),
                title: Text(
                  _weekdayNames[day.dayIndex],
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                subtitle: Text(
                  day.exercises.isEmpty
                      ? appL10n.trainingRestDay
                      : appL10n.trainingExerciseCount(day.exercises.length),
                  style: TextStyle(
                    fontSize: 12,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                childrenPadding: EdgeInsets.fromLTRB(
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
                        onVideo: exercise.exerciseId == null
                            ? null
                            : () => showTrainingVideoEditor(
                                context,
                                ref,
                                exerciseId: exercise.exerciseId!,
                                exerciseName: exercise.exerciseName,
                              ),
                        onEdit: () =>
                            _openEditor(context, ref, day.dayIndex, exercise),
                        onDelete: () => ref
                            .read(trainingTemplateControllerProvider.notifier)
                            .deleteExercise(day.dayIndex, exercise.itemId),
                      ),
                    ),
                  SizedBox(height: AppSpacing.sm),
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
                      icon: Icon(Icons.add),
                      label: Text(appL10n.trainingAddExercise),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        SizedBox(height: AppSpacing.sm),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: state.busy ? null : () => _save(context, ref),
            child: Text(
              state.saving ? appL10n.commonSaving : appL10n.trainingSavePlan,
            ),
          ),
        ),
        SizedBox(height: AppSpacing.sm),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: state.busy || !state.canSync
                ? null
                : () => _sync(context, ref),
            child: Text(
              state.syncing
                  ? appL10n.trainingSyncing
                  : !state.canSync
                  ? appL10n.trainingSaveBeforeSync
                  : appL10n.trainingSyncWeek,
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
          exercise.toTemplateItem(itemId: controller.newItemId(), order: order),
        );
        break;
      case CustomTrainingExerciseSelection(:final exercise):
        controller.addExercise(
          dayIndex,
          exercise.toTemplateItem(itemId: controller.newItemId(), order: order),
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
            ? ref.read(trainingTemplateControllerProvider.notifier).newItemId()
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
        content: Text(appL10n.trainingPlanSaved),
        action: SnackBarAction(
          label: appL10n.trainingSyncWeek,
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
    if (context.mounted) _snack(context, appL10n.trainingSyncedWeek);
  }

  void _snack(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }
}

class _ExerciseRow extends StatelessWidget {
  const _ExerciseRow({
    required this.exercise,
    required this.enabled,
    required this.onVideo,
    required this.onEdit,
    required this.onDelete,
  });

  final TrainingExerciseItem exercise;
  final bool enabled;
  final VoidCallback? onVideo;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: EdgeInsets.symmetric(vertical: AppSpacing.sm),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: theme.dividerColor)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  exercise.exerciseName,
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                SizedBox(height: AppSpacing.xs),
                Text(
                  exercise.category.isEmpty
                      ? trainingTargetText(
                          itemType: exercise.itemType,
                          targetSets: exercise.targetSets,
                          targetReps: exercise.targetReps,
                          targetWeight: exercise.targetWeight,
                          targetDurationSeconds: exercise.targetDurationSeconds,
                        ).replaceFirst(appL10n.trainingTargetPrefix, '')
                      : appL10n.trainingExerciseTargetWithCategory(
                          trainingTargetText(
                            itemType: exercise.itemType,
                            targetSets: exercise.targetSets,
                            targetReps: exercise.targetReps,
                            targetWeight: exercise.targetWeight,
                            targetDurationSeconds:
                                exercise.targetDurationSeconds,
                          ).replaceFirst(appL10n.trainingTargetPrefix, ''),
                          exercise.category,
                        ),
                  style: TextStyle(
                    fontSize: 12,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          if (onVideo != null)
            IconButton(
              tooltip: appL10n.trainingManageVideo,
              onPressed: enabled ? onVideo : null,
              icon: Icon(Icons.video_library_outlined, size: 20),
            ),
          IconButton(
            tooltip: appL10n.trainingEditExercise,
            onPressed: enabled ? onEdit : null,
            icon: Icon(Icons.edit_outlined, size: 20),
          ),
          IconButton(
            tooltip: appL10n.trainingDeleteExercise,
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
    _categoryController = TextEditingController(
      text: value?.category ?? appL10n.trainingTypeStrength,
    );
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
      setState(() => _error = appL10n.trainingExerciseNameInvalid);
      return;
    }
    if (category.length > 50) {
      setState(() => _error = appL10n.trainingCategoryTooLong);
      return;
    }
    if (sets == null || sets < 1 || sets > 50) {
      setState(() => _error = appL10n.trainingTargetSetsInvalid);
      return;
    }
    if (isStrength && (reps == null || reps < 0 || reps > 999)) {
      setState(() => _error = appL10n.trainingTargetRepsInvalid);
      return;
    }
    if (isStrength &&
        (weight == null || !weight.isFinite || weight < 0 || weight > 10000)) {
      setState(() => _error = appL10n.trainingTargetWeightInvalid);
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
      setState(() => _error = appL10n.trainingInvalidDurationParts);
      return -1;
    }
    final total = minutes * 60 + seconds;
    if (total < 1 || total > maxTrainingDurationSeconds) {
      setState(() => _error = appL10n.trainingTargetDurationInvalid);
      return -1;
    }
    return total;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AnimatedPadding(
      duration: Duration(milliseconds: 150),
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SingleChildScrollView(
        padding: EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.initial == null
                  ? appL10n.trainingAddExercise
                  : appL10n.trainingEditExercise,
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
            ),
            SizedBox(height: AppSpacing.lg),
            if (_isFixed) ...[
              Text(
                _nameController.text,
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
              ),
              SizedBox(height: AppSpacing.xs),
              Text(
                _categoryController.text,
                style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
              ),
            ] else ...[
              TextField(
                controller: _nameController,
                autofocus: widget.initial == null,
                maxLength: 100,
                decoration: InputDecoration(
                  labelText: appL10n.trainingExerciseName,
                ),
              ),
              SizedBox(height: AppSpacing.md),
              TextField(
                controller: _categoryController,
                maxLength: 50,
                decoration: InputDecoration(
                  labelText: appL10n.trainingExerciseCategory,
                ),
              ),
              SizedBox(height: AppSpacing.md),
              DropdownButtonFormField<TrainingItemType>(
                initialValue: _itemType,
                decoration: InputDecoration(
                  labelText: appL10n.trainingExerciseType,
                ),
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
            SizedBox(height: AppSpacing.md),
            if (_isFixed)
              Text(
                appL10n.trainingExerciseTypeValue(_typeLabel(_itemType)),
                style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
              ),
            if (_isFixed) SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Expanded(
                  child: _numberField(
                    appL10n.trainingTargetSets,
                    _setsController,
                  ),
                ),
                if (_itemType == TrainingItemType.strength) ...[
                  SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: _numberField(
                      appL10n.trainingTargetReps,
                      _repsController,
                    ),
                  ),
                ],
              ],
            ),
            SizedBox(height: AppSpacing.md),
            if (_itemType == TrainingItemType.strength)
              TextField(
                controller: _weightController,
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: appL10n.trainingTargetWeightKg,
                ),
              )
            else
              Row(
                children: [
                  Expanded(
                    child: _numberField(
                      appL10n.trainingTargetDurationMinutes,
                      _durationMinutesController,
                    ),
                  ),
                  SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: _numberField(
                      appL10n.commonSeconds,
                      _durationSecondsController,
                    ),
                  ),
                ],
              ),
            if (_error != null) ...[
              SizedBox(height: AppSpacing.sm),
              Text(_error!, style: TextStyle(color: theme.colorScheme.error)),
            ],
            SizedBox(height: AppSpacing.lg),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _submit,
                child: Text(appL10n.trainingSaveExercise),
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
  TrainingItemType.strength => appL10n.trainingTypeStrength,
  TrainingItemType.duration => appL10n.trainingTypeDuration,
  TrainingItemType.cardio => appL10n.trainingTypeCardio,
};

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
