import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bytesync/features/auth/domain/auth_state.dart';
import 'package:bytesync/features/auth/domain/auth_user.dart';
import 'package:bytesync/features/auth/presentation/auth_controller.dart';
import 'package:bytesync/features/meals/data/meal_ai_repository.dart';
import 'package:bytesync/features/meals/data/meals_providers.dart';
import 'package:bytesync/features/meals/data/meals_repository.dart';
import 'package:bytesync/features/meals/domain/meal.dart';
import 'package:bytesync/features/meals/domain/meal_ai_result.dart';
import 'package:bytesync/features/meals/domain/meal_patch.dart';
import 'package:bytesync/features/meals/domain/meal_share_mode.dart';
import 'package:bytesync/features/meals/domain/meal_source.dart';
import 'package:bytesync/features/meals/domain/reusable_meal_item.dart';
import 'package:bytesync/features/meals/presentation/meal_management_controller.dart';
import 'package:bytesync/features/pair/data/dto/pair_dto.dart';
import 'package:bytesync/features/pair/data/mappers/pair_mapper.dart';
import 'package:bytesync/features/pair/domain/pair.dart';
import 'package:bytesync/features/pair/domain/pair_state.dart';
import 'package:bytesync/features/pair/presentation/pair_controller.dart';
import 'package:bytesync/features/profile/domain/user_character.dart';
import 'package:bytesync/features/summary/data/summary_providers.dart';
import 'package:bytesync/features/summary/data/summary_repository.dart';
import 'package:bytesync/features/summary/domain/daily_summary.dart';
import 'package:bytesync/features/summary/presentation/summary_controller.dart';

final _user = AuthUser(
  id: 'user-1',
  provider: 'google',
  onboardingCompletedAt: DateTime(2026, 9, 27),
  email: 'one@example.com',
);

class _FixedAuthController extends AuthController {
  @override
  AuthState build() => AuthAuthenticated(_user);
}

class _MutablePairController extends PairController {
  _MutablePairController(this.initial);

  final PairState initial;

  @override
  PairState build() => initial;

  void setPairState(PairState next) => state = next;
}

class _CountingSummaryController extends SummaryController {
  int refreshCount = 0;

  @override
  SummaryState build() =>
      SummaryLoaded(DailySummary.empty(DateTime(2026, 9, 27)));

  @override
  Future<void> refresh() async => refreshCount++;
}

class _FakeSummaryRepository implements SummaryRepository {
  int dailyCalls = 0;
  int monthlyCalls = 0;

  @override
  Future<DailySummary> getDailySummary(DateTime date) async {
    dailyCalls++;
    return DailySummary.empty(date);
  }

  @override
  Future<MonthlySummary> getMonthlySummary(DateTime month) async {
    monthlyCalls++;
    return MonthlySummary.fromJson({
      'month': '${month.year}-${month.month.toString().padLeft(2, '0')}',
      'self': {'calorie_goal': 2000},
      'partner': null,
      'days': [],
    });
  }
}

class _FakeMealsRepository implements MealsRepository {
  int updateCalls = 0;
  int deleteCalls = 0;

  @override
  Future<Meal> updateMeal(String id, MealPatch patch) async {
    updateCalls++;
    return _meal(pairId: 'pair-C');
  }

  @override
  Future<void> deleteMeal(String id) async => deleteCalls++;

  @override
  Future<Meal> addMeal(NewMealInput input) => throw UnimplementedError();

  @override
  Future<Meal> getMealById(String id) => throw UnimplementedError();

  @override
  Future<List<Meal>> getMealsForDate(DateTime date) =>
      throw UnimplementedError();

  @override
  Future<List<ReusableMealItem>> getMealsForReuse({
    required DateTime date,
    int limit = 5,
  }) => throw UnimplementedError();

  @override
  Future<ReusableMealItem> favoriteMeal(String mealId) =>
      throw UnimplementedError();

  @override
  Future<void> unfavoriteMeal(String favoriteId) => throw UnimplementedError();

  @override
  Future<List<Meal>> getRecentMealsForReuse({int limit = 3}) =>
      throw UnimplementedError();
}

class _FakeMealAiRepository implements MealAiRepository {
  int calls = 0;

  @override
  Future<MealAiResult> analyzeText(String text) async {
    calls++;
    return const MealAiResult(
      name: '更新后的饭',
      calories: 500,
      protein: 30,
      carbs: 50,
      fat: 10,
      dishes: [],
    );
  }
}

Pair _pair(String id, {String inviteCode = 'CODE'}) => Pair(
  pairId: id,
  inviteCode: inviteCode,
  members: const [
    PairMember(userId: 'user-1', displayName: 'Me', isSelf: true),
    PairMember(userId: 'user-2', displayName: 'HH', isSelf: false),
  ],
  createdAt: DateTime(2026, 9, 1),
  connectedAt: DateTime(2026, 9, 2),
);

Meal _meal({String? pairId, MealSource source = MealSource.text}) => Meal(
  id: 'meal-1',
  pairId: pairId,
  userId: 'user-1',
  sharedMealId: null,
  name: '鸡肉饭',
  source: source,
  baseCalories: 800,
  baseProtein: 45,
  baseCarbs: 90,
  baseFat: 20,
  calories: 400,
  protein: 22.5,
  carbs: 45,
  fat: 10,
  portionRatio: 1,
  shareRatio: 0.5,
  shareMode: MealShareMode.sharedHalf,
  mealDate: DateTime(2026, 9, 27),
  mealTime: '12:30',
  createdAt: DateTime(2026, 9, 27, 3),
  updatedAt: DateTime(2026, 9, 27, 4),
);

Future<void> _settleScope() =>
    Future<void>.delayed(const Duration(milliseconds: 10));

void main() {
  test('Pair character maps girl and boy through DTO and mapper', () {
    final dto = PairDto.fromJson({
      'pair_id': 'pair-1',
      'invite_code': 'ABC123',
      'created_at': '2026-09-01T00:00:00Z',
      'connected_at': '2026-09-02T00:00:00Z',
      'ended_at': null,
      'members': [
        {'user_id': 'user-1', 'display_name': 'Me', 'character': 'boy'},
        {'user_id': 'user-2', 'display_name': 'HH', 'character': 'girl'},
      ],
    });

    final pair = PairMapper.fromDto(dto, currentUserId: 'user-1');

    expect(pair.currentMember?.character, UserCharacter.boy);
    expect(pair.partner?.character, UserCharacter.girl);
  });

  test('Summary refreshes only when connected Pair scope changes', () async {
    final repository = _FakeSummaryRepository();
    final pairController = _MutablePairController(const PairInitial());
    final container = ProviderContainer(
      overrides: [
        authControllerProvider.overrideWith(_FixedAuthController.new),
        pairControllerProvider.overrideWith(() => pairController),
        summaryRepositoryProvider.overrideWithValue(repository),
      ],
    );
    addTearDown(container.dispose);

    container.read(summaryControllerProvider);
    await _settleScope();
    final initialDaily = repository.dailyCalls;
    final initialMonthly = repository.monthlyCalls;

    pairController.setPairState(
      PairConnected(
        Pair(
          pairId: 'pending',
          inviteCode: 'PENDING',
          members: const [
            PairMember(userId: 'user-1', displayName: 'Me', isSelf: true),
          ],
          createdAt: DateTime(2026, 9, 1),
        ),
      ),
    );
    await _settleScope();
    expect(repository.dailyCalls, initialDaily);
    expect(repository.monthlyCalls, initialMonthly);

    pairController.setPairState(PairConnected(_pair('pair-A')));
    await _settleScope();
    expect(repository.dailyCalls, initialDaily + 1);
    expect(repository.monthlyCalls, initialMonthly + 1);

    pairController.setPairState(
      PairConnected(_pair('pair-A', inviteCode: 'CHANGED')),
    );
    await _settleScope();
    expect(repository.dailyCalls, initialDaily + 1);
    expect(repository.monthlyCalls, initialMonthly + 1);

    pairController.setPairState(const PairNotFound());
    await _settleScope();
    expect(repository.dailyCalls, initialDaily + 2);
    expect(repository.monthlyCalls, initialMonthly + 2);

    pairController.setPairState(PairConnected(_pair('pair-B')));
    await _settleScope();
    expect(repository.dailyCalls, initialDaily + 3);
    expect(repository.monthlyCalls, initialMonthly + 3);
  });

  test('historical Pair Meal blocks update, delete, and refine', () async {
    final meals = _FakeMealsRepository();
    final ai = _FakeMealAiRepository();
    final pairController = _MutablePairController(
      PairConnected(_pair('pair-C')),
    );
    final summary = _CountingSummaryController();
    final container = ProviderContainer(
      overrides: [
        pairControllerProvider.overrideWith(() => pairController),
        mealsRepositoryProvider.overrideWithValue(meals),
        mealAiRepositoryProvider.overrideWithValue(ai),
        summaryControllerProvider.overrideWith(() => summary),
      ],
    );
    addTearDown(container.dispose);
    container.read(pairControllerProvider);
    final controller = container.read(
      mealManagementControllerProvider.notifier,
    );
    final historical = _meal(pairId: 'pair-B');

    final update = await controller.updateMeal(
      historical,
      const MealPatch(name: '不应更新'),
    );
    final delete = await controller.deleteMeal(historical);
    final refine = await controller.refineMeal(historical, '不应重新估算');

    for (final result in [update, delete, refine]) {
      expect(result.isSuccess, isFalse);
      expect(result.message, '历史配对记录仅供查看');
    }
    expect(meals.updateCalls, 0);
    expect(meals.deleteCalls, 0);
    expect(ai.calls, 0);
    expect(summary.refreshCount, 0);
  });

  test('current Pair Meal and personal Meal remain editable', () async {
    final meals = _FakeMealsRepository();
    final ai = _FakeMealAiRepository();
    final pairController = _MutablePairController(
      PairConnected(_pair('pair-C')),
    );
    final summary = _CountingSummaryController();
    final container = ProviderContainer(
      overrides: [
        pairControllerProvider.overrideWith(() => pairController),
        mealsRepositoryProvider.overrideWithValue(meals),
        mealAiRepositoryProvider.overrideWithValue(ai),
        summaryControllerProvider.overrideWith(() => summary),
      ],
    );
    addTearDown(container.dispose);
    container.read(pairControllerProvider);
    final controller = container.read(
      mealManagementControllerProvider.notifier,
    );

    expect(
      (await controller.updateMeal(
        _meal(pairId: 'pair-C'),
        const MealPatch(name: '当前配对'),
      )).isSuccess,
      isTrue,
    );
    expect(
      (await controller.deleteMeal(_meal(pairId: 'pair-C'))).isSuccess,
      isTrue,
    );
    expect(
      (await controller.updateMeal(
        _meal(),
        const MealPatch(name: '个人'),
      )).isSuccess,
      isTrue,
    );
    expect(meals.updateCalls, 2);
    expect(meals.deleteCalls, 1);
  });
}
