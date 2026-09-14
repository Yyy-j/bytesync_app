import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../app/home_shell.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../pair/domain/pair_state.dart';
import '../../../pair/presentation/pair_controller.dart';
import '../../domain/meal.dart';
import '../../domain/meal_share_mode.dart';
import '../../domain/meal_source.dart';
import '../domain/record_draft.dart';
import '../domain/record_state.dart';
import 'record_controller.dart';

class RecordPage extends ConsumerStatefulWidget {
  const RecordPage({super.key});

  @override
  ConsumerState<RecordPage> createState() => _RecordPageState();
}

class _RecordPageState extends ConsumerState<RecordPage> {
  final _textController = TextEditingController();
  final _hintController = TextEditingController();
  final _nameController = TextEditingController();
  final _caloriesController = TextEditingController();
  final _proteinController = TextEditingController();
  final _carbsController = TextEditingController();
  final _fatController = TextEditingController();
  final _imagePicker = ImagePicker();
  String? _selectedImagePath;

  @override
  void dispose() {
    for (final controller in [
      _textController,
      _hintController,
      _nameController,
      _caloriesController,
      _proteinController,
      _carbsController,
      _fatController,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    final image = await _imagePicker.pickImage(
      source: source,
      maxWidth: 1600,
      imageQuality: 75,
    );
    if (image == null) return;
    final file = File(image.path);
    if (!await file.exists()) return;
    if (await file.length() > 5 * 1024 * 1024) {
      ref.read(recordControllerProvider.notifier).showError('图片太大，请重新选择');
      return;
    }
    setState(() => _selectedImagePath = image.path);
    await ref.read(recordControllerProvider.notifier).analyzeImage(
          image.path,
          hint: _hintController.text,
        );
  }

  Future<void> _analyzeText() async {
    FocusScope.of(context).unfocus();
    await ref.read(recordControllerProvider.notifier).analyzeText(
          _textController.text,
          hint: _hintController.text,
        );
  }

  void _createManualDraft() {
    final name = _nameController.text.trim();
    final calories = num.tryParse(_caloriesController.text.trim());
    if (name.isEmpty || calories == null || calories <= 0) {
      _snack('请填写食物名称和大于 0 的卡路里');
      return;
    }
    ref.read(recordControllerProvider.notifier).loadManual(
          name: name,
          calories: calories,
          protein: _number(_proteinController.text),
          carbs: _number(_carbsController.text),
          fat: _number(_fatController.text),
        );
    _clearManual();
    _snack('已生成草稿，请确认份量和用餐人');
  }

  num _number(String value) => num.tryParse(value.trim()) ?? 0;

  Future<void> _saveDraft() async {
    final pairState = ref.read(pairControllerProvider);
    final hasPartner = pairState is PairConnected &&
        pairState.pair.partner != null;
    if (!hasPartner) {
      ref
          .read(recordControllerProvider.notifier)
          .setShareMode(MealShareMode.solo);
    }
    final ok = await ref.read(recordControllerProvider.notifier).save();
    if (!mounted) return;
    if (ok) {
      final imagePath = _selectedImagePath;
      if (imagePath != null) {
        final imageFile = File(imagePath);
        if (await imageFile.exists()) await imageFile.delete();
      }
      setState(() => _selectedImagePath = null);
      _snack('已记录');
      ref.read(homeTabIndexProvider.notifier).state = 0;
    }
  }

  void _loadFromMeal(Meal meal) {
    setState(() => _selectedImagePath = null);
    ref.read(recordControllerProvider.notifier).loadFromMeal(meal);
  }

  void _clearManual() {
    for (final controller in [
      _nameController,
      _caloriesController,
      _proteinController,
      _carbsController,
      _fatController,
    ]) {
      controller.clear();
    }
  }

  void _snack(String message) => ScaffoldMessenger.of(context)
      .showSnackBar(SnackBar(content: Text(message)));

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(recordControllerProvider);
    final yesterdayMeals = ref.watch(yesterdayMealsProvider);
    final pairState = ref.watch(pairControllerProvider);
    final partner = pairState is PairConnected ? pairState.pair.partner : null;
    final draft = switch (state) {
      RecordResult(:final draft) => draft,
      RecordError(:final draft) => draft,
      RecordAnalyzing(:final draft) => draft,
      _ => null,
    };
    final busy = state is RecordAnalyzing;
    final error = state is RecordError ? state.message : null;

    return Scaffold(
      appBar: AppBar(title: const Text('记录饮食')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.pagePadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('AI 识别', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
              const SizedBox(height: AppSpacing.xs),
              const Text('描述你吃了什么，或上传一张食物照片', style: TextStyle(color: AppColors.textSecondary)),
              const SizedBox(height: AppSpacing.sm),
              TextField(
                controller: _textController,
                minLines: 2,
                maxLines: 4,
                enabled: !busy,
                decoration: const InputDecoration(
                  hintText: '描述你吃了什么',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              TextField(
                controller: _hintController,
                enabled: !busy,
                decoration: const InputDecoration(
                  labelText: '补充说明（可选）',
                  hintText: '例如：米饭只有半碗',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  Expanded(child: OutlinedButton.icon(
                    onPressed: busy ? null : _analyzeText,
                    icon: const Icon(Icons.auto_awesome_outlined),
                    label: Text(busy ? '识别中…' : 'AI 估算'),
                  )),
                  const SizedBox(width: AppSpacing.sm),
                  IconButton.filledTonal(
                    tooltip: '拍照识别',
                    onPressed: busy ? null : () => _pickImage(ImageSource.camera),
                    icon: const Icon(Icons.camera_alt_outlined),
                  ),
                  IconButton.filledTonal(
                    tooltip: '从相册选择',
                    onPressed: busy ? null : () => _pickImage(ImageSource.gallery),
                    icon: const Icon(Icons.photo_library_outlined),
                  ),
                ],
              ),
              if (error != null) ...[
                const SizedBox(height: AppSpacing.sm),
                Text(error, style: const TextStyle(color: AppColors.warning)),
              ],
              const SizedBox(height: AppSpacing.lg),
              _YesterdayReuseSection(
                meals: yesterdayMeals,
                enabled: !busy,
                onSelected: _loadFromMeal,
              ),
              if (draft != null) ...[
                const SizedBox(height: AppSpacing.lg),
                _ResultPanel(
                  draft: draft,
                  imagePath: _selectedImagePath ?? draft.localImagePath,
                  busy: busy,
                  onPortion: (ratio) => ref.read(recordControllerProvider.notifier).setPortion(ratio),
                  onShareMode: (mode) => ref.read(recordControllerProvider.notifier).setShareMode(mode),
                  partnerName: partner?.displayName,
                  onEdit: () => _showEditDialog(draft),
                  onRefine: draft.source == MealSource.text ||
                          draft.localImagePath != null
                      ? () => _showRefineDialog()
                      : null,
                  onSave: _saveDraft,
                  onRetake: () => _pickImage(ImageSource.camera),
                  onReselect: () => _pickImage(ImageSource.gallery),
                ),
              ],
              const SizedBox(height: AppSpacing.xl),
              const Divider(),
              const SizedBox(height: AppSpacing.lg),
              const Text('手动记录', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
              const SizedBox(height: AppSpacing.md),
              _field('食物名称', _nameController, '例如：鸡胸肉沙拉'),
              _field('卡路里', _caloriesController, '千卡', numeric: true),
              _field('蛋白质 (Protein)', _proteinController, '克', numeric: true),
              _field('碳水 (Carbs)', _carbsController, '克', numeric: true),
              _field('脂肪 (Fat)', _fatController, '克', numeric: true),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: busy ? null : _createManualDraft,
                  child: const Text('生成记录预览'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _field(String label, TextEditingController controller, String hint, {bool numeric = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: TextField(
        controller: controller,
        keyboardType: numeric ? const TextInputType.numberWithOptions(decimal: true) : null,
        decoration: InputDecoration(labelText: label, hintText: hint),
      ),
    );
  }

  Future<void> _showRefineDialog() async {
    final controller = TextEditingController();
    final note = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('补充说明重新估算'),
        content: TextField(controller: controller, autofocus: true, decoration: const InputDecoration(hintText: '例如：米饭实际只有半碗')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('取消')),
          FilledButton(onPressed: () => Navigator.pop(context, controller.text), child: const Text('重新估算')),
        ],
      ),
    );
    controller.dispose();
    if (note != null && mounted) await ref.read(recordControllerProvider.notifier).refine(note);
  }

  Future<void> _showEditDialog(RecordDraft draft) async {
    _nameController.text = draft.name;
    _caloriesController.text = '${draft.baseCalories}';
    _proteinController.text = '${draft.baseProtein}';
    _carbsController.text = '${draft.baseCarbs}';
    _fatController.text = '${draft.baseFat}';
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('直接修改'),
        content: SingleChildScrollView(child: Column(children: [
          _dialogField('名称', _nameController),
          _dialogField('卡路里', _caloriesController),
          _dialogField('蛋白质', _proteinController),
          _dialogField('碳水', _carbsController),
          _dialogField('脂肪', _fatController),
        ])),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('取消')),
          FilledButton(onPressed: () {
            ref.read(recordControllerProvider.notifier).applyEdit(
              name: _nameController.text,
              calories: _number(_caloriesController.text),
              protein: _number(_proteinController.text),
              carbs: _number(_carbsController.text),
              fat: _number(_fatController.text),
            );
            Navigator.pop(context);
          }, child: const Text('保存修改')),
        ],
      ),
    );
  }

  Widget _dialogField(String label, TextEditingController controller) => Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.sm),
        child: TextField(controller: controller, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: InputDecoration(labelText: label)),
      );
}

class _YesterdayReuseSection extends StatelessWidget {
  const _YesterdayReuseSection({
    required this.meals,
    required this.enabled,
    required this.onSelected,
  });

  final AsyncValue<List<Meal>> meals;
  final bool enabled;
  final ValueChanged<Meal> onSelected;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '昨天也吃了？',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: AppSpacing.sm),
        meals.when(
          loading: () => const LinearProgressIndicator(minHeight: 2),
          error: (_, _) => const Text(
            '昨天的记录暂时无法加载',
            style: TextStyle(
              fontSize: 12,
              color: AppColors.textTertiary,
            ),
          ),
          data: (values) {
            final visible = values.take(3).toList(growable: false);
            if (visible.isEmpty) {
              return const Text(
                '昨天没有可复用的记录',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textTertiary,
                ),
              );
            }
            return AppCard(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.xs,
              ),
              child: Column(
                children: [
                  for (var index = 0; index < visible.length; index++) ...[
                    ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      title: Text(visible[index].name),
                      trailing: Text(
                        '${visible[index].calories.round()} kcal',
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      onTap: enabled ? () => onSelected(visible[index]) : null,
                    ),
                    if (index != visible.length - 1)
                      const Divider(height: 1, color: AppColors.border),
                  ],
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}

class _ResultPanel extends StatelessWidget {
  const _ResultPanel({
    required this.draft,
    required this.imagePath,
    required this.busy,
    required this.onPortion,
    required this.onShareMode,
    required this.partnerName,
    required this.onEdit,
    required this.onRefine,
    required this.onSave,
    required this.onRetake,
    required this.onReselect,
  });

  final RecordDraft draft;
  final String? imagePath;
  final bool busy;
  final ValueChanged<double> onPortion;
  final ValueChanged<MealShareMode> onShareMode;
  final String? partnerName;
  final VoidCallback onEdit;
  final VoidCallback? onRefine;
  final VoidCallback onSave;
  final VoidCallback onRetake;
  final VoidCallback onReselect;

  @override
  Widget build(BuildContext context) {
    final effectiveShareMode =
        partnerName == null ? MealShareMode.solo : draft.shareMode;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (imagePath != null) ...[
            ClipRRect(borderRadius: BorderRadius.circular(8), child: Image.file(File(imagePath!), height: 180, width: double.infinity, fit: BoxFit.cover)),
            Row(children: [TextButton.icon(onPressed: busy ? null : onRetake, icon: const Icon(Icons.camera_alt_outlined), label: const Text('重新拍摄')), TextButton.icon(onPressed: busy ? null : onReselect, icon: const Icon(Icons.photo_library_outlined), label: const Text('重新选择'))]),
          ],
          Text(draft.source == MealSource.manual ? '手动记录草稿' : 'AI 估算结果', style: const TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: AppSpacing.sm),
          Text(draft.name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
          Text('${_value(draft.calories)} kcal'),
          const SizedBox(height: AppSpacing.xs),
          Text('P ${_value(draft.protein)}g    C ${_value(draft.carbs)}g    F ${_value(draft.fat)}g'),
          const SizedBox(height: AppSpacing.md),
          const Text('份量'),
          Wrap(spacing: 6, children: <double>[0.5, 0.75, 1, 1.25, 1.5, 2].map((ratio) => ChoiceChip(label: Text('${ratio}x'), selected: draft.portionRatio == ratio, onSelected: (_) => onPortion(ratio))).toList()),
          const SizedBox(height: AppSpacing.md),
          const Text('这餐是谁吃的？', style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              ChoiceChip(
                label: const Text('我吃'),
                selected: effectiveShareMode == MealShareMode.solo,
                onSelected: busy ? null : (_) => onShareMode(MealShareMode.solo),
              ),
              if (partnerName != null) ...[
                ChoiceChip(
                  label: const Text('Ta 吃'),
                  selected: draft.shareMode == MealShareMode.partnerOnly,
                  onSelected: busy ? null : (_) => onShareMode(MealShareMode.partnerOnly),
                ),
                ChoiceChip(
                  label: const Text('一起吃'),
                  selected: draft.shareMode.isShared,
                  onSelected: busy ? null : (_) => onShareMode(MealShareMode.sharedHalf),
                ),
              ],
            ],
          ),
          if (partnerName != null && effectiveShareMode.isShared) ...[
            const SizedBox(height: AppSpacing.sm),
            const Text('怎么分？', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
            Wrap(
              spacing: AppSpacing.sm,
              children: [
                ChoiceChip(
                  label: const Text('1 : 1'),
                  selected: draft.shareMode == MealShareMode.sharedHalf,
                  onSelected: busy ? null : (_) => onShareMode(MealShareMode.sharedHalf),
                ),
                ChoiceChip(
                  label: const Text('我 1 / Ta 2'),
                  selected: draft.shareMode == MealShareMode.sharedMeOneThird,
                  onSelected: busy ? null : (_) => onShareMode(MealShareMode.sharedMeOneThird),
                ),
                ChoiceChip(
                  label: const Text('我 2 / Ta 1'),
                  selected: draft.shareMode == MealShareMode.sharedMeTwoThirds,
                  onSelected: busy ? null : (_) => onShareMode(MealShareMode.sharedMeTwoThirds),
                ),
              ],
            ),
          ],
          const SizedBox(height: AppSpacing.sm),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Text(
              '分配预览：我 ${_value(draft.calories * effectiveShareMode.meRatio)} kcal'
              '${partnerName == null ? '' : '  $partnerName ${_value(draft.calories * effectiveShareMode.partnerRatio)} kcal'}',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          if (draft.dishes.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            const Text('明细', style: TextStyle(fontWeight: FontWeight.w600)),
            ...draft.scaledDishes.map((dish) => Text('${dish.name}${dish.calories == null ? '' : ' ${_value(dish.calories!)} kcal'}')),
            Text('菜品：${draft.dishes.map((dish) => dish.name).join('、')}'),
          ],
          if (draft.source != MealSource.manual) ...[
            const SizedBox(height: AppSpacing.sm),
            const Text(
              'AI 估算，仅供参考',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.md),
          Wrap(spacing: 8, runSpacing: 8, children: [
            OutlinedButton(onPressed: busy ? null : onEdit, child: const Text('直接修改')),
            if (onRefine != null)
              OutlinedButton(onPressed: busy ? null : onRefine, child: const Text('补充说明重新估算')),
            FilledButton(onPressed: busy ? null : onSave, child: const Text('记录这一餐')),
          ]),
        ],
      ),
    );
  }

  static String _value(num value) => value % 1 == 0 ? value.toInt().toString() : value.toStringAsFixed(1);
}
