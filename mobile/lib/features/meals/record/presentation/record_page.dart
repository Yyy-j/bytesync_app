import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:image_picker/image_picker.dart';
import 'package:bytesync/l10n/l10n.dart';

import '../../../../app/home_shell.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/bitesync_bottom_sheet.dart';
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
          SizedBox(height: 28),
          Text(
            kind == RecordAnalysisKind.text
                ? appL10n.recordQuerying
                : appL10n.recordRecognizing,
            style: TextStyle(
              color: accent,
              fontSize: 24,
              fontWeight: FontWeight.w800,
            ),
          ),
          SizedBox(height: 10),
          Text(
            appL10n.recordEstimating,
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
    key: ValueKey('record-manual-form'),
    children: [
      _field(appL10n.recordFoodName, nameController, appL10n.recordManual),
      _field(
        appL10n.recordCaloriesRequired,
        caloriesController,
        appL10n.recordKilocaloriesHint,
        numeric: true,
      ),
      _field(
        appL10n.commonProtein,
        proteinController,
        appL10n.recordZeroGrams,
        numeric: true,
      ),
      _field(
        appL10n.recordCarbohydrates,
        carbsController,
        appL10n.recordZeroGrams,
        numeric: true,
      ),
      _field(
        appL10n.commonFat,
        fatController,
        appL10n.recordZeroGrams,
        numeric: true,
      ),
      SizedBox(height: 4),
      SizedBox(
        width: double.infinity,
        child: FilledButton(
          onPressed: onGenerate,
          child: Text(appL10n.recordGenerate),
        ),
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
          Text(
            appL10n.recordYesterdayPrompt,
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 10),
          for (var index = 0; index < visible.length; index++) ...[
            InkWell(
              onTap: () => onSelected(visible[index]),
              borderRadius: BorderRadius.circular(10),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
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
                      appL10n.commonCaloriesValue(
                        _value(visible[index].calories),
                      ),
                      style: TextStyle(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    IconButton(
                      tooltip: appL10n.recordAdd,
                      onPressed: () => onSelected(visible[index]),
                      icon: const Icon(Icons.add, size: 20),
                    ),
                  ],
                ),
              ),
            ),
            if (index != visible.length - 1)
              Divider(height: 1, color: theme.dividerColor),
          ],
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
      padding: EdgeInsets.fromLTRB(20, 30, 20, 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            draft.source == MealSource.manual
                ? appL10n.recordManual
                : appL10n.recordRecognitionComplete,
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800),
          ),
          SizedBox(height: 18),
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(18),
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
                  SizedBox(height: 16),
                ],
                Text(
                  draft.name,
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
                ),
                SizedBox(height: 8),
                Text(
                  appL10n.commonCaloriesValue(_value(draft.calories)),
                  style: TextStyle(
                    color: accent,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  appL10n.recordMacroSummary(
                    _value(draft.protein),
                    _value(draft.carbs),
                    _value(draft.fat),
                  ),
                ),
                if (draft.dishes.isNotEmpty) ...[
                  SizedBox(height: 14),
                  Text(
                    appL10n.recordDishes(
                      draft.dishes
                          .map((dish) => dish.name)
                          .join(appL10n.commonListSeparator),
                    ),
                  ),
                ],
                if (draft.source != MealSource.manual) ...[
                  SizedBox(height: 12),
                  Text(
                    appL10n.recordAiDisclaimer,
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
            SizedBox(height: 10),
            Text(error!, style: TextStyle(color: theme.colorScheme.error)),
          ],
          SizedBox(height: 18),
          Row(
            children: [
              if (onRefine != null)
                Expanded(
                  child: OutlinedButton(
                    onPressed: onRefine,
                    child: Text(appL10n.recordRecognizeWithNote),
                  ),
                ),
              if (onRefine != null) SizedBox(width: 10),
              Expanded(
                child: OutlinedButton(
                  onPressed: onEdit,
                  child: Text(appL10n.recordEditData),
                ),
              ),
            ],
          ),
          SizedBox(height: 28),
          Text(
            appL10n.recordAmountQuestion,
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          SizedBox(height: 10),
          _ChoiceRow<double>(
            choices: [
              (1, appL10n.commonAll),
              (0.5, appL10n.recordPortionHalf),
              (2 / 3, appL10n.recordPortionTwoThirds),
              (1 / 3, appL10n.recordPortionOneThird),
            ],
            selected: draft.portionRatio,
            onSelected: onPortion,
          ),
          SizedBox(height: 30),
          Text(
            appL10n.recordShareQuestion,
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          SizedBox(height: 10),
          if (partnerName == null)
            _ChoiceRow<MealShareMode>(
              choices: [(MealShareMode.solo, appL10n.recordShareSolo)],
              selected: MealShareMode.solo,
              onSelected: onShareMode,
            )
          else ...[
            _ChoiceRow<MealShareMode>(
              choices: [
                (MealShareMode.solo, appL10n.recordShareSolo),
                (MealShareMode.partnerOnly, appL10n.recordSharePartnerOnly),
                (MealShareMode.sharedHalf, appL10n.recordShareTogether),
              ],
              selected: effectiveShareMode.isShared
                  ? MealShareMode.sharedHalf
                  : effectiveShareMode,
              onSelected: onShareMode,
            ),
            if (effectiveShareMode.isShared) ...[
              SizedBox(height: 12),
              _ChoiceRow<MealShareMode>(
                choices: [
                  (MealShareMode.sharedHalf, appL10n.recordShareHalf),
                  (
                    MealShareMode.sharedMeOneThird,
                    appL10n.recordShareMeOneThird,
                  ),
                  (
                    MealShareMode.sharedMeTwoThirds,
                    appL10n.recordShareMeTwoThirds,
                  ),
                ],
                selected: effectiveShareMode,
                onSelected: onShareMode,
              ),
              SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  appL10n.recordSharePreview(
                    _value(draft.calories * effectiveShareMode.meRatio),
                    partnerName!,
                    _value(draft.calories * effectiveShareMode.partnerRatio),
                  ),
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ],
          SizedBox(height: 30),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              key: ValueKey('record-save-button'),
              onPressed: saving ? null : onSave,
              style: FilledButton.styleFrom(
                backgroundColor: accent,
                foregroundColor: isDark ? Colors.black : Colors.white,
                minimumSize: Size.fromHeight(52),
              ),
              child: Text(
                saving ? appL10n.recordSaving : appL10n.recordThisMeal,
              ),
            ),
          ),
          SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextButton(
                onPressed: onRetake,
                child: Text(appL10n.recordRetake),
              ),
              SizedBox(width: 8),
              TextButton(
                onPressed: onReselect,
                child: Text(appL10n.recordReselect),
              ),
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

class _CameraSection extends StatelessWidget {
  const _CameraSection({
    required this.onCamera,
    required this.onManual,
    required this.onGallery,
  });

  final VoidCallback onCamera;
  final VoidCallback onManual;
  final VoidCallback onGallery;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 30, 24, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          InkWell(
            key: const ValueKey('record-camera-button'),
            onTap: onCamera,
            customBorder: const CircleBorder(),
            child: SizedBox(
              width: 108,
              height: 108,
              child: SvgPicture.asset(
                isDark ? 'svg/add-blue.svg' : 'svg/add-green.svg',
                key: ValueKey(
                  isDark ? 'record-add-blue-svg' : 'record-add-green-svg',
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            appL10n.recordTakeMeal,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextButton.icon(
                key: const ValueKey('record-manual-toggle'),
                onPressed: onManual,
                icon: const Icon(Icons.edit_outlined, size: 18),
                label: Text(appL10n.recordManualMeal),
              ),
              TextButton.icon(
                key: const ValueKey('record-gallery-button'),
                onPressed: onGallery,
                icon: const Icon(Icons.photo_library_outlined, size: 18),
                label: Text(appL10n.recordChooseGallery),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RecordHeaderDelegate extends SliverPersistentHeaderDelegate {
  _RecordHeaderDelegate({
    required this.controller,
    required this.inputFilled,
    required this.error,
    required this.showCameraShortcut,
    required this.onSubmit,
    required this.onCamera,
  });

  final TextEditingController controller;
  final bool inputFilled;
  final String? error;
  final bool showCameraShortcut;
  final VoidCallback onSubmit;
  final VoidCallback onCamera;

  bool get hasError => error != null;

  @override
  double get minExtent => hasError ? 104 : 80;

  @override
  double get maxExtent => hasError ? 192 : 170;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    final progress = (shrinkOffset / (maxExtent - minExtent)).clamp(0.0, 1.0);
    return _RecordIdleHeader(
      controller: controller,
      inputFilled: inputFilled,
      error: error,
      collapseProgress: progress,
      showCameraShortcut: showCameraShortcut,
      onSubmit: onSubmit,
      onCamera: onCamera,
    );
  }

  @override
  bool shouldRebuild(covariant _RecordHeaderDelegate oldDelegate) {
    return controller != oldDelegate.controller ||
        inputFilled != oldDelegate.inputFilled ||
        error != oldDelegate.error ||
        showCameraShortcut != oldDelegate.showCameraShortcut;
  }
}

class _RecordIdleHeader extends StatelessWidget {
  const _RecordIdleHeader({
    required this.controller,
    required this.inputFilled,
    required this.error,
    required this.collapseProgress,
    required this.showCameraShortcut,
    required this.onSubmit,
    required this.onCamera,
  });

  final TextEditingController controller;
  final bool inputFilled;
  final String? error;
  final double collapseProgress;
  final bool showCameraShortcut;
  final VoidCallback onSubmit;
  final VoidCallback onCamera;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final accent = isDark ? AppColors.darkPrimary : AppColors.primary;
    final titleOpacity = 1 - collapseProgress;
    final titleHeight = 62 * titleOpacity;
    final inputGap = 14 - (8 * collapseProgress);
    final dividerOpacity = 0.02 + (0.18 * collapseProgress);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        border: Border(
          bottom: BorderSide(
            color: theme.dividerColor.withValues(alpha: dividerOpacity),
          ),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 10),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            SizedBox(
              height: titleHeight,
              child: ClipRect(
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: Opacity(
                    opacity: titleOpacity,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          appL10n.recordTakeMeal,
                          style: const TextStyle(
                            fontSize: 30,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          appL10n.recordHeroSubtitle,
                          style: TextStyle(
                            fontSize: 15,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            SizedBox(height: inputGap),
            Row(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  curve: Curves.easeOutCubic,
                  width: showCameraShortcut ? 40 : 0,
                  child: ClipRect(
                    child: AnimatedOpacity(
                      duration: const Duration(milliseconds: 180),
                      opacity: showCameraShortcut ? 1 : 0,
                      child: IconButton(
                        key: const ValueKey('record-camera-shortcut'),
                        tooltip: appL10n.recordTakeMeal,
                        onPressed: onCamera,
                        icon: const Icon(Icons.camera_alt_outlined),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: Container(
                    height: 56,
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppColors.darkInput
                          : AppColors.primary.withValues(alpha: 0.055),
                      borderRadius: BorderRadius.circular(17),
                      border: Border.all(
                        color: accent.withValues(alpha: 0.32),
                      ),
                    ),
                    alignment: Alignment.center,
                    child: TextField(
                      key: const ValueKey('record-unified-input'),
                      controller: controller,
                      maxLines: 1,
                      maxLength: 80,
                      textInputAction: TextInputAction.send,
                      onSubmitted: inputFilled ? (_) => onSubmit() : null,
                      decoration: InputDecoration(
                        hintText: appL10n.recordDescriptionHint,
                        counterText: '',
                        filled: false,
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                        ),
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
                    label: appL10n.recordSendDescription,
                    child: IconButton(
                      key: const ValueKey('record-send-button'),
                      onPressed: inputFilled ? onSubmit : null,
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
            if (error != null)
              SizedBox(
                height: 22,
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    error!,
                    key: const ValueKey('record-idle-error'),
                    style: TextStyle(
                      color: theme.colorScheme.error,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _RecordPageState extends ConsumerState<RecordPage> {
  final _inputController = TextEditingController();
  final _nameController = TextEditingController();
  final _caloriesController = TextEditingController();
  final _proteinController = TextEditingController();
  final _carbsController = TextEditingController();
  final _fatController = TextEditingController();
  late final ScrollController _scrollController;
  late final ImagePicker _imagePicker;
  bool _showCameraShortcut = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _imagePicker = widget.imagePicker ?? ImagePicker();
    _scrollController = ScrollController()..addListener(_handleScroll);
    _inputController.addListener(_refreshInputState);
  }

  void _refreshInputState() => setState(() {});

  void _handleScroll() {
    if (!_scrollController.hasClients) return;
    final shouldShow = _scrollController.offset > 280;
    if (shouldShow != _showCameraShortcut && mounted) {
      setState(() => _showCameraShortcut = shouldShow);
    }
  }

  @override
  void dispose() {
    _inputController.removeListener(_refreshInputState);
    _scrollController
      ..removeListener(_handleScroll)
      ..dispose();
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
      builder: (context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
        child: CupertinoActionSheet(
          title: Text(appL10n.recordTakeMeal),
          actions: [
            CupertinoActionSheetAction(
              onPressed: () => Navigator.pop(context, ImageSource.camera),
              child: Text(appL10n.recordTakePhoto),
            ),
            CupertinoActionSheetAction(
              onPressed: () => Navigator.pop(context, ImageSource.gallery),
              child: Text(appL10n.recordChooseGallery),
            ),
          ],
          cancelButton: CupertinoActionSheetAction(
            isDefaultAction: true,
            onPressed: () => Navigator.pop(context),
            child: Text(appL10n.commonCancel),
          ),
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
      ref
          .read(recordControllerProvider.notifier)
          .showError(appL10n.recordImageTooLarge);
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

  bool _createManualDraft() {
    final calories = num.tryParse(_caloriesController.text.trim());
    if (calories == null || calories <= 0) {
      _snack(appL10n.recordCaloriesMustBePositive);
      return false;
    }
    ref.read(selectedRecordImagePathProvider.notifier).state = null;
    ref
        .read(recordControllerProvider.notifier)
        .loadManual(
          name: _nameController.text.trim().isEmpty
              ? appL10n.recordManual
              : _nameController.text.trim(),
          calories: calories,
          protein: _number(_proteinController.text),
          carbs: _number(_carbsController.text),
          fat: _number(_fatController.text),
        );
    _clearManual();
      return true;
  }

  void _fillManualFromMeal(Meal meal) {
    _nameController.text = meal.name;
    _caloriesController.text = _value(meal.calories);
    _proteinController.text = _value(meal.protein);
    _carbsController.text = _value(meal.carbs);
    _fatController.text = _value(meal.fat);
    _snack(appL10n.recordYesterdayFilled);
    _showManualSheet();
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
      _inputController.clear();
      _clearManual();
      _snack(appL10n.recordSaved);
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

  Future<void> _showManualSheet() async {
    await showBiteSyncModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.lg,
            AppSpacing.lg,
            MediaQuery.viewInsetsOf(sheetContext).bottom + AppSpacing.lg,
          ),
          child: _ManualForm(
            nameController: _nameController,
            caloriesController: _caloriesController,
            proteinController: _proteinController,
            carbsController: _carbsController,
            fatController: _fatController,
            onGenerate: () {
              if (_createManualDraft()) {
                Navigator.pop(sheetContext);
              }
            },
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(recordControllerProvider);
    final pairState = ref.watch(pairControllerProvider);
    final partner = pairState is PairConnected ? pairState.pair.partner : null;
    final selectedImagePath = ref.watch(selectedRecordImagePathProvider);

    return Scaffold(
      resizeToAvoidBottomInset: false,
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
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: FocusScope.of(context).unfocus,
      child: CustomScrollView(
        controller: _scrollController,
        slivers: [
          SliverPersistentHeader(
            pinned: true,
            delegate: _RecordHeaderDelegate(
              controller: _inputController,
              inputFilled: _inputController.text.trim().isNotEmpty,
              error: error,
              showCameraShortcut: _showCameraShortcut,
              onSubmit: _analyzeText,
              onCamera: _showImageSourceSheet,
            ),
          ),
          SliverToBoxAdapter(
            child: _CameraSection(
              onCamera: _showImageSourceSheet,
              onManual: _showManualSheet,
              onGallery: () => _pickImage(ImageSource.gallery),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 40),
              child: _YesterdaySection(
                meals: ref.watch(yesterdayMealsProvider),
                onSelected: _fillManualFromMeal,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showRefineDialog() async {
    final controller = TextEditingController();
    final note = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(appL10n.recordRecognizeWithNote),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(hintText: appL10n.recordCorrectionHint),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(appL10n.commonCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: Text(appL10n.recordRecognizeAgain),
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
        title: Text(appL10n.recordEditData),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _dialogField(appL10n.todayName, name, numeric: false),
              _dialogField(appL10n.todayBaseCalories, calories),
              _dialogField(appL10n.commonProtein, protein),
              _dialogField(appL10n.recordCarbohydrates, carbs),
              _dialogField(appL10n.commonFat, fat),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(appL10n.commonCancel),
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
            child: Text(appL10n.commonSaveChanges),
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
