import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'package:bytesync/features/auth/domain/auth_state.dart';
import 'package:bytesync/features/auth/domain/auth_user.dart';
import 'package:bytesync/features/auth/presentation/auth_controller.dart';
import 'package:bytesync/features/meals/domain/meal.dart';
import 'package:bytesync/features/meals/domain/meal_share_mode.dart';
import 'package:bytesync/features/meals/domain/meal_source.dart';
import 'package:bytesync/features/pair/domain/pair.dart';
import 'package:bytesync/features/pair/domain/pair_state.dart';
import 'package:bytesync/features/pair/presentation/pair_controller.dart';
import 'package:bytesync/features/pair/presentation/pairing_page.dart';
import 'package:bytesync/features/profile/domain/user_character.dart';
import 'package:bytesync/features/profile/domain/user_profile.dart';
import 'package:bytesync/features/profile/presentation/account_privacy_page.dart';
import 'package:bytesync/features/profile/presentation/profile_controller.dart';
import 'package:bytesync/features/profile/presentation/profile_page.dart';
import 'package:bytesync/features/summary/domain/daily_summary.dart';
import 'package:bytesync/features/summary/presentation/summary_controller.dart';
import 'package:bytesync/features/summary/presentation/summary_page.dart';

final _user = AuthUser(
  id: 'user-1',
  provider: 'google',
  onboardingCompletedAt: DateTime(2026, 9, 27),
  email: 'one@example.com',
);

class _TestAuthController extends AuthController {
  _TestAuthController({this.fail = false});

  final bool fail;
  int deleteCalls = 0;

  @override
  AuthState build() => AuthAuthenticated(_user);

  @override
  Future<void> deleteAccount() async {
    deleteCalls++;
    if (fail) throw Exception('delete failed');
    state = const AuthUnauthenticated();
  }
}

class _FixedPairController extends PairController {
  _FixedPairController(this.pairState);

  final PairState pairState;

  @override
  PairState build() => pairState;

  @override
  Future<void> refresh({bool showLoading = true}) async {}
}

class _FixedSummaryController extends SummaryController {
  _FixedSummaryController(this.summary);

  final DailySummary summary;

  @override
  SummaryState build() => SummaryLoaded(summary);
}

class _FixedProfileController extends ProfileController {
  @override
  ProfileState build() => ProfileReady(
    profile: UserProfile(
      id: 'user-1',
      email: 'one@example.com',
      provider: 'google',
      displayName: 'Me',
      goals: const NutritionGoals(
        calories: 2000,
        protein: 90,
        carbs: 250,
        fat: 60,
      ),
    ),
  );
}

Pair _connectedPair({
  String id = 'pair-C',
  UserCharacter partnerCharacter = UserCharacter.girl,
}) => Pair(
  pairId: id,
  inviteCode: 'ABC123',
  members: [
    const PairMember(userId: 'user-1', displayName: 'Me', isSelf: true),
    PairMember(
      userId: 'user-2',
      displayName: 'HH',
      isSelf: false,
      character: partnerCharacter,
    ),
  ],
  createdAt: DateTime(2026, 9, 1),
  connectedAt: DateTime(2026, 9, 2),
);

Meal _meal({String? pairId, String id = 'meal-1'}) => Meal(
  id: id,
  pairId: pairId,
  userId: 'user-1',
  sharedMealId: null,
  name: id,
  source: MealSource.text,
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

DailySummary _summaryWithMeal(Meal meal) => DailySummary(
  date: DateTime(2026, 9, 27),
  calories: meal.calories,
  protein: meal.protein,
  carbs: meal.carbs,
  fat: meal.fat,
  mealCount: 1,
  meals: [meal],
  selfSlice: const UserDailySlice(
    userId: 'user-1',
    displayName: 'Me',
    calories: 400,
    protein: 22.5,
    carbs: 45,
    fat: 10,
  ),
  partnerSlice: null,
  selfGoals: const DailyGoals(),
  partnerGoals: null,
);

Future<void> _pumpSummary(
  WidgetTester tester, {
  required PairState pairState,
  required Meal meal,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        pairControllerProvider.overrideWith(
          () => _FixedPairController(pairState),
        ),
        summaryControllerProvider.overrideWith(
          () => _FixedSummaryController(_summaryWithMeal(meal)),
        ),
      ],
      child: const MaterialApp(home: SummaryPage()),
    ),
  );
  await tester.pump(const Duration(milliseconds: 100));
  await tester.pump();
}

void main() {
  setUpAll(() async {
    await initializeDateFormatting('zh_CN');
  });

  testWidgets(
    'Connected Pair shows partner name, character asset, and status',
    (tester) async {
      final pair = _connectedPair(partnerCharacter: UserCharacter.girl);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            pairControllerProvider.overrideWith(
              () => _FixedPairController(PairConnected(pair)),
            ),
          ],
          child: const MaterialApp(home: PairingPage()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('HH'), findsOneWidget);
      expect(find.text('已完成配对'), findsOneWidget);
      expect(
        tester
            .widgetList<SvgPicture>(find.byType(SvgPicture))
            .any(
              (picture) =>
                  picture.bytesLoader is SvgAssetLoader &&
                  (picture.bytesLoader as SvgAssetLoader).assetName ==
                      UserCharacter.girl.bodyAsset,
            ),
        isTrue,
      );
    },
  );

  testWidgets(
    'historical Pair Meal remains visible but has no management entry',
    (tester) async {
      await _pumpSummary(
        tester,
        pairState: const PairNotFound(),
        meal: _meal(pairId: 'old-pair'),
      );

      expect(find.text('meal-1'), findsOneWidget);
      expect(find.text('历史配对记录仅供查看'), findsOneWidget);
      expect(find.byTooltip('管理meal-1'), findsNothing);
    },
  );

  testWidgets('new Pair does not manage an old Pair Meal', (tester) async {
    await _pumpSummary(
      tester,
      pairState: PairConnected(_connectedPair()),
      meal: _meal(pairId: 'pair-B'),
    );

    expect(find.text('meal-1'), findsOneWidget);
    expect(find.text('历史配对记录仅供查看'), findsOneWidget);
    expect(find.byTooltip('管理meal-1'), findsNothing);
  });

  testWidgets('current Pair Meal and personal Meal retain management entry', (
    tester,
  ) async {
    await _pumpSummary(
      tester,
      pairState: PairConnected(_connectedPair()),
      meal: _meal(pairId: 'pair-C'),
    );
    expect(find.byTooltip('管理meal-1'), findsOneWidget);
    expect(find.text('历史配对记录仅供查看'), findsNothing);

    await _pumpSummary(
      tester,
      pairState: const PairNotFound(),
      meal: _meal(pairId: null, id: 'personal-meal'),
    );
    expect(find.byTooltip('管理personal-meal'), findsOneWidget);
    expect(find.text('历史配对记录仅供查看'), findsNothing);
  });

  testWidgets(
    'Profile links to Account & Privacy and keeps delete off Profile',
    (tester) async {
      final router = GoRouter(
        initialLocation: '/profile',
        routes: [
          GoRoute(
            path: '/profile',
            builder: (context, state) => const ProfilePage(),
          ),
          GoRoute(
            path: '/account-privacy',
            builder: (context, state) => const AccountPrivacyPage(),
          ),
        ],
      );
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            profileControllerProvider.overrideWith(
              () => _FixedProfileController(),
            ),
            pairControllerProvider.overrideWith(
              () => _FixedPairController(const PairNotFound()),
            ),
          ],
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump();

      expect(find.text('账号与隐私'), findsOneWidget);
      expect(find.text('删除账号'), findsNothing);
      await tester.tap(find.text('账号与隐私'));
      await tester.pumpAndSettle();
      expect(router.state.uri.path, '/account-privacy');
      expect(find.byType(AccountPrivacyPage), findsOneWidget);
    },
  );

  testWidgets('Account & Privacy exposes all required entries', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: AccountPrivacyPage()));
    await tester.pump();

    expect(find.text('当前登录方式：Google'), findsOneWidget);
    expect(find.text('隐私政策'), findsOneWidget);
    expect(find.text('使用条款'), findsOneWidget);
    expect(find.text('AI 数据处理'), findsOneWidget);
    expect(find.text('账号数据'), findsOneWidget);
    expect(find.text('删除账号'), findsOneWidget);
  });

  testWidgets('delete confirmation cancel paths never call repository', (
    tester,
  ) async {
    final auth = _TestAuthController();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authControllerProvider.overrideWith(() => auth),
          pairControllerProvider.overrideWith(
            () => _FixedPairController(const PairNotFound()),
          ),
        ],
        child: const MaterialApp(home: AccountPrivacyPage()),
      ),
    );
    await tester.pump();

    await tester.tap(find.text('删除账号'));
    await tester.pump();
    await tester.tap(find.text('取消'));
    await tester.pump();
    expect(auth.deleteCalls, 0);

    await tester.tap(find.text('删除账号'));
    await tester.pump();
    await tester.tap(find.text('继续'));
    await tester.pump();
    await tester.tap(find.text('取消'));
    await tester.pump();
    expect(auth.deleteCalls, 0);
  });

  testWidgets('two confirmations delete account and become unauthenticated', (
    tester,
  ) async {
    final auth = _TestAuthController();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authControllerProvider.overrideWith(() => auth),
          pairControllerProvider.overrideWith(
            () => _FixedPairController(const PairNotFound()),
          ),
        ],
        child: const MaterialApp(home: AccountPrivacyPage()),
      ),
    );
    await tester.pump();

    await tester.tap(find.text('删除账号'));
    await tester.pump();
    await tester.tap(find.text('继续'));
    await tester.pump();
    await tester.tap(find.text('永久删除账号'));
    await tester.pump();

    expect(auth.deleteCalls, 1);
    expect(auth.state, isA<AuthUnauthenticated>());
  });

  testWidgets('Connected delete confirmation explains partner impact', (
    tester,
  ) async {
    final auth = _TestAuthController();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authControllerProvider.overrideWith(() => auth),
          pairControllerProvider.overrideWith(
            () => _FixedPairController(PairConnected(_connectedPair())),
          ),
        ],
        child: const MaterialApp(home: AccountPrivacyPage()),
      ),
    );
    await tester.pump();

    await tester.tap(find.text('删除账号'));
    await tester.pump();
    final firstDialogText = tester.widget<Text>(
      find
          .descendant(of: find.byType(AlertDialog), matching: find.byType(Text))
          .at(1),
    );
    expect(firstDialogText.data, contains('配对会同时结束'));
    expect(firstDialogText.data, contains('不会删除 Ta 的账号和属于 Ta 的数据'));
    expect(firstDialogText.data, isNot(contains('share_owner_id')));
    expect(firstDialogText.data, isNot(contains('allocation')));
    expect(firstDialogText.data, isNot(contains('pair_members')));
  });

  testWidgets('delete failure restores action and keeps auth state', (
    tester,
  ) async {
    final auth = _TestAuthController(fail: true);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authControllerProvider.overrideWith(() => auth),
          pairControllerProvider.overrideWith(
            () => _FixedPairController(const PairNotFound()),
          ),
        ],
        child: const MaterialApp(home: AccountPrivacyPage()),
      ),
    );
    await tester.pump();

    await tester.tap(find.text('删除账号'));
    await tester.pump();
    await tester.tap(find.text('继续'));
    await tester.pump();
    await tester.tap(find.text('永久删除账号'));
    await tester.pumpAndSettle();

    expect(auth.deleteCalls, 1);
    expect(auth.state, isA<AuthAuthenticated>());
    expect(find.text('删除账号'), findsOneWidget);
    expect(find.text('删除账号失败，请稍后重试'), findsOneWidget);
    await tester.pump(const Duration(seconds: 4));
  });
}
