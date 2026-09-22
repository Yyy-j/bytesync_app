import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:bytesync/l10n/l10n.dart';

import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/bitesync_bottom_sheet.dart';
import '../../../shared/widgets/state_views.dart';
import '../../meals/domain/meal.dart';
import '../../meals/domain/meal_source.dart';
import '../../meals/presentation/meal_management_controller.dart';
import '../../profile/domain/user_character.dart';
import '../domain/daily_summary.dart';
import 'summary_controller.dart';

class _SummaryDarkColors {
  const _SummaryDarkColors._();

  static const background = Color(0xFF000000);
  static const blue = Color(0xFF00AEFF);
  static const purple = Color(0xFF934BFB);
  static const pink = Color(0xFFFC49B5);
  static const progressTrack = Color(0xFF1B2028);
  static const primaryText = Color(0xFFFFFFFF);
  static const secondaryText = Color(0xFFB8B8BF);
}

Color _summaryContentCardBorder(BuildContext context) =>
    Theme.of(context).brightness == Brightness.dark
    ? AppColors.darkContentCardBorder
    : AppColors.lightContentCardBorder;

/// Today's per-person nutrition overview and pair meal list.
class SummaryPage extends ConsumerStatefulWidget {
  const SummaryPage({super.key});

  @override
  ConsumerState<SummaryPage> createState() => _SummaryPageState();
}

class _SummaryPageState extends ConsumerState<SummaryPage> {
  bool _calendarExpanded = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final state = ref.watch(summaryControllerProvider);

    return Scaffold(
      backgroundColor: isDark ? _SummaryDarkColors.background : null,
      appBar: AppBar(
        title: Text(appL10n.navToday),
        actions: [
          IconButton(
            tooltip: _calendarExpanded ? '收起日历' : '展开日历',
            onPressed: () {
              setState(() => _calendarExpanded = !_calendarExpanded);
            },
            icon: AnimatedSwitcher(
              duration: const Duration(milliseconds: 180),
              transitionBuilder: (child, animation) => FadeTransition(
                opacity: animation,
                child: ScaleTransition(scale: animation, child: child),
              ),
              child: Icon(
                _calendarExpanded
                    ? Icons.calendar_month
                    : Icons.calendar_month_outlined,
                key: ValueKey(_calendarExpanded),
              ),
            ),
          ),
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
              calendarExpanded: _calendarExpanded,
            ),
            SummaryLoaded(:final summary) => _SummaryBody(
              summary: summary,
              emptyState: false,
              calendarExpanded: _calendarExpanded,
            ),
          },
        ),
      ),
    );
  }
}

class _SummaryBody extends ConsumerWidget {
  const _SummaryBody({
    required this.summary,
    required this.emptyState,
    required this.calendarExpanded,
  });

  final DailySummary summary;
  final bool emptyState;
  final bool calendarExpanded;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final controller = ref.read(summaryControllerProvider.notifier);
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
        _CalendarExpansion(
          expanded: calendarExpanded,
          child: _Calendar(
            focusedMonth: controller.focusedMonth,
            selectedDate: controller.selectedDate,
            monthly: controller.monthlySummary,
            loading: controller.monthlyLoading,
            error: controller.monthlyError,
            onDateSelected: controller.selectDate,
            onMonthChanged: controller.changeMonth,
            onToday: controller.goToToday,
            onRetry: () => controller.changeMonth(controller.focusedMonth),
          ),
        ),
        SizedBox(height: AppSpacing.lg),
        Text(
          DateFormat(appL10n.todayDateFormat, 'zh_CN').format(summary.date),
          style: TextStyle(fontSize: 13, color: secondaryTextColor),
        ),
        SizedBox(height: AppSpacing.sm),
        if (controller.dailyLoading)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: AppSpacing.xl),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (controller.dailyError != null)
          ErrorView(
            message: controller.dailyError!,
            onRetry: controller.refresh,
          )
        else ...[
          _SummaryCards(summary: summary),
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
                  characterAsset: _mealCharacter(meal).eatAsset,
                  busy: managementState.isBusy(meal.id),
                  onManage: meal.userId == summary.selfSlice.userId
                      ? () => _showMealActions(context, ref, meal)
                      : null,
                ),
              ),
            ),
        ],
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

  UserCharacter _mealCharacter(Meal meal) {
    if (meal.userId == summary.selfSlice.userId) {
      return summary.selfSlice.character;
    }
    final partner = summary.partnerSlice;
    if (partner != null && meal.userId == partner.userId) {
      return partner.character;
    }
    return UserCharacter.boy;
  }
}

class _CalendarExpansion extends StatefulWidget {
  const _CalendarExpansion({required this.expanded, required this.child});

  final bool expanded;
  final Widget child;

  @override
  State<_CalendarExpansion> createState() => _CalendarExpansionState();
}

class _CalendarExpansionState extends State<_CalendarExpansion>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final CurvedAnimation _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
      value: widget.expanded ? 1 : 0,
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOutCubic,
    );
  }

  @override
  void didUpdateWidget(covariant _CalendarExpansion oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.expanded == widget.expanded) return;
    if (widget.expanded) {
      _controller.forward();
    } else {
      _controller.reverse();
    }
  }

  @override
  void dispose() {
    _animation.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) => ClipRect(
        child: Align(
          alignment: Alignment.topCenter,
          heightFactor: _animation.value,
          child: child,
        ),
      ),
      child: widget.child,
    );
  }
}

class _Calendar extends StatelessWidget {
  const _Calendar({
    required this.focusedMonth,
    required this.selectedDate,
    required this.monthly,
    required this.loading,
    required this.error,
    required this.onDateSelected,
    required this.onMonthChanged,
    required this.onToday,
    required this.onRetry,
  });

  final DateTime focusedMonth;
  final DateTime selectedDate;
  final MonthlySummary? monthly;
  final bool loading;
  final String? error;
  final ValueChanged<DateTime> onDateSelected;
  final ValueChanged<DateTime> onMonthChanged;
  final VoidCallback onToday;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final selfColor = isDark ? _SummaryDarkColors.blue : AppColors.protein;
    final partnerColor = isDark ? _SummaryDarkColors.pink : AppColors.fat;
    final partnerName = monthly?.partner?.displayName;
    final first = DateTime(focusedMonth.year, focusedMonth.month, 1);
    final days = DateTime(focusedMonth.year, focusedMonth.month + 1, 0).day;
    final leading = first.weekday - 1;
    final cells = <DateTime?>[
      ...List<DateTime?>.filled(leading, null),
      for (var day = 1; day <= days; day++)
        DateTime(focusedMonth.year, focusedMonth.month, day),
    ];
    while (cells.length % 7 != 0) {
      cells.add(null);
    }
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border.all(color: _summaryContentCardBorder(context)),
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                tooltip: appL10n.todayPreviousMonth,
                onPressed: () => onMonthChanged(
                  DateTime(focusedMonth.year, focusedMonth.month - 1),
                ),
                icon: const Icon(Icons.chevron_left),
              ),
              Expanded(
                child: Text(
                  DateFormat(
                    appL10n.todayMonthFormat,
                    'zh_CN',
                  ).format(focusedMonth),
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
              IconButton(
                tooltip: appL10n.todayNextMonth,
                onPressed: () => onMonthChanged(
                  DateTime(focusedMonth.year, focusedMonth.month + 1),
                ),
                icon: const Icon(Icons.chevron_right),
              ),
            ],
          ),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: onToday,
              child: Text(appL10n.todayBackToToday),
            ),
          ),
          if (error != null)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(error!, style: TextStyle(color: theme.colorScheme.error)),
                TextButton(
                  onPressed: onRetry,
                  child: Text(appL10n.commonRetry),
                ),
              ],
            ),
          if (loading) const LinearProgressIndicator(minHeight: 2),
          Row(
            children: [
              for (final label in appL10n.todayWeekdays.split('|'))
                Expanded(
                  child: Text(
                    label,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: cells.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              childAspectRatio: 0.78,
            ),
            itemBuilder: (context, index) {
              final date = cells[index];
              if (date == null) return const SizedBox.shrink();
              final day = monthly?.dayAt(date);
              final selected = _sameDate(date, selectedDate);
              final today = _sameDate(date, DateTime.now());
              return _CalendarCell(
                date: date,
                selected: selected,
                today: today,
                selfColor: selfColor,
                partnerColor: partnerColor,
                selfProgress: _progress(
                  day?.selfCalories,
                  monthly?.self.calorieGoal,
                ),
                partnerProgress: monthly?.partner == null
                    ? null
                    : _progress(
                        day?.partnerCalories,
                        monthly?.partner?.calorieGoal,
                      ),
                onTap: () => onDateSelected(date),
              );
            },
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _LegendDot(color: selfColor, label: appL10n.todayMe),
              if (partnerName != null) ...[
                const SizedBox(width: AppSpacing.lg),
                _LegendDot(color: partnerColor, label: partnerName),
              ],
            ],
          ),
        ],
      ),
    );
  }

  static bool _sameDate(DateTime left, DateTime right) =>
      left.year == right.year &&
      left.month == right.month &&
      left.day == right.day;

  static double _progress(num? value, num? goal) {
    if (value == null || goal == null || goal <= 0) return 0;
    return (value / goal).clamp(0, 1).toDouble();
  }
}

class _CalendarCell extends StatelessWidget {
  const _CalendarCell({
    required this.date,
    required this.selected,
    required this.today,
    required this.selfColor,
    required this.partnerColor,
    required this.selfProgress,
    required this.partnerProgress,
    required this.onTap,
  });

  final DateTime date;
  final bool selected;
  final bool today;
  final Color selfColor;
  final Color partnerColor;
  final double selfProgress;
  final double? partnerProgress;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(2),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.sm),
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            color: selected
                ? theme.colorScheme.primary.withValues(alpha: 0.12)
                : null,
            border: Border.all(
              color: selected
                  ? theme.colorScheme.primary
                  : today
                  ? theme.colorScheme.outline
                  : Colors.transparent,
            ),
            borderRadius: BorderRadius.circular(AppRadius.sm),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 4),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('${date.day}', style: const TextStyle(fontSize: 13)),
              const SizedBox(height: 5),
              _ProgressLine(value: selfProgress, color: selfColor),
              if (partnerProgress != null) ...[
                const SizedBox(height: 3),
                _ProgressLine(value: partnerProgress!, color: partnerColor),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _ProgressLine extends StatelessWidget {
  const _ProgressLine({required this.value, required this.color});

  final double value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.full),
      child: LinearProgressIndicator(
        value: value,
        minHeight: 2,
        backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
        valueColor: AlwaysStoppedAnimation<Color>(color),
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.circle, size: 8, color: color),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }
}

class _SummaryCards extends StatelessWidget {
  const _SummaryCards({required this.summary});

  final DailySummary summary;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: _CompactNutritionCard(
            name: appL10n.todayMe,
            slice: summary.selfSlice,
            goals: summary.selfGoals,
            characterAsset: summary.selfSlice.character.bodyAsset,
            valueColor: Theme.of(context).brightness == Brightness.dark
                ? _SummaryDarkColors.blue
                : AppColors.protein,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        if (summary.partnerSlice != null && summary.partnerGoals != null)
          Expanded(
            child: _CompactNutritionCard(
              name: summary.partnerSlice!.displayName,
              slice: summary.partnerSlice!,
              goals: summary.partnerGoals!,
              characterAsset: summary.partnerSlice!.character.bodyAsset,
              valueColor: Theme.of(context).brightness == Brightness.dark
                  ? _SummaryDarkColors.pink
                  : AppColors.fat,
            ),
          ),
      ],
    );
  }
}

class _CompactNutritionCard extends StatelessWidget {
  const _CompactNutritionCard({
    required this.name,
    required this.slice,
    required this.goals,
    required this.characterAsset,
    required this.valueColor,
  });

  final String name;
  final UserDailySlice slice;
  final DailyGoals goals;
  final String characterAsset;
  final Color valueColor;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final track = isDark ? _SummaryDarkColors.progressTrack : AppColors.border;
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      backgroundColor: isDark ? _SummaryDarkColors.background : null,
      borderColor: _summaryContentCardBorder(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: valueColor,
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              SizedBox(
                width: 60,
                height: 60,
                child: SvgPicture.asset(characterAsset, fit: BoxFit.contain),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: '${slice.calories.round()} ',
                    style: TextStyle(color: valueColor),
                  ),
                  TextSpan(
                    text: appL10n.todayCalorieGoal(goals.calorieGoal.round()),
                  ),
                ],
              ),
              maxLines: 1,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          _CompactMacro(
            label: appL10n.commonProtein,
            value: slice.protein,
            goal: goals.proteinGoal,
            color: isDark ? _SummaryDarkColors.blue : AppColors.protein,
            track: track,
          ),
          _CompactMacro(
            label: appL10n.macroCarbs,
            value: slice.carbs,
            goal: goals.carbsGoal,
            color: isDark ? _SummaryDarkColors.purple : AppColors.carbs,
            track: track,
          ),
          _CompactMacro(
            label: appL10n.commonFat,
            value: slice.fat,
            goal: goals.fatGoal,
            color: isDark ? _SummaryDarkColors.pink : AppColors.fat,
            track: track,
          ),
        ],
      ),
    );
  }
}

class _CompactMacro extends StatelessWidget {
  const _CompactMacro({
    required this.label,
    required this.value,
    required this.goal,
    required this.color,
    required this.track,
  });

  final String label;
  final num value;
  final num goal;
  final Color color;
  final Color track;

  @override
  Widget build(BuildContext context) {
    final progress = goal <= 0 ? 0.0 : (value / goal).clamp(0, 1).toDouble();
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$label ${value.round()} / ${goal.round()}g',
            style: const TextStyle(fontSize: 11),
          ),
          const SizedBox(height: 3),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.full),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 4,
              backgroundColor: track,
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ],
      ),
    );
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

class _MealListItem extends StatelessWidget {
  const _MealListItem({
    required this.meal,
    required this.ownerName,
    required this.characterAsset,
    required this.busy,
    required this.onManage,
  });

  final Meal meal;
  final String ownerName;
  final String characterAsset;
  final bool busy;
  final VoidCallback? onManage;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      backgroundColor: isDark ? _SummaryDarkColors.background : null,
      borderColor: _summaryContentCardBorder(context),
      child: Stack(
        children: [
          SizedBox(
            width: double.infinity,
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
                    SizedBox(
                      width: 112,
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  meal.mealTime,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: isDark
                                        ? _SummaryDarkColors.secondaryText
                                        : theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                                Text(
                                  ownerName,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: theme.colorScheme.primary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(
                            width: 32,
                            height: 32,
                            child: onManage == null
                                ? null
                                : busy
                                ? const Center(
                                    child: SizedBox(
                                      width: 24,
                                      height: 24,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    ),
                                  )
                                : IconButton(
                                    tooltip: appL10n.todayManageMeal(meal.name),
                                    visualDensity: VisualDensity.compact,
                                    padding: EdgeInsets.zero,
                                    onPressed: onManage,
                                    icon: const Icon(Icons.more_vert),
                                  ),
                          ),
                        ],
                      ),
                    ),
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
                const SizedBox(height: AppSpacing.xs),
                Padding(
                  padding: const EdgeInsets.only(right: 80),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _MacroTag(
                          label: appL10n.todayProteinGrams(
                            meal.protein.round(),
                          ),
                          color: AppColors.protein,
                          bg: AppColors.proteinBg,
                          darkColor: _SummaryDarkColors.blue,
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        _MacroTag(
                          label: appL10n.todayCarbsGrams(meal.carbs.round()),
                          color: AppColors.carbs,
                          bg: AppColors.carbsBg,
                          darkColor: _SummaryDarkColors.purple,
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        _MacroTag(
                          label: appL10n.todayFatGrams(meal.fat.round()),
                          color: AppColors.fat,
                          bg: AppColors.fatBg,
                          darkColor: _SummaryDarkColors.pink,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 28),
              ],
            ),
          ),
          Positioned(
            right: 0,
            bottom: 0,
            child: SizedBox(
              width: 72,
              height: 72,
              child: SvgPicture.asset(
                characterAsset,
                fit: BoxFit.contain,
              ),
            ),
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
