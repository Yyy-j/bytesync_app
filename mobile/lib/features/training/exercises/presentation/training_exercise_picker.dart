import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bytesync/l10n/l10n.dart';

import '../../../../core/theme/app_theme.dart';
import '../../domain/training_duration.dart';
import '../../domain/training_exercise_item.dart';
import '../data/fixed_training_exercises.dart';
import '../domain/fixed_training_exercise.dart';
import '../domain/training_custom_exercise.dart';
import '../../videos/presentation/training_exercise_video_controller.dart';
import '../../videos/presentation/training_exercise_video_editor.dart';
import 'training_custom_exercise_controller.dart';

sealed class TrainingExercisePickerResult {
  const TrainingExercisePickerResult();
}

class FixedTrainingExerciseSelection extends TrainingExercisePickerResult {
  const FixedTrainingExerciseSelection(this.exercise);

  final FixedTrainingExercise exercise;
}

class CustomTrainingExerciseSelection extends TrainingExercisePickerResult {
  const CustomTrainingExerciseSelection(this.exercise);

  final TrainingCustomExercise exercise;
}

class ManualTrainingExerciseSelection extends TrainingExercisePickerResult {
  const ManualTrainingExerciseSelection();
}

enum _PickerTab { system, custom }

class TrainingExercisePicker extends ConsumerStatefulWidget {
  const TrainingExercisePicker({super.key});

  @override
  ConsumerState<TrainingExercisePicker> createState() =>
      _TrainingExercisePickerState();
}

class _TrainingExercisePickerState
    extends ConsumerState<TrainingExercisePicker> {
  final _searchController = TextEditingController();
  _PickerTab _tab = _PickerTab.system;
  String? _category;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final customState = ref.watch(trainingCustomExerciseControllerProvider);
    ref.watch(trainingExerciseVideoControllerProvider);
    final customExercises = customState is TrainingCustomExerciseReady
        ? customState.exercises
        : const <TrainingCustomExercise>[];
    final categories = _tab == _PickerTab.system
        ? fixedTrainingExerciseCategories
        : trainingCustomExerciseCategories(customExercises);

    return SafeArea(
      child: Column(
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(
              AppSpacing.pagePadding,
              AppSpacing.md,
              AppSpacing.pagePadding,
              AppSpacing.sm,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    appL10n.trainingPickerTitle,
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                  ),
                ),
                if (_tab == _PickerTab.custom)
                  TextButton.icon(
                    onPressed: _mutationDisabled(customState)
                        ? null
                        : () => _createCustomExercise(context),
                    icon: Icon(Icons.add, size: 18),
                    label: Text(appL10n.trainingAddExercise),
                  ),
                TextButton(
                  onPressed: () =>
                      Navigator.pop(context, ManualTrainingExerciseSelection()),
                  child: Text(appL10n.trainingCustomFill),
                ),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: AppSpacing.pagePadding),
            child: SizedBox(
              width: double.infinity,
              child: SegmentedButton<_PickerTab>(
                segments: [
                  ButtonSegment(
                    value: _PickerTab.system,
                    label: Text(appL10n.trainingSystemExercises),
                  ),
                  ButtonSegment(
                    value: _PickerTab.custom,
                    label: Text(appL10n.trainingMyExercises),
                  ),
                ],
                selected: {_tab},
                onSelectionChanged: (selection) {
                  setState(() {
                    _tab = selection.single;
                    _category = null;
                  });
                },
              ),
            ),
          ),
          SizedBox(height: AppSpacing.sm),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: AppSpacing.pagePadding),
            child: TextField(
              controller: _searchController,
              autofocus: true,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                prefixIcon: Icon(Icons.search),
                hintText: _tab == _PickerTab.system
                    ? appL10n.trainingSearchSystemHint
                    : appL10n.trainingSearchMyHint,
              ),
            ),
          ),
          SizedBox(height: AppSpacing.sm),
          SizedBox(
            height: 42,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.symmetric(horizontal: AppSpacing.pagePadding),
              children: [
                ChoiceChip(
                  label: Text(appL10n.commonAll),
                  selected: _category == null,
                  onSelected: (_) => setState(() => _category = null),
                ),
                const SizedBox(width: AppSpacing.sm),
                ...categories.map(
                  (category) => Padding(
                    padding: const EdgeInsets.only(right: AppSpacing.sm),
                    child: ChoiceChip(
                      label: Text(category),
                      selected: _category == category,
                      onSelected: (_) => setState(() => _category = category),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: AppSpacing.md),
          Expanded(
            child: _tab == _PickerTab.system
                ? _systemExerciseList()
                : _customExerciseList(customState),
          ),
        ],
      ),
    );
  }

  Widget _systemExerciseList() {
    final exercises = filterFixedTrainingExercises(
      query: _searchController.text,
      category: _category,
    );
    if (exercises.isEmpty) return const _EmptyExercises();
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.pagePadding,
        0,
        AppSpacing.pagePadding,
        AppSpacing.xl,
      ),
      itemCount: exercises.length,
      separatorBuilder: (_, _) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final exercise = exercises[index];
        return ListTile(
          contentPadding: EdgeInsets.symmetric(vertical: AppSpacing.xs),
          title: Text(exercise.name),
          subtitle: Text(
            appL10n.trainingSystemExerciseSubtitle(
              exercise.englishName,
              exercise.category,
              trainingTargetText(
                itemType: exercise.itemType,
                targetSets: exercise.defaultSets,
                targetReps: exercise.defaultReps,
                targetWeight: exercise.defaultWeight,
                targetDurationSeconds: exercise.defaultDuration == 0
                    ? null
                    : exercise.defaultDuration,
              ).replaceFirst(appL10n.trainingTargetPrefix, ''),
            ),
          ),
          isThreeLine: true,
          trailing: IconButton(
            tooltip: appL10n.trainingManageVideo,
            onPressed: () => showTrainingVideoEditor(
              context,
              ref,
              exerciseId: exercise.id,
              exerciseName: exercise.name,
            ),
            icon: const Icon(Icons.video_library_outlined, size: 20),
          ),
          onTap: () =>
              Navigator.pop(context, FixedTrainingExerciseSelection(exercise)),
        );
      },
    );
  }

  Widget _customExerciseList(TrainingCustomExerciseState state) {
    return switch (state) {
      TrainingCustomExerciseLoading() => Center(
        child: CircularProgressIndicator(),
      ),
      TrainingCustomExerciseFailure(:final message) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(message, textAlign: TextAlign.center),
            SizedBox(height: AppSpacing.sm),
            OutlinedButton(
              onPressed: () => ref
                  .read(trainingCustomExerciseControllerProvider.notifier)
                  .refresh(),
              child: Text(appL10n.commonRetry),
            ),
          ],
        ),
      ),
      TrainingCustomExerciseReady(:final exercises, :final mutating) =>
        _customReadyList(exercises, mutating),
    };
  }

  Widget _customReadyList(
    List<TrainingCustomExercise> allExercises,
    bool mutating,
  ) {
    final exercises = filterTrainingCustomExercises(
      allExercises,
      query: _searchController.text,
      category: _category,
    );
    if (exercises.isEmpty) {
      return _EmptyExercises(
        message: allExercises.isEmpty
            ? appL10n.trainingMyExercisesEmpty
            : appL10n.trainingNoMatchingExercises,
      );
    }
    return Stack(
      children: [
        ListView.separated(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.pagePadding,
            0,
            AppSpacing.pagePadding,
            AppSpacing.xl,
          ),
          itemCount: exercises.length,
          separatorBuilder: (_, _) => const Divider(height: 1),
          itemBuilder: (context, index) {
            final exercise = exercises[index];
            return ListTile(
              contentPadding: EdgeInsets.symmetric(vertical: AppSpacing.xs),
              title: Text(exercise.name),
              subtitle: Text(
                appL10n.trainingCustomExerciseSubtitle(
                  exercise.category.isEmpty
                      ? appL10n.commonUncategorized
                      : exercise.category,
                  _typeLabel(exercise.itemType),
                  trainingTargetText(
                    itemType: exercise.itemType,
                    targetSets: exercise.defaultSets,
                    targetReps: exercise.defaultReps,
                    targetWeight: exercise.defaultWeight,
                    targetDurationSeconds: exercise.defaultDurationSeconds,
                  ).replaceFirst(appL10n.trainingTargetPrefix, ''),
                ),
              ),
              isThreeLine: true,
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    tooltip: appL10n.trainingManageVideo,
                    onPressed: mutating
                        ? null
                        : () => showTrainingVideoEditor(
                            context,
                            ref,
                            exerciseId: exercise.id,
                            exerciseName: exercise.name,
                          ),
                    icon: Icon(Icons.video_library_outlined, size: 20),
                  ),
                  IconButton(
                    tooltip: appL10n.trainingEditExercise,
                    onPressed: mutating
                        ? null
                        : () => _editCustomExercise(context, exercise),
                    icon: Icon(Icons.edit_outlined, size: 20),
                  ),
                  IconButton(
                    tooltip: appL10n.trainingDeleteExercise,
                    onPressed: mutating
                        ? null
                        : () => _deleteCustomExercise(context, exercise),
                    icon: const Icon(Icons.delete_outline, size: 20),
                  ),
                ],
              ),
              onTap: mutating
                  ? null
                  : () => Navigator.pop(
                      context,
                      CustomTrainingExerciseSelection(exercise),
                    ),
            );
          },
        ),
        if (mutating)
          const Positioned(
            left: 0,
            right: 0,
            top: 0,
            child: LinearProgressIndicator(),
          ),
      ],
    );
  }

  Future<void> _createCustomExercise(BuildContext context) async {
    final input = await showModalBottomSheet<TrainingCustomExerciseInput>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => const _CustomExerciseEditorSheet(),
    );
    if (input == null || !context.mounted) return;
    final result = await ref
        .read(trainingCustomExerciseControllerProvider.notifier)
        .create(input);
    if (!context.mounted) return;
    if (result.isSuccess) {
      setState(() => _category = null);
      _snack(context, appL10n.trainingExerciseAdded);
    } else {
      _snack(context, result.errorMessage!);
    }
  }

  Future<void> _editCustomExercise(
    BuildContext context,
    TrainingCustomExercise exercise,
  ) async {
    final input = await showModalBottomSheet<TrainingCustomExerciseInput>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => _CustomExerciseEditorSheet(initial: exercise),
    );
    if (input == null || !context.mounted) return;
    final result = await ref
        .read(trainingCustomExerciseControllerProvider.notifier)
        .update(exercise.id, input);
    if (!context.mounted) return;
    if (result.isSuccess) {
      setState(() => _category = null);
      _snack(context, appL10n.trainingExerciseUpdated);
    } else {
      _snack(context, result.errorMessage!);
    }
  }

  Future<void> _deleteCustomExercise(
    BuildContext context,
    TrainingCustomExercise exercise,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(appL10n.trainingDeleteExerciseTitle),
        content: Text(appL10n.trainingDeleteExerciseDescription),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(appL10n.commonCancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(appL10n.commonDelete),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    final result = await ref
        .read(trainingCustomExerciseControllerProvider.notifier)
        .delete(exercise.id);
    if (!context.mounted) return;
    if (result.isSuccess) {
      setState(() => _category = null);
      _snack(context, appL10n.trainingExerciseDeleted);
    } else {
      if (result.isNotFound) setState(() => _category = null);
      _snack(context, result.errorMessage!);
    }
  }

  void _snack(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }
}

class _CustomExerciseEditorSheet extends StatefulWidget {
  const _CustomExerciseEditorSheet({this.initial});

  final TrainingCustomExercise? initial;

  @override
  State<_CustomExerciseEditorSheet> createState() =>
      _CustomExerciseEditorSheetState();
}

class _CustomExerciseEditorSheetState
    extends State<_CustomExerciseEditorSheet> {
  late final TextEditingController _nameController;
  late final TextEditingController _categoryController;
  late final TextEditingController _setsController;
  late final TextEditingController _repsController;
  late final TextEditingController _weightController;
  late final TextEditingController _durationMinutesController;
  late final TextEditingController _durationSecondsController;
  late TrainingItemType _itemType;
  String? _error;

  @override
  void initState() {
    super.initState();
    final value = widget.initial;
    _nameController = TextEditingController(text: value?.name ?? '');
    _categoryController = TextEditingController(text: value?.category ?? '');
    _setsController = TextEditingController(text: '${value?.defaultSets ?? 3}');
    _repsController = TextEditingController(
      text: '${value?.defaultReps ?? 10}',
    );
    _weightController = TextEditingController(
      text: _weight(value?.defaultWeight ?? 0),
    );
    final duration = value?.defaultDurationSeconds;
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
      setState(() => _error = appL10n.trainingDefaultSetsInvalid);
      return;
    }
    final isStrength = _itemType == TrainingItemType.strength;
    if (isStrength && (reps == null || reps < 0 || reps > 999)) {
      setState(() => _error = appL10n.trainingDefaultRepsInvalid);
      return;
    }
    if (isStrength &&
        (weight == null || !weight.isFinite || weight < 0 || weight > 10000)) {
      setState(() => _error = appL10n.trainingDefaultWeightInvalid);
      return;
    }
    final duration = isStrength ? null : _readDuration();
    if (!isStrength && duration == -1) return;
    Navigator.pop(
      context,
      TrainingCustomExerciseInput(
        name: name,
        category: category,
        itemType: _itemType,
        defaultSets: sets,
        defaultReps: reps ?? widget.initial?.defaultReps ?? 0,
        defaultWeight: weight ?? widget.initial?.defaultWeight ?? 0,
        defaultDurationSeconds: duration,
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
      setState(() => _error = appL10n.trainingDefaultDurationInvalid);
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
                  ? appL10n.trainingAddMyExercise
                  : appL10n.trainingEditMyExercise,
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
            ),
            SizedBox(height: AppSpacing.lg),
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
            SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Expanded(
                  child: _numberField(
                    appL10n.trainingDefaultSets,
                    _setsController,
                  ),
                ),
                if (_itemType == TrainingItemType.strength) ...[
                  SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: _numberField(
                      appL10n.trainingDefaultReps,
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
                  labelText: appL10n.trainingDefaultWeightKg,
                ),
              )
            else
              Row(
                children: [
                  Expanded(
                    child: _numberField(
                      appL10n.trainingDefaultDurationMinutes,
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

class _EmptyExercises extends StatelessWidget {
  const _EmptyExercises({this.message});

  final String? message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Text(
        message ?? appL10n.trainingNoMatchingExercises,
        style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
      ),
    );
  }
}

bool _mutationDisabled(TrainingCustomExerciseState state) {
  return state is! TrainingCustomExerciseReady || state.mutating;
}

String _typeLabel(TrainingItemType type) => switch (type) {
  TrainingItemType.strength => appL10n.trainingTypeStrength,
  TrainingItemType.duration => appL10n.trainingTypeDuration,
  TrainingItemType.cardio => appL10n.trainingTypeCardio,
};

String _weight(double value) {
  return value == value.roundToDouble()
      ? value.toInt().toString()
      : value.toStringAsFixed(1);
}
