import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:bytesync/l10n/l10n.dart';
import 'package:intl/intl.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/state_views.dart';
import '../../auth/presentation/auth_controller.dart';
import '../../auth/domain/auth_state.dart';
import '../../profile/domain/user_profile.dart';
import '../data/body_providers.dart';
import '../domain/body_data.dart';
import '../domain/body_validation.dart';

class OnboardingPage extends ConsumerStatefulWidget {
  const OnboardingPage({super.key});
  @override
  ConsumerState<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends ConsumerState<OnboardingPage> {
  final _birthYear = TextEditingController();
  final _height = TextEditingController();
  final _currentWeight = TextEditingController();
  final _targetWeight = TextEditingController();
  final _calories = TextEditingController();
  final _protein = TextEditingController();
  final _carbs = TextEditingController();
  final _fat = TextEditingController();
  int _step = 0;
  String? _sex;
  String? _activity;
  DateTime? _targetDate;
  CalorieRecommendation? _recommendation;
  String? _error;
  bool _busy = false;

  @override
  void dispose() {
    for (final controller in [
      _birthYear,
      _height,
      _currentWeight,
      _targetWeight,
      _calories,
      _protein,
      _carbs,
      _fat,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(appL10n.onboardingTitle)),
    body: SafeArea(
      child: ListView(
        padding: EdgeInsets.all(AppSpacing.pagePadding),
        children: [
          LinearProgressIndicator(value: (_step + 1) / 4),
          SizedBox(height: AppSpacing.lg),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.md),
              child: Text(
                _error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ),
          if (_step == 0) _basicStep(),
          if (_step == 1) _goalStep(),
          if (_step == 2) _recommendationStep(),
          if (_step == 3) _confirmStep(),
        ],
      ),
    ),
  );

  Widget _basicStep() => _section(appL10n.onboardingBasicTitle, [
    Text(appL10n.onboardingBasicDescription),
    _number(appL10n.onboardingBirthYear, _birthYear, hint: '1998'),
    _choice(appL10n.onboardingSex, _sex, {
      appL10n.onboardingMale: 'male',
      appL10n.onboardingFemale: 'female',
    }, (value) => setState(() => _sex = value)),
    _number(appL10n.onboardingHeight, _height, suffix: 'cm'),
    _number(appL10n.onboardingCurrentWeight, _currentWeight, suffix: 'kg'),
    _nextButton(appL10n.commonContinue, _validateBasic),
  ]);

  Widget _goalStep() => _section(appL10n.onboardingGoalTitle, [
    _number(appL10n.onboardingTargetWeight, _targetWeight, suffix: 'kg'),
    ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(
        _targetDate == null
            ? appL10n.onboardingTargetDatePrompt
            : appL10n.bodyTargetDateValue(_date(_targetDate!)),
      ),
      trailing: const Icon(Icons.calendar_today_outlined),
      onTap: _pickDate,
    ),
    _choice(appL10n.onboardingActivity, _activity, {
      appL10n.onboardingSedentary: 'sedentary',
      appL10n.onboardingLightActivity: 'light',
      appL10n.onboardingModerateActivity: 'moderate',
      appL10n.onboardingHighActivity: 'high',
      appL10n.onboardingVeryHighActivity: 'very_high',
    }, (value) => setState(() => _activity = value)),
    if (_birthYear.text.isEmpty ||
        int.tryParse(_birthYear.text) == null ||
        int.parse(_birthYear.text) > DateTime.now().year - 18)
      Text(appL10n.onboardingUnderageDescription),
    _nextButton(appL10n.onboardingRecommendationTitle, _loadRecommendation),
    TextButton(
      onPressed: _manualGoals,
      child: Text(appL10n.onboardingManualGoals),
    ),
  ]);

  Widget _recommendationStep() {
    final recommendation = _recommendation;
    if (recommendation == null) return const LoadingView();
    return _section(appL10n.onboardingRecommendationTitle, [
      AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(appL10n.onboardingRecommendedCalories),
            Text(
              appL10n.recommendationCaloriesPerDay(
                recommendation.calories.round().toString(),
              ),
              style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w700),
            ),
            Text(
              appL10n.recommendationMacros(
                recommendation.protein.round().toString(),
                recommendation.carbs.round().toString(),
                recommendation.fat.round().toString(),
              ),
            ),
          ],
        ),
      ),
      if (recommendation.aggressiveTimeline)
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(appL10n.onboardingAggressiveTitle),
              Text(
                appL10n.onboardingSuggestedDate(
                  recommendation.recommendedTargetDate == null
                      ? '-'
                      : _date(recommendation.recommendedTargetDate!),
                ),
              ),
              TextButton(
                onPressed: recommendation.recommendedTargetDate == null
                    ? null
                    : () {
                        setState(
                          () => _targetDate =
                              recommendation.recommendedTargetDate,
                        );
                        _loadRecommendation();
                      },
                child: Text(appL10n.onboardingAdoptDate),
              ),
            ],
          ),
        ),
      TextButton(
        onPressed: _editGoals,
        child: Text(appL10n.onboardingEditGoals),
      ),
      _nextButton(
        appL10n.onboardingConfirmGoals,
        () => setState(() => _step = 3),
      ),
    ]);
  }

  Widget _confirmStep() => _section(appL10n.onboardingReadyTitle, [
    Text('${appL10n.onboardingCurrentWeight}：${_currentWeight.text} kg'),
    Text('${appL10n.onboardingTargetWeight}：${_targetWeight.text} kg'),
    Text(
      '${appL10n.onboardingTargetDate}：${_targetDate == null ? '-' : _date(_targetDate!)}',
    ),
    Text(
      '${appL10n.onboardingDailyGoals}：${_calories.text} kcal · P ${_protein.text}g · C ${_carbs.text}g · F ${_fat.text}g',
    ),
    _nextButton(
      _busy ? appL10n.onboardingSubmitting : appL10n.onboardingSubmit,
      _submit,
    ),
  ]);

  Widget _section(String title, List<Widget> children) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(title, style: Theme.of(context).textTheme.headlineSmall),
      SizedBox(height: AppSpacing.md),
      ...children.map(
        (child) => Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.md),
          child: child,
        ),
      ),
    ],
  );
  Widget _number(
    String label,
    TextEditingController controller, {
    String? suffix,
    String? hint,
  }) => TextField(
    controller: controller,
    keyboardType: const TextInputType.numberWithOptions(decimal: true),
    decoration: InputDecoration(
      labelText: label,
      suffixText: suffix,
      hintText: hint,
    ),
  );
  Widget _choice(
    String label,
    String? value,
    Map<String, String> options,
    ValueChanged<String> onChanged,
  ) => DropdownButtonFormField<String>(
    initialValue: value,
    decoration: InputDecoration(labelText: label),
    items: options.entries
        .map(
          (entry) =>
              DropdownMenuItem(value: entry.value, child: Text(entry.key)),
        )
        .toList(),
    onChanged: (next) {
      if (next != null) onChanged(next);
    },
  );
  Widget _nextButton(String label, VoidCallback action) => SizedBox(
    width: double.infinity,
    child: FilledButton(onPressed: _busy ? null : action, child: Text(label)),
  );

  void _validateBasic() {
    final birth = int.tryParse(_birthYear.text);
    final height = double.tryParse(_height.text);
    final weight = double.tryParse(_currentWeight.text);
    if (birth == null ||
        birth < 1900 ||
        birth > DateTime.now().year - 13 ||
        _sex == null ||
        height == null ||
        height < 100 ||
        height > 250 ||
        weight == null ||
        weight < 20 ||
        weight > 400) {
      setState(() => _error = appL10n.onboardingInvalidBasic);
      return;
    }
    setState(() {
      _error = null;
      _step = 1;
    });
  }

  Future<void> _pickDate() async {
    final date = await showDatePicker(
      context: context,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 3650)),
      initialDate: _targetDate ?? DateTime.now().add(const Duration(days: 90)),
    );
    if (date != null) setState(() => _targetDate = date);
  }

  BodyInput? _input() {
    final target = double.tryParse(_targetWeight.text);
    if (target == null ||
        target < 20 ||
        target > 400 ||
        _targetDate == null ||
        _activity == null) {
      setState(() => _error = appL10n.onboardingInvalidGoal);
      return null;
    }
    if (!isValidGoalTimeline(
      currentWeight: double.parse(_currentWeight.text),
      targetWeight: target,
      targetDate: _targetDate!,
    )) {
      setState(() => _error = appL10n.onboardingInvalidGoalTimeline);
      return null;
    }
    return BodyInput(
      birthYear: int.parse(_birthYear.text),
      sexForEnergyEstimate: _sex!,
      heightCm: double.parse(_height.text),
      currentWeightKg: double.parse(_currentWeight.text),
      targetWeightKg: target,
      targetDate: _targetDate!,
      activityLevel: _activity!,
    );
  }

  Future<void> _loadRecommendation() async {
    final birthYear = int.tryParse(_birthYear.text);
    if (birthYear == null || birthYear > DateTime.now().year - 18) {
      setState(() => _error = appL10n.onboardingUnderageDescription);
      return;
    }
    final input = _input();
    if (input == null) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final result = await ref.read(bodyRepositoryProvider).recommend(input);
      setState(() {
        _recommendation = result;
        _calories.text = result.calories.round().toString();
        _protein.text = result.protein.round().toString();
        _carbs.text = result.carbs.round().toString();
        _fat.text = result.fat.round().toString();
        _step = 2;
      });
    } catch (error) {
      setState(
        () => _error = error is ApiException
            ? error.message
            : appL10n.onboardingRecommendationFailed,
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _manualGoals() {
    setState(() {
      _error = null;
      _calories.clear();
      _protein.clear();
      _carbs.clear();
      _fat.clear();
      _step = 3;
    });
  }

  void _editGoals() => showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (context) => Padding(
      padding: EdgeInsets.fromLTRB(
        24,
        24,
        24,
        MediaQuery.viewInsetsOf(context).bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _number(
            appL10n.onboardingRecommendedCalories,
            _calories,
            suffix: 'kcal',
          ),
          _number(appL10n.commonProtein, _protein, suffix: 'g'),
          _number(appL10n.macroCarbs, _carbs, suffix: 'g'),
          _number(appL10n.commonFat, _fat, suffix: 'g'),
          FilledButton(
            onPressed: () => Navigator.pop(context),
            child: Text(appL10n.commonSave),
          ),
        ],
      ),
    ),
  );

  Future<void> _submit() async {
    final input = _input();
    if (input == null) return;
    final goals = NutritionGoals(
      calories: double.tryParse(_calories.text) ?? 0,
      protein: double.tryParse(_protein.text) ?? 0,
      carbs: double.tryParse(_carbs.text) ?? 0,
      fat: double.tryParse(_fat.text) ?? 0,
    );
    if ([
      goals.calories,
      goals.protein,
      goals.carbs,
      goals.fat,
    ].any((value) => value <= 0)) {
      setState(() => _error = appL10n.onboardingInvalidNutrition);
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref.read(bodyRepositoryProvider).completeOnboarding(input, goals);
      await ref.read(authControllerProvider.notifier).refreshCurrentUser();
      if (mounted) context.go('/');
    } on ConflictException {
      await ref.read(authControllerProvider.notifier).refreshCurrentUser();
      final authState = ref.read(authControllerProvider);
      if (authState is AuthAuthenticated &&
          authState.user.onboardingCompleted) {
        if (mounted) context.go('/');
      } else {
        setState(() => _error = appL10n.onboardingConflictRetry);
      }
    } catch (error) {
      setState(
        () => _error = error is ApiException
            ? error.message
            : appL10n.onboardingSubmitFailed,
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  String _date(DateTime date) =>
      DateFormat(appL10n.commonDateFormat, 'zh_CN').format(date);
}
