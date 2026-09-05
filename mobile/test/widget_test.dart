import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bytesync/app/app.dart';
import 'package:bytesync/features/auth/data/auth_providers.dart';
import 'package:bytesync/features/auth/data/auth_repository.dart';
import 'package:bytesync/features/auth/domain/auth_user.dart';

class _UnauthenticatedAuthRepository implements AuthRepository {
  @override
  Future<AuthUser?> restoreSession() async => null;

  @override
  Future<AuthUser> signInWithGoogle() {
    throw UnimplementedError();
  }

  @override
  Future<AuthUser> getCurrentUser() {
    throw UnimplementedError();
  }

  @override
  Future<void> signOut() async {}
}

void main() {
  testWidgets('App boots and shows the Google sign-in button', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(
            _UnauthenticatedAuthRepository(),
          ),
        ],
        child: const BiteSyncApp(),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('使用 Google 登录'), findsOneWidget);
  });
}

