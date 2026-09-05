import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../app/home_shell.dart';
import '../../../core/theme/app_theme.dart';
import '../domain/meal_patch.dart';
import '../domain/meal_share_mode.dart';
import '../domain/meal_source.dart';
import '../../summary/presentation/summary_controller.dart';
import 'add_meal_controller.dart';

/// Manual meal-entry form — the MVP subset of the mini-program's `record`
/// page. Photo capture, AI recognition, portion ratios, and pairing/split
/// are intentionally out of scope for this stage.
class AddMealPage extends ConsumerStatefulWidget {
  const AddMealPage({super.key});

  @override
  ConsumerState<AddMealPage> createState() => _AddMealPageState();
}

class _AddMealPageState extends ConsumerState<AddMealPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _caloriesController = TextEditingController();
  final _proteinController = TextEditingController();
  final _carbsController = TextEditingController();
  final _fatController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _caloriesController.dispose();
    _proteinController.dispose();
    _carbsController.dispose();
    _fatController.dispose();
    super.dispose();
  }

  num _parseNum(String text) => num.tryParse(text.trim()) ?? 0;

  Future<void> _onSave() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    FocusScope.of(context).unfocus();

    final input = NewMealInput(
      name: _nameController.text.trim().isEmpty
          ? '手动记录'
          : _nameController.text.trim(),
      source: MealSource.manual,
      baseCalories: _parseNum(_caloriesController.text),
      baseProtein: _parseNum(_proteinController.text),
      baseCarbs: _parseNum(_carbsController.text),
      baseFat: _parseNum(_fatController.text),
      portionRatio: 1,
      shareMode: MealShareMode.solo,
      mealTime: DateFormat('HH:mm').format(DateTime.now()),
    );

    final ok = await ref.read(addMealControllerProvider.notifier).submit(input);
    if (!mounted) return;

    if (ok) {
      // Today's summary should reflect the new meal immediately, whether
      // it came from the mock store or the real backend.
      await ref.read(summaryControllerProvider.notifier).refresh();
      if (!mounted) return;
      _nameController.clear();
      _caloriesController.clear();
      _proteinController.clear();
      _carbsController.clear();
      _fatController.clear();
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('已保存')));
      // "记录" is a bottom-nav tab, not a pushed route, so "return to
      // today's page" means switching the shell back to the 今日 tab.
      ref.read(homeTabIndexProvider.notifier).state = 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(addMealControllerProvider);
    final isSaving = state is AddMealSaving;
    final errorMessage = state is AddMealError ? state.message : null;

    return Scaffold(
      appBar: AppBar(title: const Text('记录饮食')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.pagePadding),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '手动记录一餐',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: AppSpacing.xs),
                const Text(
                  '填写食物名称和营养信息，保存后自动出现在今日汇总里',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                _FormField(
                  label: '食物名称',
                  controller: _nameController,
                  hintText: '例如：鸡胸肉沙拉',
                ),
                _FormField(
                  label: '卡路里',
                  controller: _caloriesController,
                  hintText: '千卡',
                  required: true,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                ),
                _FormField(
                  label: '蛋白质 (Protein)',
                  controller: _proteinController,
                  hintText: '克',
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                ),
                _FormField(
                  label: '碳水 (Carbs)',
                  controller: _carbsController,
                  hintText: '克',
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                ),
                _FormField(
                  label: '脂肪 (Fat)',
                  controller: _fatController,
                  hintText: '克',
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                ),
                if (errorMessage != null) ...[
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    errorMessage,
                    style: const TextStyle(
                      color: AppColors.warning,
                      fontSize: 13,
                    ),
                  ),
                ],
                const SizedBox(height: AppSpacing.xl),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: isSaving ? null : _onSave,
                    child: Text(isSaving ? '保存中…' : '保存'),
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FormField extends StatelessWidget {
  const _FormField({
    required this.label,
    required this.controller,
    required this.hintText,
    this.required = false,
    this.keyboardType,
  });

  final String label;
  final TextEditingController controller;
  final String hintText;
  final bool required;
  final TextInputType? keyboardType;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (required)
                const Text(' *', style: TextStyle(color: AppColors.warning)),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          TextFormField(
            controller: controller,
            keyboardType: keyboardType,
            decoration: InputDecoration(hintText: hintText),
            validator: required
                ? (value) {
                    final n = num.tryParse((value ?? '').trim());
                    if (n == null || n <= 0) return '请填写大于 0 的卡路里';
                    return null;
                  }
                : null,
          ),
        ],
      ),
    );
  }
}
