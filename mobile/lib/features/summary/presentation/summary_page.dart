import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/macro_bar.dart';
import '../../../shared/widgets/state_views.dart';
import '../../meals/domain/meal.dart';
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

class _SummaryBody extends StatelessWidget {
  const _SummaryBody({
    required this.summary,
    required this.emptyState,
  });

  final DailySummary summary;
  final bool emptyState;

  @override
  Widget build(BuildContext context) {
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
  const _MealListItem({required this.meal, required this.ownerName});

  final Meal meal;
  final String ownerName;

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
