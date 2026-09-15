import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

/// A single labelled progress row for one macro nutrient (protein / carbs /
/// fat), mirroring `components/macro-bar` from the mini-program: a label,
/// a track+fill bar, and a "Xg" value.
class MacroBarRow extends StatelessWidget {
  const MacroBarRow({
    required this.label,
    required this.grams,
    required this.goalGrams,
    required this.fillColor,
    required this.trackColor,
    this.textColor,
    super.key,
  });

  final String label;
  final num grams;
  final num goalGrams;
  final Color fillColor;
  final Color trackColor;
  final Color? textColor;

  double get _progress {
    if (goalGrams <= 0) return 0;
    final ratio = grams / goalGrams;
    return ratio.clamp(0, 1).toDouble();
  }

  @override
  Widget build(BuildContext context) {
    final secondaryText =
        textColor ?? Theme.of(context).colorScheme.onSurfaceVariant;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        children: [
          SizedBox(
            width: 44,
            child: Text(
              label,
              style: TextStyle(fontSize: 12, color: secondaryText),
            ),
          ),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.full),
              child: LinearProgressIndicator(
                value: _progress,
                minHeight: 8,
                backgroundColor: trackColor,
                valueColor: AlwaysStoppedAnimation<Color>(fillColor),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          SizedBox(
            width: 44,
            child: Text(
              '${grams.round()}g',
              textAlign: TextAlign.end,
              style: TextStyle(fontSize: 12, color: secondaryText),
            ),
          ),
        ],
      ),
    );
  }
}

/// Stacks the three macro rows (protein / carbs / fat), matching the
/// `macro-bar` component's fixed nutrient order.
class MacroBar extends StatelessWidget {
  const MacroBar({
    required this.protein,
    required this.proteinGoal,
    required this.carbs,
    required this.carbsGoal,
    required this.fat,
    required this.fatGoal,
    this.proteinFillColor = AppColors.protein,
    this.carbsFillColor = AppColors.carbs,
    this.fatFillColor = AppColors.fat,
    this.proteinTrackColor = AppColors.proteinBg,
    this.carbsTrackColor = AppColors.carbsBg,
    this.fatTrackColor = AppColors.fatBg,
    this.textColor,
    super.key,
  });

  final num protein;
  final num proteinGoal;
  final num carbs;
  final num carbsGoal;
  final num fat;
  final num fatGoal;
  final Color proteinFillColor;
  final Color carbsFillColor;
  final Color fatFillColor;
  final Color proteinTrackColor;
  final Color carbsTrackColor;
  final Color fatTrackColor;
  final Color? textColor;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        MacroBarRow(
          label: '蛋白质',
          grams: protein,
          goalGrams: proteinGoal,
          fillColor: proteinFillColor,
          trackColor: proteinTrackColor,
          textColor: textColor,
        ),
        MacroBarRow(
          label: '碳水',
          grams: carbs,
          goalGrams: carbsGoal,
          fillColor: carbsFillColor,
          trackColor: carbsTrackColor,
          textColor: textColor,
        ),
        MacroBarRow(
          label: '脂肪',
          grams: fat,
          goalGrams: fatGoal,
          fillColor: fatFillColor,
          trackColor: fatTrackColor,
          textColor: textColor,
        ),
      ],
    );
  }
}
