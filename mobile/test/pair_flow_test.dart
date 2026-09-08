import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:bytesync/app/app.dart';
import 'package:bytesync/app/home_shell.dart';
import 'package:bytesync/core/network/api_exception.dart';
import 'package:bytesync/features/auth/data/auth_providers.dart';
import 'package:bytesync/features/auth/data/auth_repository.dart';
import 'package:bytesync/features/auth/domain/auth_state.dart';
import 'package:bytesync/features/auth/domain/auth_user.dart';
import 'package:bytesync/features/auth/presentation/auth_controller.dart';
import 'package:bytesync/features/pair/data/pair_providers.dart';
import 'package:bytesync/features/pair/data/pair_repository.dart';
import 'package:bytesync/features/pair/domain/pair.dart';
import 'package:bytesync/features/pair/domain/pair_state.dart';
import 'package:bytesync/features/pair/presentation/pair_controller.dart';
import 'package:bytesync/features/pair/presentation/pairing_page.dart';

final _user = AuthUser(id: 'user-1', provider: 'google', email: 'one@example.com');
final _pair = Pair(
  pairId: 'pair-1',
  inviteCode: 'ABC123',
  members: const [
    PairMember(userId: 'user-1', displayName: 'One', avatarUrl: null, isSelf: true),
  ],
  createdAt: DateTime(2026),
);

class _FakeAuthRepository implements AuthRepository {
  _FakeAuthRepository({this.restoredUser});

  final AuthUser? restoredUser;

  @override
  Future<AuthUser?> restoreSession() async => restoredUser;

  @override
  Future<AuthUser> signInWithGoogle() async => _user;

  @override
  Future<AuthUser> getCurrentUser() async => _user;

  @override
  Future<void> signOut() async {}
}

class _FakePairRepository implements PairRepository {
  _FakePairRepository({this.currentPair});

  Pair? currentPair;
  Object? createError;
  Object? joinError;

  @override
  Future<Pair?> getCurrentPair() async => currentPair;

  @override
  Future<Pair> createPair() async {
    if (createError != null) throw createError!;
    currentPair = _pair;
    return _pair;
  }

  @override
  Future<Pair> joinPair({required String inviteCode}) async {
    if (joinError != null) throw joinError!;
    currentPair = _pair;
    return _pair;
  }
}

class _FixedAuthController extends AuthController {
  @override
  AuthState build() => AuthAuthenticated(_user);
}

Future<void> _settle(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 50));
}

void main() {
  testWidgets('未登录用户进入 /login', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(_FakeAuthRepository()),
          pairRepositoryProvider.overrideWithValue(_FakePairRepository()),
        ],
        child: const BiteSyncApp(),
      ),
    );
    await _settle(tester);

    expect(find.text('使用 Google 登录'), findsOneWidget);
  });

  testWidgets('已登录未配对用户进入 /pairing', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(
            _FakeAuthRepository(restoredUser: _user),
          ),
          pairRepositoryProvider.overrideWithValue(_FakePairRepository()),
        ],
        child: const BiteSyncApp(),
      ),
    );
    await _settle(tester);

    expect(find.byType(PairingPage), findsOneWidget);
  });

  testWidgets('已登录已配对用户进入主页', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(
            _FakeAuthRepository(restoredUser: _user),
          ),
          pairRepositoryProvider.overrideWithValue(
            _FakePairRepository(currentPair: _pair),
          ),
        ],
        child: const BiteSyncApp(),
      ),
    );
    await _settle(tester);

    expect(find.text('今日'), findsAtLeastNWidgets(1));
    expect(find.byType(PairingPage), findsNothing);

    GoRouter.of(tester.element(find.byType(HomeShell))).go('/pairing');
    await _settle(tester);
    expect(find.byType(PairingPage), findsNothing);
  });

  test('create and join update pair state', () async {
    final repository = _FakePairRepository();
    final container = ProviderContainer(
      overrides: [
        authControllerProvider.overrideWith(_FixedAuthController.new),
        pairRepositoryProvider.overrideWithValue(repository),
      ],
    );
    addTearDown(container.dispose);

    await container.read(pairControllerProvider.notifier).createPair();
    final created = container.read(pairControllerProvider);
    expect(created, isA<PairConnected>());
    expect((created as PairConnected).pair.inviteCode, 'ABC123');

    repository.currentPair = null;
    await container.read(pairControllerProvider.notifier).joinPair(' ABC123 ');
    expect(container.read(pairControllerProvider), isA<PairConnected>());
  });

  test('invalid invite and full pair errors are translated', () async {
    final repository = _FakePairRepository()
      ..joinError = const ValidationException('invalid invite');
    final container = ProviderContainer(
      overrides: [
        authControllerProvider.overrideWith(_FixedAuthController.new),
        pairRepositoryProvider.overrideWithValue(repository),
      ],
    );
    addTearDown(container.dispose);

    await container.read(pairControllerProvider.notifier).joinPair('bad');
    expect((container.read(pairControllerProvider) as PairFailure).message, '邀请码无效或已失效，请检查后重试');

    repository.joinError = const ConflictException('pair full');
    await container.read(pairControllerProvider.notifier).joinPair('full');
    expect((container.read(pairControllerProvider) as PairFailure).message, '这个配对已经有两位成员了');
  });

  test('logout clears pair state', () async {
    final repository = _FakePairRepository(currentPair: _pair);
    final container = ProviderContainer(
      overrides: [
        authRepositoryProvider.overrideWithValue(
          _FakeAuthRepository(restoredUser: _user),
        ),
        pairRepositoryProvider.overrideWithValue(repository),
      ],
    );
    addTearDown(container.dispose);

    container.read(authControllerProvider);
    await Future<void>.delayed(Duration.zero);
    await container.read(pairControllerProvider.notifier).refresh();
    expect(container.read(pairControllerProvider), isA<PairConnected>());

    await container.read(authControllerProvider.notifier).signOut();
    expect(container.read(pairControllerProvider), isA<PairInitial>());
  });
}
