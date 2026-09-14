import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../data/fixed_training_exercises.dart';
import '../domain/fixed_training_exercise.dart';

sealed class TrainingExercisePickerResult {
  const TrainingExercisePickerResult();
}

class FixedTrainingExerciseSelection extends TrainingExercisePickerResult {
  const FixedTrainingExerciseSelection(this.exercise);

  final FixedTrainingExercise exercise;
}

class ManualTrainingExerciseSelection extends TrainingExercisePickerResult {
  const ManualTrainingExerciseSelection();
}

class TrainingExercisePicker extends StatefulWidget {
  const TrainingExercisePicker({super.key});

  @override
  State<TrainingExercisePicker> createState() =>
      _TrainingExercisePickerState();
}

class _TrainingExercisePickerState extends State<TrainingExercisePicker> {
  final _searchController = TextEditingController();
  String? _category;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final exercises = filterFixedTrainingExercises(
      query: _searchController.text,
      category: _category,
    );
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
            child: TextField(
              controller: _searchController,
              autofocus: true,
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                hintText: '搜索中文或英文名称',
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
                ...fixedTrainingExerciseCategories.map(
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
            child: exercises.isEmpty
                ? const Center(
                    child: Text(
                      '没有匹配的动作',
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                  )
                : ListView.separated(
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
                  ),
          ),
        ],
      ),
    );
  }
}

String _weight(double value) {
  return value == value.roundToDouble()
      ? value.toInt().toString()
      : value.toStringAsFixed(1);
}
