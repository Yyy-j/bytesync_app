import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bytesync/l10n/l10n.dart';

import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/bitesync_snackbar.dart';
import '../../../shared/widgets/state_views.dart';
import '../domain/user_profile.dart';
import 'nutrition_goals_controller.dart';

class NutritionGoalsPage extends ConsumerStatefulWidget {
  const NutritionGoalsPage({super.key});

  @override
  ConsumerState<NutritionGoalsPage> createState() => _NutritionGoalsPageState();
}

class _NutritionGoalsPageState extends ConsumerState<NutritionGoalsPage> {
  final _caloriesController = TextEditingController();
  final _proteinController = TextEditingController();
  final _carbsController = TextEditingController();
  final _fatController = TextEditingController();
  bool _populated = false;
  String? _validationError;

  @override
  void dispose() {
    _caloriesController.dispose();
    _proteinController.dispose();
    _carbsController.dispose();
    _fatController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(nutritionGoalsControllerProvider);
    return Scaffold(
      appBar: AppBar(title: Text(appL10n.profileNutritionGoals)),
      body: SafeArea(
        child: switch (state) {
          NutritionGoalsLoading() => const LoadingView(),
          NutritionGoalsFailure(:final message) => ErrorView(
            message: message,
            onRetry: () =>
                ref.read(nutritionGoalsControllerProvider.notifier).refresh(),
          ),
          NutritionGoalsReady() => _buildForm(state),
        },
      ),
    );
  }

  Widget _buildForm(NutritionGoalsReady state) {
    final theme = Theme.of(context);
    if (!_populated) {
      _setValues(state.profile.goals);
      _populated = true;
    }
    return ListView(
      padding: EdgeInsets.all(AppSpacing.pagePadding),
      children: [
        Text(
          appL10n.goalsDescription,
          style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
        ),
        SizedBox(height: AppSpacing.lg),
        AppCard(
          child: Column(
            children: [
              _field(
                appL10n.goalsDailyCalories,
                appL10n.commonKilocaloriesUnit,
                _caloriesController,
              ),
              _field(
                appL10n.goalsProtein,
                appL10n.commonGramsUnit,
                _proteinController,
              ),
              _field(
                appL10n.goalsCarbs,
                appL10n.commonGramsUnit,
                _carbsController,
              ),
              _field(appL10n.goalsFat, appL10n.commonGramsUnit, _fatController),
              if (_validationError != null) ...[
                SizedBox(height: AppSpacing.xs),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    _validationError!,
                    style: TextStyle(color: theme.colorScheme.error),
                  ),
                ),
              ],
            ],
          ),
        ),
        SizedBox(height: AppSpacing.lg),
        ElevatedButton(
          onPressed: state.saving ? null : _save,
          child: Text(state.saving ? appL10n.commonSaving : appL10n.goalsSave),
        ),
      ],
    );
  }

  Widget _field(String label, String suffix, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: TextField(
        controller: controller,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        decoration: InputDecoration(labelText: label, suffixText: suffix),
      ),
    );
  }

  Future<void> _save() async {
    FocusScope.of(context).unfocus();
    final values = [
      double.tryParse(_caloriesController.text.trim()),
      double.tryParse(_proteinController.text.trim()),
      double.tryParse(_carbsController.text.trim()),
      double.tryParse(_fatController.text.trim()),
    ];
    if (values.any((value) => value == null || !value.isFinite || value < 0)) {
      setState(() => _validationError = appL10n.goalsInvalidValue);
      return;
    }
    setState(() => _validationError = null);
    final result = await ref
        .read(nutritionGoalsControllerProvider.notifier)
        .save(
          NutritionGoals(
            calories: values[0]!,
            protein: values[1]!,
            carbs: values[2]!,
            fat: values[3]!,
          ),
        );
    if (!mounted) return;
    BiteSyncSnackBar.show(
      context,
      message: result.isSuccess ? appL10n.goalsSaved : result.errorMessage!,
    );
  }

  void _setValues(NutritionGoals goals) {
    _caloriesController.text = _number(goals.calories);
    _proteinController.text = _number(goals.protein);
    _carbsController.text = _number(goals.carbs);
    _fatController.text = _number(goals.fat);
  }

  String _number(double value) {
    return value == value.roundToDouble()
        ? value.toInt().toString()
        : value.toString();
  }
}
