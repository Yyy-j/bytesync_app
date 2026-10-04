import 'package:flutter/material.dart';
import 'package:bytesync/l10n/l10n.dart';
import 'package:intl/intl.dart';

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
  Widget build(BuildContext context) {
    final recommendation = widget.recommendation;
    return Padding(
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
            Text(appL10n.onboardingRecommendedCalories),
            Text(
              appL10n.recommendationCaloriesPerDay(
                recommendation.calories.round().toString(),
              ),
              style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w700),
            ),
            Text(
              appL10n.recommendationMacros(
                recommendation.protein.round().toString(),
                recommendation.carbs.round().toString(),
                recommendation.fat.round().toString(),
              ),
            ),
            if (recommendation.aggressiveTimeline)
              AppCard(
                child: Text(
                  appL10n.recommendationAggressiveMessage(
                    recommendation.recommendedTargetDate == null
                        ? '-'
                        : _date(recommendation.recommendedTargetDate!),
                  ),
                ),
              ),
            ExpansionTile(
              title: Text(appL10n.recommendationWhy),
              children: [
                ListTile(
                  title: Text(appL10n.onboardingBmr),
                  trailing: Text(
                    appL10n.recommendationBmrValue(
                      recommendation.bmr?.round().toString() ?? '-',
                    ),
                  ),
                ),
                ListTile(
                  title: Text(appL10n.onboardingMaintenance),
                  trailing: Text(
                    appL10n.recommendationMaintenanceValue(
                      recommendation.maintenanceCalories?.round().toString() ??
                          '-',
                    ),
                  ),
                ),
                ListTile(
                  title: Text(appL10n.onboardingMethod),
                  trailing: Text(recommendation.method ?? '-'),
                ),
              ],
            ),
            TextButton(
              onPressed: () => setState(() => _editing = !_editing),
              child: Text(
                _editing
                    ? appL10n.recommendationCollapseAdjust
                    : appL10n.recommendationAdjust,
              ),
            ),
            if (_editing) ...[
              _field(appL10n.onboardingRecommendedCalories, _calories, 'kcal'),
              _field(appL10n.commonProtein, _protein, 'g'),
              _field(appL10n.macroCarbs, _carbs, 'g'),
              _field(appL10n.commonFat, _fat, 'g'),
            ],
            SizedBox(height: AppSpacing.sm),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _apply,
                child: Text(appL10n.recommendationApply),
              ),
            ),
          ],
        ),
      ),
    );
  }

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

  String _date(DateTime date) =>
      DateFormat(appL10n.commonDateFormat, 'zh_CN').format(date);
}
