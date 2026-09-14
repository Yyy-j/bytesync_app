import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_exception.dart';
import '../../../summary/presentation/summary_controller.dart';
import '../../data/meal_ai_repository.dart';
import '../../data/meals_providers.dart';
import '../../data/meals_repository.dart';
import '../../domain/meal.dart';
import '../../domain/meal_ai_result.dart';
import '../../domain/meal_patch.dart';
import '../../domain/meal_share_mode.dart';
import '../../domain/meal_source.dart';
import '../domain/record_draft.dart';
import '../domain/record_state.dart';

final recordControllerProvider =
    NotifierProvider.autoDispose<RecordController, RecordState>(RecordController.new);

final yesterdayMealsProvider = FutureProvider.autoDispose<List<Meal>>((ref) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  return ref
      .watch(mealsRepositoryProvider)
      .getMealsForReuse(
        date: today.subtract(const Duration(days: 1)),
        limit: 3,
      );
});

class RecordController extends AutoDisposeNotifier<RecordState> {
  late final MealAiRepository _aiRepository;
  late final MealsRepository _mealsRepository;

  @override
  RecordState build() {
    _aiRepository = ref.watch(mealAiRepositoryProvider);
    _mealsRepository = ref.watch(mealsRepositoryProvider);
    return const RecordIdle();
  }

  Future<bool> analyze(String text) => analyzeText(text);

  Future<bool> analyzeText(String text, {String? hint}) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return false;
    state = const RecordAnalyzing();
    try {
      final result = await _aiRepository.analyzeText(_combine(trimmed, hint));
      state = RecordResult(RecordDraft.fromAi(
        result: result,
        source: MealSource.text,
        originalText: trimmed,
        hint: hint,
      ));
      return true;
    } catch (error) {
      state = RecordError(_messageFor(error));
      return false;
    }
  }

  Future<bool> analyzeImage(String path, {String? hint}) async {
    state = const RecordAnalyzing();
    try {
      final imageRepository = _aiRepository;
      if (imageRepository is! MealImageAiRepository) {
        state = const RecordError('图片识别暂不可用');
        return false;
      }
      final result = await (imageRepository as MealImageAiRepository)
          .analyzeImage(path, hint: hint);
      state = RecordResult(RecordDraft.fromAi(
        result: result,
        source: MealSource.ai,
        hint: hint,
        localImagePath: path,
      ));
      return true;
    } catch (error) {
      state = RecordError(_messageFor(error));
      return false;
    }
  }

  Future<bool> refine(String note) async {
    final current = _draft;
    final trimmed = note.trim();
    if (current == null || trimmed.isEmpty) return false;
    state = RecordAnalyzing(current);
    try {
      final result = current.source == MealSource.text
          ? await _aiRepository.analyzeText(_combine(current.originalText ?? current.name, trimmed))
          : await (_aiRepository as MealImageAiRepository).analyzeImage(current.localImagePath!, hint: _combine(current.hint, trimmed));
      state = RecordResult(
        RecordDraft.fromAi(
          result: result,
          source: current.source,
          originalText: current.originalText,
          hint: _combine(current.hint, trimmed),
          localImagePath: current.localImagePath,
        ).copyWith(shareMode: current.shareMode),
      );
      return true;
    } catch (error) {
      state = RecordError(_messageFor(error), draft: current);
      return false;
    }
  }

  void setPortion(double ratio) {
    final current = _draft;
    if (current != null) state = RecordResult(current.copyWith(portionRatio: ratio));
  }

  void setShareMode(MealShareMode shareMode) {
    final current = _draft;
    if (current != null) {
      state = RecordResult(current.copyWith(shareMode: shareMode));
    }
  }

  void loadManual({
    required String name,
    required num calories,
    required num protein,
    required num carbs,
    required num fat,
  }) {
    state = RecordResult(
      RecordDraft(
        name: name,
        baseCalories: calories,
        baseProtein: protein,
        baseCarbs: carbs,
        baseFat: fat,
        dishes: const [],
        source: MealSource.manual,
      ),
    );
  }

  void loadFromMeal(Meal meal) {
    state = RecordResult(
      RecordDraft(
        name: meal.name,
        baseCalories: meal.baseCalories,
        baseProtein: meal.baseProtein,
        baseCarbs: meal.baseCarbs,
        baseFat: meal.baseFat,
        dishes: meal.dishes,
        source: meal.source,
        originalText: meal.originalInput,
        hint: meal.aiHint,
        portionRatio: meal.portionRatio,
        shareMode: meal.shareMode,
      ),
    );
  }

  void applyEdit({required String name, required num calories, required num protein, required num carbs, required num fat}) {
    final current = _draft;
    if (current == null) return;
    state = RecordResult(current.copyWith(
      name: name.trim().isEmpty ? current.name : name.trim(),
      baseCalories: calories,
      baseProtein: protein,
      baseCarbs: carbs,
      baseFat: fat,
      portionRatio: 1,
    ));
  }

  Future<bool> save() async {
    final current = _draft;
    if (current == null) return false;
    try {
      await _mealsRepository.addMeal(NewMealInput(
        name: current.name,
        source: current.source,
        baseCalories: current.baseCalories,
        baseProtein: current.baseProtein,
        baseCarbs: current.baseCarbs,
        baseFat: current.baseFat,
        portionRatio: current.portionRatio,
        shareMode: current.shareMode,
        mealTime: _mealTime,
        dishes: current.dishes,
        aiHint: current.hint,
        originalInput: current.originalText,
      ));
      await ref.read(summaryControllerProvider.notifier).refresh();
      clear();
      return true;
    } catch (error) {
      state = RecordError(_messageFor(error), draft: current);
      return false;
    }
  }

  void clear() => state = const RecordIdle();

  void showError(String message) => state = RecordError(message, draft: _draft);

  RecordDraft? get _draft => switch (state) {
        RecordResult(:final draft) => draft,
        RecordError(:final draft) => draft,
        RecordAnalyzing(:final draft) => draft,
        _ => null,
      };

  String get _mealTime {
    final now = DateTime.now();
    return '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
  }

  String _combine(String? first, String? second) => [first, second]
      .whereType<String>()
      .map((value) => value.trim())
      .where((value) => value.isNotEmpty)
      .join('；');

  String _messageFor(Object error) {
    if (error is NetworkException) return '网络连接失败，请检查网络';
    if (error is ApiException && error.statusCode == 413) return '图片太大，请重新选择';
    if (error is ApiException && error.statusCode == 415) return '暂不支持这张图片格式';
    if (error is ApiException && error.statusCode == 503) return 'AI 服务暂时不可用，请稍后重试';
    if (error is ApiException && error.statusCode == 502) return '识别失败，请重新尝试';
    if (error is ServerException) return 'AI 服务暂时不可用，请稍后重试';
    return 'AI 估算失败，请稍后重试';
  }
}

extension RecordStateCompatibility on RecordResult {
  MealAiResult get result => MealAiResult(
        name: draft.name,
        calories: draft.baseCalories,
        protein: draft.baseProtein,
        carbs: draft.baseCarbs,
        fat: draft.baseFat,
        dishes: draft.dishes.map((dish) => dish.name).toList(growable: false),
      );
}
