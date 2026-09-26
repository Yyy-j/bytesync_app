import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/state_views.dart';
import '../../auth/presentation/auth_controller.dart';
import '../../auth/domain/auth_state.dart';
import '../../profile/domain/user_profile.dart';
import '../data/body_providers.dart';
import '../domain/body_data.dart';

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
    appBar: AppBar(title: const Text('开始使用 BiteSync')),
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

  Widget _basicStep() => _section('先了解一下你', [
    const Text('这些信息仅用于基础代谢估算。'),
    _number('出生年份', _birthYear, hint: '例如 1998'),
    _choice('用于热量估算的生理参数', _sex, {
      '男性': 'male',
      '女性': 'female',
    }, (value) => setState(() => _sex = value)),
    _number('身高', _height, suffix: 'cm'),
    _number('当前体重', _currentWeight, suffix: 'kg'),
    _nextButton('下一步', _validateBasic),
  ]);

  Widget _goalStep() => _section('你的目标', [
    _number('目标体重', _targetWeight, suffix: 'kg'),
    ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(
        _targetDate == null ? '希望实现目标的日期' : '目标日期：${_date(_targetDate!)}',
      ),
      trailing: const Icon(Icons.calendar_today_outlined),
      onTap: _pickDate,
    ),
    _choice('活动量', _activity, const {
      '久坐为主': 'sedentary',
      '轻度活动': 'light',
      '中等活动': 'moderate',
      '高活动量': 'high',
      '非常高的活动量': 'very_high',
    }, (value) => setState(() => _activity = value)),
    _nextButton('查看推荐', _loadRecommendation),
    TextButton(onPressed: _manualGoals, child: const Text('手动填写目标')),
  ]);

  Widget _recommendationStep() {
    final recommendation = _recommendation;
    if (recommendation == null) return const LoadingView();
    return _section('推荐结果', [
      AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('推荐每日热量'),
            Text(
              '${recommendation.calories.round()} kcal',
              style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w700),
            ),
            Text(
              '蛋白质 ${recommendation.protein.round()}g · 碳水 ${recommendation.carbs.round()}g · 脂肪 ${recommendation.fat.round()}g',
            ),
          ],
        ),
      ),
      if (recommendation.aggressiveTimeline)
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('这个目标速度有些快'),
              Text(
                '按照更稳妥的节奏，建议把目标日期调整到 ${recommendation.recommendedTargetDate == null ? '稍后' : _date(recommendation.recommendedTargetDate!)}。',
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
                child: const Text('采用建议日期'),
              ),
            ],
          ),
        ),
      TextButton(onPressed: _editGoals, child: const Text('调整目标')),
      _nextButton('确认目标', () => setState(() => _step = 3)),
    ]);
  }

  Widget _confirmStep() => _section('准备好了', [
    Text('当前体重：${_currentWeight.text} kg'),
    Text('目标体重：${_targetWeight.text} kg'),
    Text('目标日期：${_targetDate == null ? '-' : _date(_targetDate!)}'),
    Text(
      '每日目标：${_calories.text} kcal · P ${_protein.text}g · C ${_carbs.text}g · F ${_fat.text}g',
    ),
    _nextButton(_busy ? '提交中…' : '开始使用 BiteSync', _submit),
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
      setState(() => _error = '请填写合理的身体资料');
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
      setState(() => _error = '请补充目标体重、日期和活动量');
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
      setState(() => _error = '未满 18 岁或年龄无法确认，请手动填写营养目标');
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
        () => _error = error is ApiException ? error.message : '暂时无法获取推荐，请重试',
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
          _number('热量', _calories, suffix: 'kcal'),
          _number('蛋白质', _protein, suffix: 'g'),
          _number('碳水', _carbs, suffix: 'g'),
          _number('脂肪', _fat, suffix: 'g'),
          FilledButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('完成'),
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
      setState(() => _error = '请填写有效的营养目标');
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
      if (ref.read(authControllerProvider) is AuthAuthenticated) {
        if (mounted) context.go('/');
      } else {
        setState(() => _error = '提交状态发生变化，请重试');
      }
    } catch (error) {
      setState(
        () => _error = error is ApiException ? error.message : '提交失败，请重试',
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  String _date(DateTime date) => '${date.month}月${date.day}日';
}
