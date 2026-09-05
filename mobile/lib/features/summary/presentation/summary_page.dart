import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/macro_bar.dart';
import '../../../shared/widgets/state_views.dart';
import '../../meals/domain/meal.dart';
import '../domain/daily_summary.dart';
import 'summary_controller.dart';

/// Today's nutrition overview: date, total calories, PFC breakdown, and
/// today's meal list — the MVP subset of the mini-program's `summary`
/// page (no pairing / dual-user cards, no goal editing).
class SummaryPage extends ConsumerWidget {
  const SummaryPage({super.key});

  static const _goals = DailyGoals();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(summaryControllerProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('今日')),
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
              goals: _goals,
              emptyState: true,
            ),
            SummaryLoaded(:final summary) => _SummaryBody(
              summary: summary,
              goals: _goals,
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
    required this.goals,
    required this.emptyState,
  });

  final DailySummary summary;
  final DailyGoals goals;
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
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    '${summary.calories.round()}',
                    style: const TextStyle(
                      fontSize: 40,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Text(
                    'kcal',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '/ ${goals.calorieGoal.round()} 目标',
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
                protein: summary.protein,
                proteinGoal: goals.proteinGoal,
                carbs: summary.carbs,
                carbsGoal: goals.carbsGoal,
                fat: summary.fat,
                fatGoal: goals.fatGoal,
              ),
            ],
          ),
        ),
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
              child: _MealListItem(meal: meal),
            ),
          ),
      ],
    );
  }
}

class _MealListItem extends StatelessWidget {
  const _MealListItem({required this.meal});

  final Meal meal;

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
              Text(
                meal.mealTime,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textTertiary,
                ),
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
