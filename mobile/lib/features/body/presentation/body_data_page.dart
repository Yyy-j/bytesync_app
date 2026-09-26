import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/state_views.dart';
import '../data/body_providers.dart';
import '../domain/body_data.dart';
import 'body_profile_edit_page.dart';

final bodyDataControllerProvider =
    AsyncNotifierProvider.autoDispose<BodyDataController, BodyViewData>(
      BodyDataController.new,
    );

class BodyViewData {
  const BodyViewData({required this.body, required this.weights});
  final BodyData body;
  final List<WeightMeasurement> weights;
}

class BodyDataController extends AutoDisposeAsyncNotifier<BodyViewData> {
  @override
  Future<BodyViewData> build() async {
    final repository = ref.watch(bodyRepositoryProvider);
    final result = await Future.wait([
      repository.getBody(),
      repository.getWeights(),
    ]);
    return BodyViewData(
      body: result[0] as BodyData,
      weights: result[1] as List<WeightMeasurement>,
    );
  }

  Future<void> reload() async => state = await AsyncValue.guard(build);
  Future<void> addWeight(DateTime date, double weight) async {
    await ref
        .read(bodyRepositoryProvider)
        .createWeight(measuredOn: date, weightKg: weight);
    await reload();
  }

  Future<void> updateWeight(String id, DateTime date, double weight) async {
    await ref
        .read(bodyRepositoryProvider)
        .updateWeight(id, measuredOn: date, weightKg: weight);
    await reload();
  }

  Future<void> deleteWeight(String id) async {
    await ref.read(bodyRepositoryProvider).deleteWeight(id);
    await reload();
  }
}

class BodyDataPage extends ConsumerWidget {
  const BodyDataPage({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(bodyDataControllerProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('身体数据'),
        actions: [
          IconButton(
            tooltip: '编辑身体目标',
            icon: const Icon(Icons.edit_outlined),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const BodyProfileEditPage()),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: state.when(
          loading: () => const LoadingView(),
          error: (error, _) => ErrorView(
            message: error is ApiException ? error.message : '加载失败，请重试',
            onRetry: () => ref.invalidate(bodyDataControllerProvider),
          ),
          data: (data) => _content(context, ref, data),
        ),
      ),
    );
  }

  Widget _content(
    BuildContext context,
    WidgetRef ref,
    BodyViewData data,
  ) => ListView(
    padding: EdgeInsets.all(AppSpacing.pagePadding),
    children: [
      AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('当前体重'),
            Text(
              data.body.currentWeight == null
                  ? '还没有记录'
                  : '${data.body.currentWeight!.weightKg} kg',
              style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w700),
            ),
            if (data.body.currentWeight != null)
              Text('BMI ${data.body.currentWeight!.bmi}'),
          ],
        ),
      ),
      SizedBox(height: AppSpacing.md),
      AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('目标'),
            Text(
              data.body.targetWeightKg == null
                  ? '还没有设置目标'
                  : '目标体重 ${data.body.targetWeightKg} kg',
            ),
            if (data.body.targetDate != null)
              Text(
                '目标日期 ${data.body.targetDate!.month}月${data.body.targetDate!.day}日',
              ),
            if (data.body.weightDifferenceKg != null)
              Text(
                data.body.weightDifferenceKg! < 0
                    ? '距离目标还有 ${data.body.weightDifferenceKg!.abs()} kg'
                    : '还需要增加 ${data.body.weightDifferenceKg} kg',
              ),
          ],
        ),
      ),
      SizedBox(height: AppSpacing.lg),
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('体重记录', style: Theme.of(context).textTheme.titleLarge),
          IconButton(
            onPressed: () => _add(context, ref),
            icon: const Icon(Icons.add),
            tooltip: '记录体重',
          ),
        ],
      ),
      if (data.weights.isEmpty) const EmptyView(message: '还没有体重记录'),
      if (data.weights.isNotEmpty)
        AppCard(
          child: SizedBox(
            height: 150,
            child: CustomPaint(
              painter: _WeightChartPainter(
                data.weights,
                Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
        ),
      ...data.weights.map(
        (weight) => ListTile(
          title: Text('${weight.weightKg} kg'),
          subtitle: Text(
            '${weight.measuredOn.month}月${weight.measuredOn.day}日 · BMI ${weight.bmi}',
          ),
          trailing: IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: () => _delete(context, ref, weight),
          ),
          onTap: () => _edit(context, ref, weight),
        ),
      ),
    ],
  );

  Future<void> _add(BuildContext context, WidgetRef ref) async {
    await _weightEditor(context, ref);
  }

  Future<void> _edit(
    BuildContext context,
    WidgetRef ref,
    WeightMeasurement weight,
  ) async {
    await _weightEditor(context, ref, existing: weight);
  }

  Future<void> _weightEditor(
    BuildContext context,
    WidgetRef ref, {
    WeightMeasurement? existing,
  }) async {
    final controller = TextEditingController();
    controller.text = existing?.weightKg.toString() ?? '';
    var measuredOn = existing?.measuredOn ?? DateTime.now();
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => StatefulBuilder(
        builder: (sheetContext, setSheetState) => Padding(
          padding: EdgeInsets.fromLTRB(
            24,
            24,
            24,
            MediaQuery.viewInsetsOf(sheetContext).bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text('日期：${measuredOn.month}月${measuredOn.day}日'),
                trailing: const Icon(Icons.calendar_today_outlined),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: sheetContext,
                    firstDate: DateTime(2000),
                    lastDate: DateTime.now(),
                    initialDate: measuredOn.isAfter(DateTime.now())
                        ? DateTime.now()
                        : measuredOn,
                  );
                  if (picked != null) {
                    measuredOn = picked;
                    if (sheetContext.mounted) setSheetState(() {});
                  }
                },
              ),
              TextField(
                controller: controller,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  labelText: '体重',
                  suffixText: 'kg',
                ),
              ),
              FilledButton(
                onPressed: () async {
                  final weight = double.tryParse(controller.text);
                  if (weight == null || weight < 20 || weight > 400) return;
                  try {
                    if (existing == null) {
                      await ref
                          .read(bodyDataControllerProvider.notifier)
                          .addWeight(measuredOn, weight);
                    } else {
                      await ref
                          .read(bodyDataControllerProvider.notifier)
                          .updateWeight(existing.id, measuredOn, weight);
                    }
                    if (sheetContext.mounted) Navigator.pop(sheetContext);
                  } catch (error) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            error is ApiException
                                ? existing == null
                                      ? '这一天已经有体重记录，可以直接修改已有记录。'
                                      : '这一天已经有体重记录，请选择其他日期。'
                                : '保存失败，请重试',
                          ),
                        ),
                      );
                    }
                  }
                },
                child: Text(existing == null ? '记录体重' : '保存修改'),
              ),
            ],
          ),
        ),
      ),
    );
    controller.dispose();
  }

  Future<void> _delete(
    BuildContext context,
    WidgetRef ref,
    WeightMeasurement weight,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('删除这条体重记录？'),
        content: const Text('删除后无法恢复。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('删除'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await ref
          .read(bodyDataControllerProvider.notifier)
          .deleteWeight(weight.id);
    }
  }
}

class _WeightChartPainter extends CustomPainter {
  _WeightChartPainter(this.weights, this.color);
  final List<WeightMeasurement> weights;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final values = weights.reversed
        .take(30)
        .map((item) => item.weightKg)
        .toList();
    if (values.isEmpty) return;
    final minValue = values.reduce((a, b) => a < b ? a : b);
    final maxValue = values.reduce((a, b) => a > b ? a : b);
    final range = (maxValue - minValue).abs();
    final scale = range == 0 ? 1 : range;
    final path = Path();
    final points = <Offset>[];
    for (var index = 0; index < values.length; index++) {
      final x = values.length == 1
          ? size.width / 2
          : index * size.width / (values.length - 1);
      final y =
          size.height - ((values[index] - minValue) / scale * size.height);
      points.add(Offset(x, y));
      if (index == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    if (values.length > 1) canvas.drawPath(path, paint);
    canvas.drawPoints(ui.PointMode.points, points, paint..strokeWidth = 8);
  }

  @override
  bool shouldRepaint(_WeightChartPainter oldDelegate) {
    if (oldDelegate.color != color ||
        oldDelegate.weights.length != weights.length) {
      return true;
    }
    for (var index = 0; index < weights.length; index++) {
      final oldWeight = oldDelegate.weights[index];
      final weight = weights[index];
      if (oldWeight.id != weight.id ||
          oldWeight.weightKg != weight.weightKg ||
          oldWeight.measuredOn != weight.measuredOn ||
          oldWeight.bmi != weight.bmi) {
        return true;
      }
    }
    return false;
  }
}
