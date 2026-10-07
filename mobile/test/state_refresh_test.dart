import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bytesync/features/profile/data/user_providers.dart';
import 'package:bytesync/features/profile/data/user_repository.dart';
import 'package:bytesync/features/profile/domain/user_character.dart';
import 'package:bytesync/features/profile/domain/user_profile.dart';
import 'package:bytesync/features/profile/presentation/nutrition_goals_controller.dart';
import 'package:bytesync/features/profile/presentation/profile_controller.dart';
import 'package:bytesync/features/summary/domain/daily_summary.dart';
import 'package:bytesync/features/summary/presentation/summary_controller.dart';

const _initialGoals = NutritionGoals(
  calories: 2000,
  protein: 90,
  carbs: 250,
  fat: 60,
);

class _FakeUserRepository implements UserRepository {
  UserProfile profile = const UserProfile(
    id: 'user-1',
    email: 'one@example.test',
    provider: 'google',
    displayName: 'One',
    goals: _initialGoals,
  );
  int profileReads = 0;

  @override
  Future<UserProfile> getProfile() async {
    profileReads++;
    return profile;
  }

  @override
  Future<UserProfile> updateNutritionGoals(NutritionGoals goals) async {
    profile = UserProfile(
      id: profile.id,
      email: profile.email,
      provider: profile.provider,
      displayName: profile.displayName,
      goals: goals,
      character: profile.character,
    );
    return profile;
  }

  @override
  Future<UserProfile> updateCharacter(UserCharacter character) =>
      throw UnimplementedError();

  @override
  Future<UserProfile> updateProfile({
    required String? displayName,
    int? birthYear,
    String? sexForEnergyEstimate,
    double? heightCm,
    double? targetWeightKg,
    DateTime? targetDate,
    String? activityLevel,
  }) => throw UnimplementedError();
}

class _CountingSummaryController extends SummaryController {
  int refreshCount = 0;

  @override
  SummaryState build() =>
      SummaryLoaded(DailySummary.empty(DateTime(2026, 10, 7)));

  @override
  Future<void> refresh() async => refreshCount++;
}

void main() {
  test(
    'nutrition mutation refreshes existing Profile and Summary only',
    () async {
      final repository = _FakeUserRepository();
      final summary = _CountingSummaryController();
      final container = ProviderContainer(
        overrides: [
          userRepositoryProvider.overrideWithValue(repository),
          summaryControllerProvider.overrideWith(() => summary),
        ],
      );
      addTearDown(container.dispose);

      final profileSubscription = container.listen(
        profileControllerProvider,
        (_, _) {},
        fireImmediately: true,
      );
      final nutritionSubscription = container.listen(
        nutritionGoalsControllerProvider,
        (_, _) {},
        fireImmediately: true,
      );
      addTearDown(profileSubscription.close);
      addTearDown(nutritionSubscription.close);
      await Future<void>.delayed(const Duration(milliseconds: 10));

      const updated = NutritionGoals(
        calories: 1800,
        protein: 110,
        carbs: 210,
        fat: 55,
      );
      final result = await container
          .read(nutritionGoalsControllerProvider.notifier)
          .save(updated);

      expect(result.isSuccess, isTrue);
      expect(summary.refreshCount, 1);
      expect(repository.profileReads, 3);
      final profile = container.read(profileControllerProvider) as ProfileReady;
      expect(profile.profile.goals.calories, 1800);
      expect(profile.profile.goals.protein, 110);
    },
  );
}
