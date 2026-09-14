import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../domain/training_exercise_item.dart';
import '../data/fixed_training_exercises.dart';
import '../domain/fixed_training_exercise.dart';
import '../domain/training_custom_exercise.dart';
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
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.pagePadding,
              AppSpacing.md,
              AppSpacing.pagePadding,
              AppSpacing.sm,
            ),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    '选择训练动作',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                if (_tab == _PickerTab.custom)
                  TextButton.icon(
                    onPressed: _mutationDisabled(customState)
                        ? null
                        : () => _createCustomExercise(context),
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('新增动作'),
                  ),
                TextButton(
                  onPressed: () => Navigator.pop(
                    context,
                    const ManualTrainingExerciseSelection(),
                  ),
                  child: const Text('自定义填写'),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.pagePadding,
            ),
            child: SizedBox(
              width: double.infinity,
              child: SegmentedButton<_PickerTab>(
                segments: const [
                  ButtonSegment(
                    value: _PickerTab.system,
                    label: Text('系统动作'),
                  ),
                  ButtonSegment(
                    value: _PickerTab.custom,
                    label: Text('我的动作'),
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
          const SizedBox(height: AppSpacing.sm),
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.pagePadding,
            ),
            child: TextField(
              controller: _searchController,
              autofocus: true,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search),
                hintText: _tab == _PickerTab.system
                    ? '搜索中文或英文名称'
                    : '搜索动作名称或分类',
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          SizedBox(
            height: 42,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.pagePadding,
              ),
              children: [
                ChoiceChip(
                  label: const Text('全部'),
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
          contentPadding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
          title: Text(exercise.name),
          subtitle: Text(
            '${exercise.englishName} · ${exercise.category}\n'
            '${exercise.defaultSets} × ${exercise.defaultReps}  '
            '${_weight(exercise.defaultWeight)} kg',
          ),
          isThreeLine: true,
          onTap: () => Navigator.pop(
            context,
            FixedTrainingExerciseSelection(exercise),
          ),
        );
      },
    );
  }

  Widget _customExerciseList(TrainingCustomExerciseState state) {
    return switch (state) {
      TrainingCustomExerciseLoading() => const Center(
        child: CircularProgressIndicator(),
      ),
      TrainingCustomExerciseFailure(:final message) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: AppSpacing.sm),
            OutlinedButton(
              onPressed: () => ref
                  .read(trainingCustomExerciseControllerProvider.notifier)
                  .refresh(),
              child: const Text('重试'),
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
        message: allExercises.isEmpty ? '还没有我的动作' : '没有匹配的动作',
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
              contentPadding: const EdgeInsets.symmetric(
                vertical: AppSpacing.xs,
              ),
              title: Text(exercise.name),
              subtitle: Text(
                '${exercise.category.isEmpty ? '未分类' : exercise.category} · '
                '${_typeLabel(exercise.itemType)}\n'
                '${exercise.defaultSets} × ${exercise.defaultReps}  '
                '${_weight(exercise.defaultWeight)} kg',
              ),
              isThreeLine: true,
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    tooltip: '编辑动作',
                    onPressed: mutating
                        ? null
                        : () => _editCustomExercise(context, exercise),
                    icon: const Icon(Icons.edit_outlined, size: 20),
                  ),
                  IconButton(
                    tooltip: '删除动作',
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
      _snack(context, '动作已新增');
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
      _snack(context, '动作已更新');
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
        title: const Text('删除动作？'),
        content: const Text('删除后不会影响已经保存的训练计划和历史记录。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('删除'),
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
      _snack(context, '动作已删除');
    } else {
      if (result.isNotFound) setState(() => _category = null);
      _snack(context, result.errorMessage!);
    }
  }

  void _snack(BuildContext context, String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
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
    _itemType = value?.itemType ?? TrainingItemType.strength;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _categoryController.dispose();
    _setsController.dispose();
    _repsController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  void _submit() {
    final name = _nameController.text.trim();
    final category = _categoryController.text.trim();
    final sets = int.tryParse(_setsController.text.trim());
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
      setState(() => _error = '默认组数请输入 1 到 50');
      return;
    }
    if (reps == null || reps < 0 || reps > 999) {
      setState(() => _error = '默认次数请输入 0 到 999');
      return;
    }
    if (weight == null || !weight.isFinite || weight < 0 || weight > 10000) {
      setState(() => _error = '默认重量请输入 0 到 10000');
      return;
    }
    Navigator.pop(
      context,
      TrainingCustomExerciseInput(
        name: name,
        category: category,
        itemType: _itemType,
        defaultSets: sets,
        defaultReps: reps,
        defaultWeight: weight,
      ),
    );
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
              widget.initial == null ? '新增我的动作' : '编辑我的动作',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: AppSpacing.lg),
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
                      child: Text(type.name),
                    ),
                  )
                  .toList(growable: false),
              onChanged: (value) {
                if (value != null) setState(() => _itemType = value);
              },
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Expanded(child: _numberField('默认组数', _setsController)),
                const SizedBox(width: AppSpacing.md),
                Expanded(child: _numberField('默认次数', _repsController)),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: _weightController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(labelText: '默认重量 kg'),
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

class _EmptyExercises extends StatelessWidget {
  const _EmptyExercises({this.message = '没有匹配的动作'});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        message,
        style: const TextStyle(color: AppColors.textSecondary),
      ),
    );
  }
}

bool _mutationDisabled(TrainingCustomExerciseState state) {
  return state is! TrainingCustomExerciseReady || state.mutating;
}

String _typeLabel(TrainingItemType type) => switch (type) {
  TrainingItemType.strength => 'strength',
  TrainingItemType.duration => 'duration',
  TrainingItemType.cardio => 'cardio',
};

String _weight(double value) {
  return value == value.roundToDouble()
      ? value.toInt().toString()
      : value.toStringAsFixed(1);
}
