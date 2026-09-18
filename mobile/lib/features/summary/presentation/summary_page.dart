import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:bytesync/l10n/l10n.dart';

import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/bitesync_bottom_sheet.dart';
import '../../../shared/widgets/macro_bar.dart';
import '../../../shared/widgets/state_views.dart';
import '../../meals/domain/meal.dart';
import '../../meals/domain/meal_source.dart';
import '../../meals/presentation/meal_management_controller.dart';
import '../domain/daily_summary.dart';
import 'summary_controller.dart';

class _SummaryDarkColors {
  const _SummaryDarkColors._();

  static const background = Color(0xFF000000);
  static const blue = Color(0xFF00AEFF);
  static const purple = Color(0xFF934BFB);
  static const pink = Color(0xFFFC49B5);
  static const progressTrack = Color(0xFF1B2028);
  static const divider = Color(0xFF24262B);
  static const primaryText = Color(0xFFFFFFFF);
  static const secondaryText = Color(0xFFB8B8BF);
  static const calorieGoalText = Color(0xFFC7C7CD);
}

/// Today's per-person nutrition overview and pair meal list.
class SummaryPage extends ConsumerWidget {
  const SummaryPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final state = ref.watch(summaryControllerProvider);

    return Scaffold(
      backgroundColor: isDark ? _SummaryDarkColors.background : null,
      appBar: AppBar(
        title: Text(appL10n.navToday),
        actions: [
          IconButton(
            tooltip: appL10n.profileNutritionGoals,
            icon: Icon(Icons.track_changes_outlined),
            onPressed: () => context.push('/nutrition-goals'),
          ),
          IconButton(
            tooltip: appL10n.pairDetails,
            icon: const Icon(Icons.people_outline),
            onPressed: () => context.push('/pairing'),
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          color: theme.colorScheme.primary,
          onRefresh: () =>
              ref.read(summaryControllerProvider.notifier).refresh(),
          child: switch (state) {
            SummaryLoading() => const LoadingView(),
            SummaryFailure(:final message) => ErrorView(
              message: message,
              onRetry: () =>
                  ref.read(summaryControllerProvider.notifier).refresh(),
            ),
            SummaryEmpty(:final summary) => _SummaryBody(
              summary: summary,
              emptyState: true,
            ),
            SummaryLoaded(:final summary) => _SummaryBody(
              summary: summary,
              emptyState: false,
            ),
          },
        ),
      ),
    );
  }
}

class _SummaryBody extends ConsumerWidget {
  const _SummaryBody({required this.summary, required this.emptyState});

  final DailySummary summary;
  final bool emptyState;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final secondaryTextColor = isDark
        ? _SummaryDarkColors.secondaryText
        : theme.colorScheme.onSurfaceVariant;
    final managementState = ref.watch(mealManagementControllerProvider);
    final sortedMeals = [...summary.meals]
      ..sort((left, right) {
        final leftIsCurrentUser = left.userId == summary.selfSlice.userId;
        final rightIsCurrentUser = right.userId == summary.selfSlice.userId;
        if (leftIsCurrentUser != rightIsCurrentUser) {
          return leftIsCurrentUser ? -1 : 1;
        }
        return _mealSortTime(right).compareTo(_mealSortTime(left));
      });
    return ListView(
      // Ensures pull-to-refresh works even when content is short (empty
      // state) by always allowing scroll.
      physics: AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.all(AppSpacing.pagePadding),
      children: [
        Text(
          DateFormat(appL10n.todayDateFormat, 'zh_CN').format(summary.date),
          style: TextStyle(fontSize: 13, color: secondaryTextColor),
        ),
        SizedBox(height: AppSpacing.md),
        _NutritionCard(
          title: appL10n.todayMyIntake,
          name: appL10n.todayMe,
          slice: summary.selfSlice,
          goals: summary.selfGoals,
          valueColor: isDark ? _SummaryDarkColors.blue : AppColors.protein,
        ),
        if (summary.partnerSlice != null && summary.partnerGoals != null) ...[
          SizedBox(height: AppSpacing.md),
          _NutritionCard(
            title: appL10n.todayPartnerIntake,
            name: summary.partnerSlice!.displayName,
            slice: summary.partnerSlice!,
            goals: summary.partnerGoals!,
            valueColor: isDark ? _SummaryDarkColors.pink : AppColors.fat,
          ),
        ],
        SizedBox(height: AppSpacing.xl),
        Text(
          appL10n.todayRecords,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: secondaryTextColor,
          ),
        ),
        SizedBox(height: AppSpacing.md),
        if (emptyState || summary.meals.isEmpty)
          Padding(
            padding: EdgeInsets.only(top: AppSpacing.xl),
            child: EmptyView(message: appL10n.todayEmpty),
          )
        else
          ...sortedMeals.map(
            (meal) => Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.md),
              child: _MealListItem(
                meal: meal,
                ownerName: _ownerName(meal),
                busy: managementState.isBusy(meal.id),
                onManage: meal.userId == summary.selfSlice.userId
                    ? () => _showMealActions(context, ref, meal)
                    : null,
              ),
            ),
          ),
      ],
    );
  }

  String _ownerName(Meal meal) {
    if (meal.userId == summary.selfSlice.userId) return appL10n.todayMe;
    final partner = summary.partnerSlice;
    if (partner != null && meal.userId == partner.userId) {
      return partner.displayName;
    }
    return appL10n.commonMember;
  }
}

DateTime _mealSortTime(Meal meal) {
  final timeParts = meal.mealTime.split(':');
  if (timeParts.length >= 2) {
    final hour = int.tryParse(timeParts[0]);
    final minute = int.tryParse(timeParts[1]);
    if (hour != null && minute != null) {
      return DateTime(
        meal.mealDate.year,
        meal.mealDate.month,
        meal.mealDate.day,
        hour,
        minute,
      );
    }
  }
  return meal.updatedAt;
}

enum _MealAction { portion, edit, refine, delete }

Future<void> _showMealActions(
  BuildContext context,
  WidgetRef ref,
  Meal meal,
) async {
  final action = await showBiteSyncModalBottomSheet<_MealAction>(
    context: context,
    showDragHandle: true,
    builder: (sheetContext) => SafeArea(
      child: Wrap(
        children: [
          ListTile(
            leading: Icon(Icons.pie_chart_outline),
            title: Text(appL10n.todayAdjustPortion),
            onTap: () => Navigator.pop(sheetContext, _MealAction.portion),
          ),
          ListTile(
            leading: Icon(Icons.edit_outlined),
            title: Text(appL10n.todayEditDirectly),
            onTap: () => Navigator.pop(sheetContext, _MealAction.edit),
          ),
          if (meal.source == MealSource.text)
            ListTile(
              leading: Icon(Icons.auto_awesome_outlined),
              title: Text(appL10n.todayReestimateWithNote),
              onTap: () => Navigator.pop(sheetContext, _MealAction.refine),
            ),
          ListTile(
            leading: Icon(Icons.delete_outline, color: AppColors.warning),
            title: Text(
              appL10n.commonDelete,
              style: TextStyle(color: AppColors.warning),
            ),
            onTap: () => Navigator.pop(sheetContext, _MealAction.delete),
          ),
        ],
      ),
    ),
  );
  if (!context.mounted || action == null) return;

  final controller = ref.read(mealManagementControllerProvider.notifier);
  MealManagementResult? result;
  String successMessage = appL10n.todayRecordUpdated;
  switch (action) {
    case _MealAction.portion:
      final ratio = await _showPortionPicker(context, meal);
      if (ratio == null || !context.mounted) return;
      result = await controller.updatePortion(meal, ratio);
      successMessage = appL10n.todayPortionUpdated;
      break;
    case _MealAction.edit:
      final values = await _showMealEditSheet(context, meal);
      if (values == null || !context.mounted) return;
      result = await controller.updateDetails(
        meal,
        name: values.name,
        baseCalories: values.baseCalories,
        baseProtein: values.baseProtein,
        baseCarbs: values.baseCarbs,
        baseFat: values.baseFat,
      );
      break;
    case _MealAction.refine:
      final hint = await _showRefineSheet(context);
      if (hint == null || !context.mounted) return;
      result = await controller.refineMeal(meal, hint);
      successMessage = appL10n.todayReestimated;
      break;
    case _MealAction.delete:
      final confirmed = await _showDeleteConfirmation(context);
      if (!confirmed || !context.mounted) return;
      result = await controller.deleteMeal(meal);
      successMessage = appL10n.todayRecordDeleted;
      break;
  }

  if (!context.mounted) return;
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(
        result.isSuccess
            ? successMessage
            : result.message ?? appL10n.errorOperationFailed,
      ),
    ),
  );
}

Future<double?> _showPortionPicker(BuildContext context, Meal meal) {
  return showBiteSyncModalBottomSheet<double>(
    context: context,
    showDragHandle: true,
    builder: (sheetContext) => SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          AppSpacing.pagePadding,
          0,
          AppSpacing.pagePadding,
          AppSpacing.xl,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              appL10n.todayAdjustPortion,
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: AppSpacing.md),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: <double>[0.5, 0.75, 1, 1.25, 1.5, 2]
                  .map(
                    (ratio) => ChoiceChip(
                      label: Text(appL10n.todayPortionRatio('$ratio')),
                      selected: meal.portionRatio == ratio,
                      onSelected: (_) => Navigator.pop(sheetContext, ratio),
                    ),
                  )
                  .toList(growable: false),
            ),
          ],
        ),
      ),
    ),
  );
}

Future<_MealEditValues?> _showMealEditSheet(
  BuildContext context,
  Meal meal,
) async {
  final name = TextEditingController(text: meal.name);
  final calories = TextEditingController(text: '${meal.baseCalories}');
  final protein = TextEditingController(text: '${meal.baseProtein}');
  final carbs = TextEditingController(text: '${meal.baseCarbs}');
  final fat = TextEditingController(text: '${meal.baseFat}');
  String? error;

  final values = await showBiteSyncModalBottomSheet<_MealEditValues>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (sheetContext) => StatefulBuilder(
      builder: (sheetContext, setModalState) => Padding(
        padding: EdgeInsets.fromLTRB(
          AppSpacing.pagePadding,
          0,
          AppSpacing.pagePadding,
          MediaQuery.viewInsetsOf(sheetContext).bottom + AppSpacing.xl,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                appL10n.todayEditDirectly,
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
              ),
              SizedBox(height: AppSpacing.md),
              _MealEditField(label: appL10n.todayName, controller: name),
              _MealEditField(
                label: appL10n.todayBaseCalories,
                controller: calories,
                numeric: true,
              ),
              _MealEditField(
                label: appL10n.todayBaseProtein,
                controller: protein,
                numeric: true,
              ),
              _MealEditField(
                label: appL10n.todayBaseCarbs,
                controller: carbs,
                numeric: true,
              ),
              _MealEditField(
                label: appL10n.todayBaseFat,
                controller: fat,
                numeric: true,
              ),
              if (error != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: Text(
                    error!,
                    style: const TextStyle(color: AppColors.warning),
                  ),
                ),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () {
                    final parsed = [
                      num.tryParse(calories.text.trim()),
                      num.tryParse(protein.text.trim()),
                      num.tryParse(carbs.text.trim()),
                      num.tryParse(fat.text.trim()),
                    ];
                    if (name.text.trim().isEmpty ||
                        parsed.any(
                          (value) =>
                              value == null || !value.isFinite || value < 0,
                        )) {
                      setModalState(() {
                        error = appL10n.todayInvalidMealValues;
                      });
                      return;
                    }
                    Navigator.pop(
                      sheetContext,
                      _MealEditValues(
                        name: name.text.trim(),
                        baseCalories: parsed[0]!,
                        baseProtein: parsed[1]!,
                        baseCarbs: parsed[2]!,
                        baseFat: parsed[3]!,
                      ),
                    );
                  },
                  child: Text(appL10n.commonSaveChanges),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );

  name.dispose();
  calories.dispose();
  protein.dispose();
  carbs.dispose();
  fat.dispose();
  return values;
}

Future<String?> _showRefineSheet(BuildContext context) async {
  final hint = TextEditingController();
  String? error;
  final value = await showBiteSyncModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (sheetContext) => StatefulBuilder(
      builder: (sheetContext, setModalState) => Padding(
        padding: EdgeInsets.fromLTRB(
          AppSpacing.pagePadding,
          0,
          AppSpacing.pagePadding,
          MediaQuery.viewInsetsOf(sheetContext).bottom + AppSpacing.xl,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              appL10n.todayReestimateWithNote,
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
            ),
            SizedBox(height: AppSpacing.md),
            TextField(
              controller: hint,
              autofocus: true,
              minLines: 2,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: appL10n.todayReestimateHint,
              ),
            ),
            if (error != null) ...[
              SizedBox(height: AppSpacing.sm),
              Text(error!, style: TextStyle(color: AppColors.warning)),
            ],
            SizedBox(height: AppSpacing.md),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () {
                  if (hint.text.trim().isEmpty) {
                    setModalState(() => error = appL10n.todayNoteRequired);
                    return;
                  }
                  Navigator.pop(sheetContext, hint.text.trim());
                },
                child: Text(appL10n.todayReestimate),
              ),
            ),
          ],
        ),
      ),
    ),
  );
  hint.dispose();
  return value;
}

Future<bool> _showDeleteConfirmation(BuildContext context) async {
  return await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: Text(appL10n.todayDeleteTitle),
          content: Text(appL10n.todayDeleteDescription),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: Text(appL10n.commonCancel),
            ),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: AppColors.warning),
              onPressed: () => Navigator.pop(dialogContext, true),
              child: Text(appL10n.todayConfirmDelete),
            ),
          ],
        ),
      ) ??
      false;
}

class _MealEditValues {
  const _MealEditValues({
    required this.name,
    required this.baseCalories,
    required this.baseProtein,
    required this.baseCarbs,
    required this.baseFat,
  });

  final String name;
  final num baseCalories;
  final num baseProtein;
  final num baseCarbs;
  final num baseFat;
}

class _MealEditField extends StatelessWidget {
  const _MealEditField({
    required this.label,
    required this.controller,
    this.numeric = false,
  });

  final String label;
  final TextEditingController controller;
  final bool numeric;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: TextField(
        controller: controller,
        keyboardType: numeric
            ? const TextInputType.numberWithOptions(decimal: true)
            : null,
        decoration: InputDecoration(labelText: label),
      ),
    );
  }
}

class _NutritionCard extends StatelessWidget {
  const _NutritionCard({
    required this.title,
    required this.name,
    required this.slice,
    required this.goals,
    required this.valueColor,
  });

  final String title;
  final String name;
  final UserDailySlice slice;
  final DailyGoals goals;
  final Color valueColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final secondaryTextColor = isDark
        ? _SummaryDarkColors.secondaryText
        : theme.colorScheme.onSurfaceVariant;
    return AppCard(
      backgroundColor: isDark ? _SummaryDarkColors.background : null,
      borderColor: isDark
          ? _SummaryDarkColors.blue
          : AppColors.lightScreenBorder,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: secondaryTextColor,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Flexible(
                child: Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(text: name),
                      TextSpan(text: ' ${slice.calories.round()}'),
                    ],
                    style: TextStyle(color: valueColor),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 32, fontWeight: FontWeight.w700),
                ),
              ),
              const SizedBox(width: 4),
              Text(
                appL10n.todayCalorieGoal(goals.calorieGoal.round()),
                style: TextStyle(
                  fontSize: 13,
                  color: isDark
                      ? _SummaryDarkColors.calorieGoalText
                      : theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Divider(
            height: 1,
            color: isDark ? _SummaryDarkColors.divider : theme.dividerColor,
          ),
          const SizedBox(height: AppSpacing.md),
          MacroBar(
            protein: slice.protein,
            proteinGoal: goals.proteinGoal,
            carbs: slice.carbs,
            carbsGoal: goals.carbsGoal,
            fat: slice.fat,
            fatGoal: goals.fatGoal,
            proteinFillColor: isDark
                ? _SummaryDarkColors.blue
                : AppColors.protein,
            carbsFillColor: isDark
                ? _SummaryDarkColors.purple
                : AppColors.carbs,
            fatFillColor: isDark ? _SummaryDarkColors.pink : AppColors.fat,
            proteinTrackColor: isDark
                ? _SummaryDarkColors.progressTrack
                : AppColors.proteinBg,
            carbsTrackColor: isDark
                ? _SummaryDarkColors.progressTrack
                : AppColors.carbsBg,
            fatTrackColor: isDark
                ? _SummaryDarkColors.progressTrack
                : AppColors.fatBg,
            textColor: isDark ? _SummaryDarkColors.secondaryText : null,
          ),
        ],
      ),
    );
  }
}

class _MealListItem extends StatelessWidget {
  const _MealListItem({
    required this.meal,
    required this.ownerName,
    required this.busy,
    required this.onManage,
  });

  final Meal meal;
  final String ownerName;
  final bool busy;
  final VoidCallback? onManage;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      backgroundColor: isDark ? _SummaryDarkColors.background : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  meal.name,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: isDark ? _SummaryDarkColors.primaryText : null,
                  ),
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    meal.mealTime,
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark
                          ? _SummaryDarkColors.secondaryText
                          : theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  Text(
                    ownerName,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ],
              ),
              if (onManage != null) ...[
                const SizedBox(width: AppSpacing.xs),
                if (busy)
                  const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                else
                  IconButton(
                    tooltip: appL10n.todayManageMeal(meal.name),
                    visualDensity: VisualDensity.compact,
                    onPressed: onManage,
                    icon: const Icon(Icons.more_vert),
                  ),
              ],
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            appL10n.commonCaloriesValue('${meal.calories.round()}'),
            style: TextStyle(
              fontSize: 13,
              color: isDark
                  ? _SummaryDarkColors.secondaryText
                  : theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.sm,
            children: [
              _MacroTag(
                label: appL10n.todayProteinGrams(meal.protein.round()),
                color: AppColors.protein,
                bg: AppColors.proteinBg,
                darkColor: _SummaryDarkColors.blue,
              ),
              _MacroTag(
                label: appL10n.todayCarbsGrams(meal.carbs.round()),
                color: AppColors.carbs,
                bg: AppColors.carbsBg,
                darkColor: _SummaryDarkColors.purple,
              ),
              _MacroTag(
                label: appL10n.todayFatGrams(meal.fat.round()),
                color: AppColors.fat,
                bg: AppColors.fatBg,
                darkColor: _SummaryDarkColors.pink,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MacroTag extends StatelessWidget {
  const _MacroTag({
    required this.label,
    required this.color,
    required this.bg,
    required this.darkColor,
  });

  final String label;
  final Color color;
  final Color bg;
  final Color darkColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: isDark ? darkColor.withValues(alpha: 0.14) : bg,
        borderRadius: BorderRadius.circular(AppRadius.full),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 11, color: isDark ? darkColor : color),
      ),
    );
  }
}
