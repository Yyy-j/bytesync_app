import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../app/home_shell.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../pair/domain/pair_state.dart';
import '../../../pair/presentation/pair_controller.dart';
import '../../domain/meal.dart';
import '../../domain/meal_share_mode.dart';
import '../../domain/meal_source.dart';
import '../domain/record_draft.dart';
import '../domain/record_state.dart';
import 'record_controller.dart';

final selectedRecordImagePathProvider = StateProvider.autoDispose<String?>(
  (ref) => null,
);

class RecordPage extends ConsumerStatefulWidget {
  const RecordPage({super.key, this.imagePicker});

  final ImagePicker? imagePicker;

  @override
  ConsumerState<RecordPage> createState() => _RecordPageState();
}

class _LoadingView extends StatelessWidget {
  const _LoadingView({required this.kind});

  final RecordAnalysisKind kind;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = theme.brightness == Brightness.dark
        ? AppColors.darkPrimary
        : AppColors.primary;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 42,
            height: 42,
            child: CircularProgressIndicator(color: accent, strokeWidth: 3),
          ),
          const SizedBox(height: 28),
          Text(
            kind == RecordAnalysisKind.text ? '查询中…' : '识别中…',
            style: TextStyle(
              color: accent,
              fontSize: 24,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            '正在估算这份料理',
            style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

class _ManualForm extends StatelessWidget {
  const _ManualForm({
    required this.nameController,
    required this.caloriesController,
    required this.proteinController,
    required this.carbsController,
    required this.fatController,
    required this.onGenerate,
  });

  final TextEditingController nameController;
  final TextEditingController caloriesController;
  final TextEditingController proteinController;
  final TextEditingController carbsController;
  final TextEditingController fatController;
  final VoidCallback onGenerate;

  @override
  Widget build(BuildContext context) => Column(
    key: const ValueKey('record-manual-form'),
    children: [
      _field('食物名称', nameController, '手动记录'),
      _field('卡路里 *', caloriesController, '千卡', numeric: true),
      _field('蛋白质', proteinController, '0 克', numeric: true),
      _field('碳水化合物', carbsController, '0 克', numeric: true),
      _field('脂肪', fatController, '0 克', numeric: true),
      const SizedBox(height: 4),
      SizedBox(
        width: double.infinity,
        child: FilledButton(onPressed: onGenerate, child: const Text('生成记录')),
      ),
    ],
  );

  Widget _field(
    String label,
    TextEditingController controller,
    String hint, {
    bool numeric = false,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: TextField(
      controller: controller,
      keyboardType: numeric
          ? const TextInputType.numberWithOptions(decimal: true)
          : null,
      decoration: InputDecoration(labelText: label, hintText: hint),
    ),
  );
}

class _YesterdaySection extends StatelessWidget {
  const _YesterdaySection({required this.meals, required this.onSelected});

  final AsyncValue<List<Meal>> meals;
  final ValueChanged<Meal> onSelected;

  @override
  Widget build(BuildContext context) => meals.maybeWhen(
    data: (values) {
      final visible = values.take(3).toList(growable: false);
      if (visible.isEmpty) return const SizedBox.shrink();
      final theme = Theme.of(context);
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '昨天也吃了？',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 10),
          Container(
            decoration: BoxDecoration(
              color: theme.brightness == Brightness.dark
                  ? AppColors.darkCard
                  : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: theme.dividerColor),
            ),
            child: Column(
              children: [
                for (var index = 0; index < visible.length; index++) ...[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 13, 10, 13),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            visible[index].name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          '${_value(visible[index].calories)} kcal',
                          style: TextStyle(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(width: 8),
                        TextButton(
                          onPressed: () => onSelected(visible[index]),
                          child: const Text('添加'),
                        ),
                      ],
                    ),
                  ),
                  if (index != visible.length - 1)
                    Divider(height: 1, color: theme.dividerColor),
                ],
              ],
            ),
          ),
        ],
      );
    },
    orElse: () => const SizedBox.shrink(),
  );
}

class _ResultView extends StatelessWidget {
  const _ResultView({
    required this.draft,
    required this.imagePath,
    required this.partnerName,
    required this.saving,
    required this.onPortion,
    required this.onShareMode,
    required this.onEdit,
    required this.onRefine,
    required this.onSave,
    required this.onRetake,
    required this.onReselect,
    this.error,
  });

  final RecordDraft draft;
  final String? imagePath;
  final String? partnerName;
  final bool saving;
  final String? error;
  final ValueChanged<double> onPortion;
  final ValueChanged<MealShareMode> onShareMode;
  final VoidCallback onEdit;
  final VoidCallback? onRefine;
  final VoidCallback onSave;
  final VoidCallback onRetake;
  final VoidCallback onReselect;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final accent = isDark ? AppColors.darkPrimary : AppColors.primary;
    final effectiveShareMode = partnerName == null
        ? MealShareMode.solo
        : draft.shareMode;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 30, 20, 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '识别结果',
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 18),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkCard : Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: accent.withValues(alpha: 0.18)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (imagePath != null && File(imagePath!).existsSync()) ...[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.file(
                      File(imagePath!),
                      height: 190,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                Text(
                  draft.name,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${_value(draft.calories)} kcal',
                  style: TextStyle(
                    color: accent,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '蛋白质 ${_value(draft.protein)}g  ·  '
                  '碳水 ${_value(draft.carbs)}g  ·  '
                  '脂肪 ${_value(draft.fat)}g',
                ),
                if (draft.dishes.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  Text('菜品：${draft.dishes.map((dish) => dish.name).join('、')}'),
                ],
                if (draft.source != MealSource.manual) ...[
                  const SizedBox(height: 12),
                  Text(
                    'AI 估算，仅供参考',
                    style: TextStyle(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontSize: 12,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (error != null) ...[
            const SizedBox(height: 10),
            Text(error!, style: TextStyle(color: theme.colorScheme.error)),
          ],
          const SizedBox(height: 18),
          Row(
            children: [
              if (onRefine != null)
                Expanded(
                  child: OutlinedButton(
                    onPressed: onRefine,
                    child: const Text('补充说明再识别'),
                  ),
                ),
              if (onRefine != null) const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton(
                  onPressed: onEdit,
                  child: const Text('手动改数据'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),
          const Text(
            '吃了多少？',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 10),
          _ChoiceRow<double>(
            choices: const [
              (1, '全部'),
              (0.5, '1/2'),
              (2 / 3, '2/3'),
              (1 / 3, '1/3'),
            ],
            selected: draft.portionRatio,
            onSelected: onPortion,
          ),
          const SizedBox(height: 30),
          const Text(
            '这顿要同步给 Ta 吗？',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 10),
          if (partnerName == null)
            _ChoiceRow<MealShareMode>(
              choices: const [(MealShareMode.solo, '只记录给我')],
              selected: MealShareMode.solo,
              onSelected: onShareMode,
            )
          else ...[
            _ChoiceRow<MealShareMode>(
              choices: const [
                (MealShareMode.solo, '只记录给我'),
                (MealShareMode.partnerOnly, '只给 Ta 记'),
                (MealShareMode.sharedHalf, '一起吃'),
              ],
              selected: effectiveShareMode.isShared
                  ? MealShareMode.sharedHalf
                  : effectiveShareMode,
              onSelected: onShareMode,
            ),
            if (effectiveShareMode.isShared) ...[
              const SizedBox(height: 12),
              _ChoiceRow<MealShareMode>(
                choices: const [
                  (MealShareMode.sharedHalf, '一人一半'),
                  (MealShareMode.sharedMeOneThird, '我 1/3 · Ta 2/3'),
                  (MealShareMode.sharedMeTwoThirds, '我 2/3 · Ta 1/3'),
                ],
                selected: effectiveShareMode,
                onSelected: onShareMode,
              ),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  '分配预览：我 ${_value(draft.calories * effectiveShareMode.meRatio)} kcal  '
                  '$partnerName ${_value(draft.calories * effectiveShareMode.partnerRatio)} kcal',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ],
          const SizedBox(height: 30),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              key: const ValueKey('record-save-button'),
              onPressed: saving ? null : onSave,
              style: FilledButton.styleFrom(
                backgroundColor: accent,
                foregroundColor: isDark ? Colors.black : Colors.white,
                minimumSize: const Size.fromHeight(52),
              ),
              child: Text(saving ? '记录中…' : '记录这一餐'),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextButton(onPressed: onRetake, child: const Text('重新拍摄')),
              const SizedBox(width: 8),
              TextButton(onPressed: onReselect, child: const Text('重新选择')),
            ],
          ),
        ],
      ),
    );
  }
}

class _ChoiceRow<T> extends StatelessWidget {
  const _ChoiceRow({
    required this.choices,
    required this.selected,
    required this.onSelected,
  });

  final List<(T, String)> choices;
  final T selected;
  final ValueChanged<T> onSelected;

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: 8,
    runSpacing: 8,
    children: choices
        .map(
          (choice) => ChoiceChip(
            label: Text(choice.$2),
            selected: selected == choice.$1,
            onSelected: (_) => onSelected(choice.$1),
          ),
        )
        .toList(growable: false),
  );
}

String _value(num value) =>
    value % 1 == 0 ? value.toInt().toString() : value.toStringAsFixed(1);

class _RecordPageState extends ConsumerState<RecordPage> {
  final _inputController = TextEditingController();
  final _nameController = TextEditingController();
  final _caloriesController = TextEditingController();
  final _proteinController = TextEditingController();
  final _carbsController = TextEditingController();
  final _fatController = TextEditingController();
  late final ImagePicker _imagePicker;
  bool _manualExpanded = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _imagePicker = widget.imagePicker ?? ImagePicker();
    _inputController.addListener(_refreshInputState);
  }

  void _refreshInputState() => setState(() {});

  @override
  void dispose() {
    _inputController.removeListener(_refreshInputState);
    for (final controller in [
      _inputController,
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

  Future<void> _showImageSourceSheet() async {
    FocusScope.of(context).unfocus();
    final source = await showCupertinoModalPopup<ImageSource>(
      context: context,
      builder: (context) => CupertinoActionSheet(
        title: const Text('拍一餐'),
        actions: [
          CupertinoActionSheetAction(
            onPressed: () => Navigator.pop(context, ImageSource.camera),
            child: const Text('拍照'),
          ),
          CupertinoActionSheetAction(
            onPressed: () => Navigator.pop(context, ImageSource.gallery),
            child: const Text('从相册选择'),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          isDefaultAction: true,
          onPressed: () => Navigator.pop(context),
          child: const Text('取消'),
        ),
      ),
    );
    if (source != null && mounted) await _pickImage(source);
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
    ref.read(selectedRecordImagePathProvider.notifier).state = image.path;
    final hint = _inputController.text.trim();
    await ref
        .read(recordControllerProvider.notifier)
        .analyzeImage(image.path, hint: hint.isEmpty ? null : hint);
  }

  Future<void> _analyzeText() async {
    final text = _inputController.text.trim();
    if (text.isEmpty) return;
    FocusScope.of(context).unfocus();
    ref.read(selectedRecordImagePathProvider.notifier).state = null;
    final success = await ref
        .read(recordControllerProvider.notifier)
        .analyzeText(text);
    if (success && mounted) _inputController.clear();
  }

  void _createManualDraft() {
    final calories = num.tryParse(_caloriesController.text.trim());
    if (calories == null || calories <= 0) {
      _snack('请填写大于 0 的卡路里');
      return;
    }
    ref.read(selectedRecordImagePathProvider.notifier).state = null;
    ref
        .read(recordControllerProvider.notifier)
        .loadManual(
          name: _nameController.text.trim().isEmpty
              ? '手动记录'
              : _nameController.text.trim(),
          calories: calories,
          protein: _number(_proteinController.text),
          carbs: _number(_carbsController.text),
          fat: _number(_fatController.text),
        );
    _clearManual();
    setState(() => _manualExpanded = false);
  }

  void _fillManualFromMeal(Meal meal) {
    _nameController.text = meal.name;
    _caloriesController.text = _value(meal.calories);
    _proteinController.text = _value(meal.protein);
    _carbsController.text = _value(meal.carbs);
    _fatController.text = _value(meal.fat);
    setState(() => _manualExpanded = true);
    _snack('已填入昨天的记录，可修改后生成');
  }

  num _number(String value) => num.tryParse(value.trim()) ?? 0;

  Future<void> _saveDraft() async {
    if (_saving) return;
    setState(() => _saving = true);
    final pairState = ref.read(pairControllerProvider);
    final hasPartner =
        pairState is PairConnected && pairState.pair.partner != null;
    if (!hasPartner) {
      ref
          .read(recordControllerProvider.notifier)
          .setShareMode(MealShareMode.solo);
    }
    final ok = await ref.read(recordControllerProvider.notifier).save();
    if (!mounted) return;
    setState(() => _saving = false);
    if (ok) {
      ref.read(selectedRecordImagePathProvider.notifier).state = null;
      _snack('已记录');
      ref.read(homeTabIndexProvider.notifier).state = 0;
    }
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

  void _snack(String message) =>
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(recordControllerProvider);
    final pairState = ref.watch(pairControllerProvider);
    final partner = pairState is PairConnected ? pairState.pair.partner : null;
    final selectedImagePath = ref.watch(selectedRecordImagePathProvider);

    return Scaffold(
      body: SafeArea(
        child: switch (state) {
          RecordAnalyzing(:final kind) => _LoadingView(kind: kind),
          RecordResult(:final draft) => _resultView(
            draft,
            selectedImagePath ?? draft.localImagePath,
            partner?.displayName,
          ),
          RecordError(:final draft, :final message) when draft != null =>
            _resultView(
              draft,
              selectedImagePath ?? draft.localImagePath,
              partner?.displayName,
              error: message,
            ),
          RecordError(:final message) => _buildIdle(error: message),
          RecordIdle() => _buildIdle(),
        },
      ),
    );
  }

  Widget _resultView(
    RecordDraft draft,
    String? imagePath,
    String? partnerName, {
    String? error,
  }) => _ResultView(
    draft: draft,
    imagePath: imagePath,
    partnerName: partnerName,
    saving: _saving,
    error: error,
    onPortion: (ratio) =>
        ref.read(recordControllerProvider.notifier).setPortion(ratio),
    onShareMode: (mode) =>
        ref.read(recordControllerProvider.notifier).setShareMode(mode),
    onEdit: () => _showEditDialog(draft),
    onRefine: draft.source == MealSource.text || draft.localImagePath != null
        ? _showRefineDialog
        : null,
    onSave: _saveDraft,
    onRetake: () => _pickImage(ImageSource.camera),
    onReselect: () => _pickImage(ImageSource.gallery),
  );

  Widget _buildIdle({String? error}) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final accent = isDark ? AppColors.darkPrimary : AppColors.primary;
    final inputFilled = _inputController.text.trim().isNotEmpty;
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: FocusScope.of(context).unfocus,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 34, 24, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '拍一餐',
              style: TextStyle(fontSize: 30, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            Text(
              '饭前拍一下，轻轻记录这一餐',
              style: TextStyle(
                fontSize: 15,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 46),
            Row(
              children: [
                Expanded(
                  child: Container(
                    height: 56,
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppColors.darkInput
                          : AppColors.primary.withValues(alpha: 0.055),
                      borderRadius: BorderRadius.circular(17),
                      border: Border.all(color: accent.withValues(alpha: 0.32)),
                    ),
                    alignment: Alignment.center,
                    child: TextField(
                      key: const ValueKey('record-unified-input'),
                      controller: _inputController,
                      maxLines: 1,
                      textInputAction: TextInputAction.send,
                      onSubmitted: inputFilled ? (_) => _analyzeText() : null,
                      decoration: const InputDecoration(
                        hintText: '描述食物，或拍照前补充说明',
                        filled: false,
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(horizontal: 16),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Opacity(
                  opacity: inputFilled ? 1 : 0.32,
                  child: Semantics(
                    button: true,
                    enabled: inputFilled,
                    label: '发送文字描述',
                    child: IconButton(
                      key: const ValueKey('record-send-button'),
                      onPressed: inputFilled ? _analyzeText : null,
                      style: IconButton.styleFrom(
                        fixedSize: const Size(50, 50),
                        padding: const EdgeInsets.all(13),
                        backgroundColor: accent.withValues(alpha: 0.12),
                        shape: const CircleBorder(),
                      ),
                      icon: SvgPicture.asset(
                        isDark ? 'svg/send-blue.svg' : 'svg/send-green.svg',
                        key: ValueKey(
                          isDark
                              ? 'record-send-blue-svg'
                              : 'record-send-green-svg',
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            if (error != null) ...[
              const SizedBox(height: 10),
              Text(
                error,
                key: const ValueKey('record-idle-error'),
                style: TextStyle(color: theme.colorScheme.error, fontSize: 13),
              ),
            ],
            const SizedBox(height: 52),
            Center(
              child: Column(
                children: [
                  InkWell(
                    key: const ValueKey('record-camera-button'),
                    onTap: _showImageSourceSheet,
                    customBorder: const CircleBorder(),
                    child: SizedBox(
                      width: 108,
                      height: 108,
                      child: SvgPicture.asset(
                        isDark ? 'svg/add-blue.svg' : 'svg/add-green.svg',
                        key: ValueKey(
                          isDark
                              ? 'record-add-blue-svg'
                              : 'record-add-green-svg',
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    '拍一餐',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 46),
            Center(
              child: TextButton(
                key: const ValueKey('record-manual-toggle'),
                onPressed: () =>
                    setState(() => _manualExpanded = !_manualExpanded),
                child: Text(_manualExpanded ? '收起' : '手动记录一餐'),
              ),
            ),
            AnimatedSize(
              duration: const Duration(milliseconds: 180),
              alignment: Alignment.topCenter,
              child: _manualExpanded
                  ? _ManualForm(
                      nameController: _nameController,
                      caloriesController: _caloriesController,
                      proteinController: _proteinController,
                      carbsController: _carbsController,
                      fatController: _fatController,
                      onGenerate: _createManualDraft,
                    )
                  : const SizedBox.shrink(),
            ),
            const SizedBox(height: 28),
            _YesterdaySection(
              meals: ref.watch(yesterdayMealsProvider),
              onSelected: _fillManualFromMeal,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showRefineDialog() async {
    final controller = TextEditingController();
    final note = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('补充说明再识别'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(hintText: '例如：米饭实际只有半碗'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('重新识别'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (note != null && mounted) {
      await ref.read(recordControllerProvider.notifier).refine(note);
    }
  }

  Future<void> _showEditDialog(RecordDraft draft) async {
    final name = TextEditingController(text: draft.name);
    final calories = TextEditingController(text: _value(draft.baseCalories));
    final protein = TextEditingController(text: _value(draft.baseProtein));
    final carbs = TextEditingController(text: _value(draft.baseCarbs));
    final fat = TextEditingController(text: _value(draft.baseFat));
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('手动改数据'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _dialogField('名称', name, numeric: false),
              _dialogField('卡路里', calories),
              _dialogField('蛋白质', protein),
              _dialogField('碳水化合物', carbs),
              _dialogField('脂肪', fat),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () {
              ref
                  .read(recordControllerProvider.notifier)
                  .applyEdit(
                    name: name.text,
                    calories: _number(calories.text),
                    protein: _number(protein.text),
                    carbs: _number(carbs.text),
                    fat: _number(fat.text),
                  );
              Navigator.pop(context);
            },
            child: const Text('保存修改'),
          ),
        ],
      ),
    );
    name.dispose();
    calories.dispose();
    protein.dispose();
    carbs.dispose();
    fat.dispose();
  }

  Widget _dialogField(
    String label,
    TextEditingController controller, {
    bool numeric = true,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: TextField(
      controller: controller,
      keyboardType: numeric
          ? const TextInputType.numberWithOptions(decimal: true)
          : null,
      decoration: InputDecoration(labelText: label),
    ),
  );
}
