import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/app_card.dart';
import '../domain/body_data.dart';
import '../../profile/domain/user_profile.dart';

Future<NutritionGoals?> showRecommendationResultSheet(
  BuildContext context,
  CalorieRecommendation recommendation,
) {
  return showModalBottomSheet<NutritionGoals>(
    context: context,
    isScrollControlled: true,
    builder: (context) => _RecommendationSheet(recommendation: recommendation),
  );
}

class _RecommendationSheet extends StatefulWidget {
  const _RecommendationSheet({required this.recommendation});
  final CalorieRecommendation recommendation;
  @override
  State<_RecommendationSheet> createState() => _RecommendationSheetState();
}

class _RecommendationSheetState extends State<_RecommendationSheet> {
  late final _calories = TextEditingController(
    text: _number(widget.recommendation.calories),
  );
  late final _protein = TextEditingController(
    text: _number(widget.recommendation.protein),
  );
  late final _carbs = TextEditingController(
    text: _number(widget.recommendation.carbs),
  );
  late final _fat = TextEditingController(
    text: _number(widget.recommendation.fat),
  );
  bool _editing = false;

  @override
  void dispose() {
    _calories.dispose();
    _protein.dispose();
    _carbs.dispose();
    _fat.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.fromLTRB(
      24,
      24,
      24,
      MediaQuery.viewInsetsOf(context).bottom + 24,
    ),
    child: SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('推荐每日热量'),
          Text(
            '${widget.recommendation.calories.round()} kcal / 天',
            style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w700),
          ),
          Text(
            '蛋白质 ${widget.recommendation.protein.round()}g · 碳水 ${widget.recommendation.carbs.round()}g · 脂肪 ${widget.recommendation.fat.round()}g',
          ),
          if (widget.recommendation.aggressiveTimeline)
            AppCard(
              child: Text(
                '这个目标速度有些快，建议将目标日期调整到 ${widget.recommendation.recommendedTargetDate?.month}月${widget.recommendation.recommendedTargetDate?.day}日。',
              ),
            ),
          ExpansionTile(
            title: const Text('为什么是这个数字？'),
            children: [
              ListTile(
                title: const Text('基础代谢'),
                trailing: Text(
                  '${widget.recommendation.bmr?.round() ?? '-'} kcal',
                ),
              ),
              ListTile(
                title: const Text('维持热量'),
                trailing: Text(
                  '${widget.recommendation.maintenanceCalories?.round() ?? '-'} kcal',
                ),
              ),
              ListTile(
                title: const Text('计算方式'),
                trailing: Text(widget.recommendation.method ?? '-'),
              ),
            ],
          ),
          TextButton(
            onPressed: () => setState(() => _editing = !_editing),
            child: Text(_editing ? '收起调整' : '调整目标'),
          ),
          if (_editing) ...[
            _field('热量', _calories, 'kcal'),
            _field('蛋白质', _protein, 'g'),
            _field('碳水', _carbs, 'g'),
            _field('脂肪', _fat, 'g'),
          ],
          SizedBox(height: AppSpacing.sm),
          SizedBox(
            width: double.infinity,
            child: FilledButton(onPressed: _apply, child: const Text('使用这个目标')),
          ),
        ],
      ),
    ),
  );

  Widget _field(
    String label,
    TextEditingController controller,
    String suffix,
  ) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: TextField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(labelText: label, suffixText: suffix),
    ),
  );

  void _apply() {
    final values = [
      _calories,
      _protein,
      _carbs,
      _fat,
    ].map((controller) => double.tryParse(controller.text)).toList();
    if (values.any((value) => value == null || !value.isFinite || value < 0)) {
      return;
    }
    Navigator.pop(
      context,
      NutritionGoals(
        calories: values[0]!,
        protein: values[1]!,
        carbs: values[2]!,
        fat: values[3]!,
      ),
    );
  }

  String _number(double value) => value == value.roundToDouble()
      ? value.toInt().toString()
      : value.toString();
}
