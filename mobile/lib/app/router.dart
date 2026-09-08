import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/auth/domain/auth_state.dart';
import '../features/auth/presentation/auth_controller.dart';
import '../features/auth/presentation/login_page.dart';
import '../features/pair/domain/pair_state.dart';
import '../features/pair/presentation/pair_controller.dart';
import '../features/pair/presentation/pairing_page.dart';
import 'home_shell.dart';
import 'splash_page.dart';

/// Bridges Riverpod's [authControllerProvider] to go_router's
/// [Listenable]-based `refreshListenable`, so the router re-evaluates
/// [GoRouter.redirect] whenever [AuthState] changes, without recreating
/// the [GoRouter] instance (which would otherwise reset the navigation
/// stack).
class _RouterRefreshNotifier extends ChangeNotifier {
  _RouterRefreshNotifier(Ref ref) {
    ref.listen<AuthState>(
      authControllerProvider,
      (previous, next) => notifyListeners(),
    );
    ref.listen<PairState>(
      pairControllerProvider,
      (previous, next) => notifyListeners(),
    );
  }
}

final _routerRefreshProvider = Provider<_RouterRefreshNotifier>((ref) {
  return _RouterRefreshNotifier(ref);
});

final routerProvider = Provider<GoRouter>((ref) {
  final refresh = ref.watch(_routerRefreshProvider);

  return GoRouter(
    initialLocation: '/splash',
    refreshListenable: refresh,
    redirect: (context, state) {
      final authState = ref.read(authControllerProvider);
      final pairState = ref.read(pairControllerProvider);
      final location = state.matchedLocation;

      if (authState is AuthInitial) {
        return location == '/splash' ? null : '/splash';
      }
      if (authState is AuthAuthenticated) {
        if (pairState is PairInitial || pairState is PairLoading) {
          return location == '/splash' ? null : '/splash';
        }
        if (pairState is PairConnected) {
          final canShowInvite = pairState.showInviteCode && location == '/pairing';
          if (canShowInvite) return null;
          return (location == '/login' || location == '/splash' || location == '/pairing')
              ? '/'
              : null;
        }
        return (location == '/login' || location == '/splash') ? '/pairing' : null;
      }
      // AuthUnauthenticated or AuthLoading (mid sign-in attempt from the
      // login page itself) both mean "show the login page".
      return location == '/login' ? null : '/login';
    },
    routes: [
      GoRoute(path: '/splash', builder: (context, state) => const SplashPage()),
      GoRoute(path: '/login', builder: (context, state) => const LoginPage()),
      GoRoute(path: '/pairing', builder: (context, state) => const PairingPage()),
      GoRoute(path: '/', builder: (context, state) => const HomeShell()),
    ],
  );
});
