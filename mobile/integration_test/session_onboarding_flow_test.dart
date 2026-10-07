import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:bytesync/app/app.dart';
import 'package:bytesync/app/home_shell.dart';
import 'package:bytesync/core/network/api_exception.dart';
import 'package:bytesync/core/providers/core_providers.dart';
import 'package:bytesync/features/auth/data/auth_providers.dart';
import 'package:bytesync/features/auth/data/auth_repository.dart';
import 'package:bytesync/features/auth/domain/auth_user.dart';
import 'package:bytesync/features/auth/presentation/auth_controller.dart';
import 'package:bytesync/features/body/data/body_providers.dart';
import 'package:bytesync/features/body/data/body_repository.dart';
import 'package:bytesync/features/body/domain/body_data.dart';
import 'package:bytesync/features/pair/data/pair_providers.dart';
import 'package:bytesync/features/pair/data/pair_repository.dart';
import 'package:bytesync/features/pair/domain/pair.dart';
import 'package:bytesync/features/profile/domain/user_profile.dart';

const _incompleteUser = AuthUser(
  id: 'new-user',
  provider: 'google',
  email: 'new@example.test',
);

final _completedUser = AuthUser(
  id: 'new-user',
  provider: 'google',
  email: 'new@example.test',
  onboardingCompletedAt: DateTime.utc(2026, 10, 7),
);

class _LifecycleAuthRepository implements AuthRepository {
  int transientRestoreFailures = 1;
  bool onboardingComplete = false;

  AuthUser get currentUser =>
      onboardingComplete ? _completedUser : _incompleteUser;

  @override
  Future<AuthUser?> restoreSession() async {
    if (transientRestoreFailures > 0) {
      transientRestoreFailures--;
      throw NetworkException('网络暂时不可用，请重试');
    }
    return currentUser;
  }

  @override
  Future<AuthUser> getCurrentUser() async => currentUser;

  @override
  Future<AuthUser> signInWithGoogle() async => currentUser;

  @override
  Future<void> signOut() async {}

  @override
  Future<void> deleteAccount() async {}
}

class _NoPairRepository implements PairRepository {
  @override
  Future<Pair?> getCurrentPair() async => null;

  @override
  Future<void> cancelPair() => throw UnimplementedError();

  @override
  Future<Pair> createPair() => throw UnimplementedError();

  @override
  Future<void> endPair() => throw UnimplementedError();

  @override
  Future<Pair> joinPair({required String inviteCode}) =>
      throw UnimplementedError();

  @override
  Future<Pair> regenerateInviteCode() => throw UnimplementedError();
}

class _OnboardingBodyRepository implements BodyRepository {
  _OnboardingBodyRepository(this.auth);

  final _LifecycleAuthRepository auth;
  int completionCalls = 0;

  @override
  Future<OnboardingResult> completeOnboarding(
    BodyInput input,
    NutritionGoals goals,
  ) async {
    completionCalls++;
    auth.onboardingComplete = true;
    return OnboardingResult(
      onboardingCompletedAt: _completedUser.onboardingCompletedAt!,
      birthYear: input.birthYear,
      sexForEnergyEstimate: input.sexForEnergyEstimate,
      heightCm: input.heightCm,
      targetWeightKg: input.targetWeightKg,
      targetDate: input.targetDate,
      activityLevel: input.activityLevel,
      goals: goals,
      currentWeight: WeightMeasurement(
        id: 'weight-1',
        measuredOn: DateTime.utc(2026, 10, 7),
        weightKg: input.currentWeightKg,
        bmi: 22.9,
      ),
    );
  }

  @override
  Future<BodyData> getBody() => throw UnimplementedError();

  @override
  Future<List<WeightMeasurement>> getWeights({int limit = 30}) =>
      throw UnimplementedError();

  @override
  Future<WeightMeasurement> createWeight({
    required DateTime measuredOn,
    required double weightKg,
  }) => throw UnimplementedError();

  @override
  Future<void> deleteWeight(String id) => throw UnimplementedError();

  @override
  Future<CalorieRecommendation> recommend(BodyInput input) =>
      throw UnimplementedError();

  @override
  Future<WeightMeasurement> updateWeight(
    String id, {
    required DateTime measuredOn,
    required double weightKg,
  }) => throw UnimplementedError();
}

List<Override> _overrides(
  _LifecycleAuthRepository auth,
  _OnboardingBodyRepository body,
) => [
  authRepositoryProvider.overrideWithValue(auth),
  bodyRepositoryProvider.overrideWithValue(body),
  pairRepositoryProvider.overrideWithValue(_NoPairRepository()),
];

Future<void> _pumpRoute(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 100));
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('restore retry -> onboarding -> Home -> relaunch -> 401 Login', (
    tester,
  ) async {
    final auth = _LifecycleAuthRepository();
    final body = _OnboardingBodyRepository(auth);
    var container = ProviderContainer(overrides: _overrides(auth, body));

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const BiteSyncApp(),
      ),
    );
    await _pumpRoute(tester);

    expect(find.text('网络暂时不可用，请重试'), findsOneWidget);
    expect(find.text('重试'), findsOneWidget);
    expect(auth.onboardingComplete, isFalse);

    await tester.tap(find.text('重试'));
    await _pumpRoute(tester);
    expect(find.text('开始使用 BiteSync'), findsOneWidget);

    await container
        .read(bodyRepositoryProvider)
        .completeOnboarding(
          BodyInput(
            birthYear: 1995,
            sexForEnergyEstimate: 'female',
            heightCm: 165,
            currentWeightKg: 62,
            targetWeightKg: 58,
            targetDate: DateTime.utc(2027, 1, 7),
            activityLevel: 'moderate',
          ),
          const NutritionGoals(
            calories: 1800,
            protein: 110,
            carbs: 210,
            fat: 55,
          ),
        );
    await container.read(authControllerProvider.notifier).refreshCurrentUser();
    await _pumpRoute(tester);
    expect(body.completionCalls, 1);
    expect(find.byType(HomeShell), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    container.dispose();
    container = ProviderContainer(overrides: _overrides(auth, body));
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const BiteSyncApp(),
      ),
    );
    await _pumpRoute(tester);
    expect(find.byType(HomeShell), findsOneWidget);
    expect(find.text('开始使用 BiteSync'), findsNothing);

    container.read(authEventBusProvider).emitUnauthorized();
    await _pumpRoute(tester);
    expect(find.text('使用 Google 登录'), findsOneWidget);
  });
}
