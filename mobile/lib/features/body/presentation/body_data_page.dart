import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bytesync/l10n/l10n.dart';
import 'package:intl/intl.dart';

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
        title: Text(appL10n.bodyTitle),
        actions: [
          IconButton(
            tooltip: appL10n.bodyEditProfile,
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
            message: error is ApiException
                ? error.message
                : appL10n.bodyProfileLoadFailed,
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
            Text(appL10n.bodyCurrentWeight),
            Text(
              data.body.currentWeight == null
                  ? appL10n.bodyNoWeight
                  : '${data.body.currentWeight!.weightKg} kg',
              style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w700),
            ),
            if (data.body.currentWeight != null)
              Text(
                appL10n.bodyBmiValue(data.body.currentWeight!.bmi.toString()),
              ),
          ],
        ),
      ),
      SizedBox(height: AppSpacing.md),
      AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(appL10n.bodyGoal),
            Text(
              data.body.targetWeightKg == null
                  ? appL10n.bodyNoGoal
                  : appL10n.bodyTargetWeightValue(
                      data.body.targetWeightKg.toString(),
                    ),
            ),
            if (data.body.targetDate != null)
              Text(appL10n.bodyTargetDateValue(_date(data.body.targetDate!))),
            if (data.body.weightDifferenceKg != null)
              Text(
                data.body.weightDifferenceKg! < 0
                    ? appL10n.bodyWeightRemaining(
                        data.body.weightDifferenceKg!.abs().toString(),
                      )
                    : appL10n.bodyWeightIncrease(
                        data.body.weightDifferenceKg.toString(),
                      ),
              ),
          ],
        ),
      ),
      SizedBox(height: AppSpacing.lg),
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            appL10n.bodyWeightRecords,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          IconButton(
            onPressed: () => _add(context, ref),
            icon: const Icon(Icons.add),
            tooltip: appL10n.bodyAddWeight,
          ),
        ],
      ),
      if (data.weights.isEmpty)
        Column(
          children: [
            EmptyView(message: appL10n.bodyEmptyWeights),
            Text(appL10n.bodyEmptyWeightsHint),
          ],
        ),
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
            '${_date(weight.measuredOn)} · ${appL10n.bodyBmiValue(weight.bmi.toString())}',
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
                title: Text(appL10n.bodyTargetDateValue(_date(measuredOn))),
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
                decoration: InputDecoration(
                  labelText: appL10n.bodyWeight,
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
                                      ? appL10n.bodyDuplicateCreate
                                      : appL10n.bodyDuplicateUpdate
                                : appL10n.bodySaveFailed,
                          ),
                        ),
                      );
                    }
                  }
                },
                child: Text(
                  existing == null ? appL10n.bodyAddWeight : appL10n.bodySave,
                ),
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
        title: Text(appL10n.bodyDeleteTitle),
        content: Text(appL10n.bodyDeleteDescription),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(appL10n.commonCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(appL10n.bodyDelete),
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

  String _date(DateTime date) =>
      DateFormat(appL10n.commonDateFormat, 'zh_CN').format(date);
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
