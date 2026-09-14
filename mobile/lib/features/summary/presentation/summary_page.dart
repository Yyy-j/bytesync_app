import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/macro_bar.dart';
import '../../../shared/widgets/state_views.dart';
import '../../meals/domain/meal.dart';
import '../../meals/domain/meal_source.dart';
import '../../meals/presentation/meal_management_controller.dart';
import '../domain/daily_summary.dart';
import 'summary_controller.dart';

/// Today's per-person nutrition overview and pair meal list.
class SummaryPage extends ConsumerWidget {
  const SummaryPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(summaryControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('今日'),
        actions: [
          IconButton(
            tooltip: '营养目标',
            icon: const Icon(Icons.track_changes_outlined),
            onPressed: () => context.push('/nutrition-goals'),
          ),
          IconButton(
            tooltip: '配对详情',
            icon: const Icon(Icons.people_outline),
            onPressed: () => context.push('/pairing'),
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.primary,
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
  const _SummaryBody({
    required this.summary,
    required this.emptyState,
  });

  final DailySummary summary;
  final bool emptyState;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final managementState = ref.watch(mealManagementControllerProvider);
    return ListView(
      // Ensures pull-to-refresh works even when content is short (empty
      // state) by always allowing scroll.
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(AppSpacing.pagePadding),
      children: [
        Text(
          DateFormat('yyyy年M月d日 EEEE', 'zh_CN').format(summary.date),
          style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
        ),
        const SizedBox(height: AppSpacing.md),
        _NutritionCard(
          title: '我的今日摄入',
          name: '我',
          slice: summary.selfSlice,
          goals: summary.selfGoals,
        ),
        if (summary.partnerSlice != null && summary.partnerGoals != null) ...[
          const SizedBox(height: AppSpacing.md),
          _NutritionCard(
            title: '搭档今日摄入',
            name: summary.partnerSlice!.displayName,
            slice: summary.partnerSlice!,
            goals: summary.partnerGoals!,
          ),
        ],
        const SizedBox(height: AppSpacing.xl),
        const Text(
          '今日记录',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        if (emptyState || summary.meals.isEmpty)
          const Padding(
            padding: EdgeInsets.only(top: AppSpacing.xl),
            child: EmptyView(message: '还没有记录，去记一笔吧'),
          )
        else
          ...summary.meals.map(
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
    if (meal.userId == summary.selfSlice.userId) return '我';
    final partner = summary.partnerSlice;
    if (partner != null && meal.userId == partner.userId) {
      return partner.displayName;
    }
    return '成员';
  }
}

enum _MealAction { portion, edit, refine, delete }

Future<void> _showMealActions(
  BuildContext context,
  WidgetRef ref,
  Meal meal,
) async {
  final action = await showModalBottomSheet<_MealAction>(
    context: context,
    showDragHandle: true,
    builder: (sheetContext) => SafeArea(
      child: Wrap(
        children: [
          ListTile(
            leading: const Icon(Icons.pie_chart_outline),
            title: const Text('调整份量'),
            onTap: () => Navigator.pop(sheetContext, _MealAction.portion),
          ),
          ListTile(
            leading: const Icon(Icons.edit_outlined),
            title: const Text('直接编辑'),
            onTap: () => Navigator.pop(sheetContext, _MealAction.edit),
          ),
          if (meal.source == MealSource.text)
            ListTile(
              leading: const Icon(Icons.auto_awesome_outlined),
              title: const Text('补充说明再估算'),
              onTap: () => Navigator.pop(sheetContext, _MealAction.refine),
            ),
          ListTile(
            leading: const Icon(
              Icons.delete_outline,
              color: AppColors.warning,
            ),
            title: const Text(
              '删除',
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
  String successMessage = '记录已更新';
  switch (action) {
    case _MealAction.portion:
      final ratio = await _showPortionPicker(context, meal);
      if (ratio == null || !context.mounted) return;
      result = await controller.updatePortion(meal, ratio);
      successMessage = '份量已更新';
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
      successMessage = '已重新估算并更新';
      break;
    case _MealAction.delete:
      final confirmed = await _showDeleteConfirmation(context);
      if (!confirmed || !context.mounted) return;
      result = await controller.deleteMeal(meal);
      successMessage = '记录已删除';
      break;
  }

  if (!context.mounted || result == null) return;
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(
        result.isSuccess ? successMessage : result.message ?? '操作失败，请稍后重试',
      ),
    ),
  );
}

Future<double?> _showPortionPicker(BuildContext context, Meal meal) {
  return showModalBottomSheet<double>(
    context: context,
    showDragHandle: true,
    builder: (sheetContext) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.pagePadding,
          0,
          AppSpacing.pagePadding,
          AppSpacing.xl,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '调整份量',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: AppSpacing.md),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: <double>[0.5, 0.75, 1, 1.25, 1.5, 2]
                  .map(
                    (ratio) => ChoiceChip(
                      label: Text('${ratio}x'),
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

  final values = await showModalBottomSheet<_MealEditValues>(
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
              const Text(
                '直接编辑',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: AppSpacing.md),
              _MealEditField(label: '名称', controller: name),
              _MealEditField(
                label: '基础卡路里',
                controller: calories,
                numeric: true,
              ),
              _MealEditField(
                label: '基础蛋白质',
                controller: protein,
                numeric: true,
              ),
              _MealEditField(
                label: '基础碳水',
                controller: carbs,
                numeric: true,
              ),
              _MealEditField(
                label: '基础脂肪',
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
                        error = '请填写名称和大于等于 0 的有效营养数值';
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
                  child: const Text('保存修改'),
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
  final value = await showModalBottomSheet<String>(
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
            const Text(
              '补充说明再估算',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: hint,
              autofocus: true,
              minLines: 2,
              maxLines: 4,
              decoration: const InputDecoration(
                hintText: '例如：米饭其实只有半碗',
              ),
            ),
            if (error != null) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(error!, style: const TextStyle(color: AppColors.warning)),
            ],
            const SizedBox(height: AppSpacing.md),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () {
                  if (hint.text.trim().isEmpty) {
                    setModalState(() => error = '请输入补充说明');
                    return;
                  }
                  Navigator.pop(sheetContext, hint.text.trim());
                },
                child: const Text('重新估算'),
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
          title: const Text('删除这条记录？'),
          content: const Text('删除后无法恢复。'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('取消'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: AppColors.warning),
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('确认删除'),
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
  });

  final String title;
  final String name;
  final UserDailySlice slice;
  final DailyGoals goals;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Flexible(
                child: Text(
                  '$name ${slice.calories.round()}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              const SizedBox(width: 4),
              Text(
                '/ ${goals.calorieGoal.round()} kcal',
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textTertiary,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          const Divider(height: 1, color: AppColors.border),
          const SizedBox(height: AppSpacing.md),
          MacroBar(
            protein: slice.protein,
            proteinGoal: goals.proteinGoal,
            carbs: slice.carbs,
            carbsGoal: goals.carbsGoal,
            fat: slice.fat,
            fatGoal: goals.fatGoal,
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
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  meal.name,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    meal.mealTime,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textTertiary,
                    ),
                  ),
                  Text(
                    ownerName,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primaryDark,
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
                    tooltip: '管理${meal.name}',
                    visualDensity: VisualDensity.compact,
                    onPressed: onManage,
                    icon: const Icon(Icons.more_vert),
                  ),
              ],
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            '${meal.calories.round()} kcal',
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.sm,
            children: [
              _MacroTag(
                label: '蛋白 ${meal.protein.round()}g',
                color: AppColors.protein,
                bg: AppColors.proteinBg,
              ),
              _MacroTag(
                label: '碳水 ${meal.carbs.round()}g',
                color: AppColors.carbs,
                bg: AppColors.carbsBg,
              ),
              _MacroTag(
                label: '脂肪 ${meal.fat.round()}g',
                color: AppColors.fat,
                bg: AppColors.fatBg,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MacroTag extends StatelessWidget {
  const _MacroTag({required this.label, required this.color, required this.bg});

  final String label;
  final Color color;
  final Color bg;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppRadius.full),
      ),
      child: Text(label, style: TextStyle(fontSize: 11, color: color)),
    );
  }
}
