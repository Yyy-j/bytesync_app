import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/network/auth_event_bus.dart';
import '../../../core/providers/core_providers.dart';
import '../data/auth_providers.dart';
import '../data/auth_repository.dart';
import '../domain/auth_state.dart';

final authControllerProvider = NotifierProvider<AuthController, AuthState>(
  AuthController.new,
);

/// Owns [AuthState] for the whole app.
///
/// - Restores the session on cold start (once, at build time).
/// - Bridges [AuthEventBus] so any 401 (from any request in any feature)
///   transitions to [AuthUnauthenticated] and the router redirects to
///   `/login`.
class AuthController extends Notifier<AuthState> {
  late final AuthRepository _repository;
  StreamSubscription<AuthEvent>? _authEventSub;

  @override
  AuthState build() {
    _repository = ref.watch(authRepositoryProvider);

    final bus = ref.watch(authEventBusProvider);
    _authEventSub = bus.stream.listen(_onAuthEvent);
    ref.onDispose(() => _authEventSub?.cancel());

    _restoreSession();
    return const AuthInitial();
  }

  Future<void> _restoreSession() async {
    final user = await _repository.restoreSession();
    state = user != null
        ? AuthAuthenticated(user)
        : const AuthUnauthenticated();
  }

  void _onAuthEvent(AuthEvent event) {
    if (event == AuthEvent.unauthorized) {
      // The interceptor already cleared the token; just flip state.
      state = const AuthUnauthenticated(errorMessage: '登录已过期，请重新登录');
    }
  }

  Future<void> signInWithGoogle() async {
    state = const AuthLoading();
    try {
      final user = await _repository.signInWithGoogle();
      state = AuthAuthenticated(user);
    } catch (e) {
      state = AuthUnauthenticated(errorMessage: _messageFor(e));
    }
  }

  Future<void> signOut() async {
    await _repository.signOut();
    state = const AuthUnauthenticated();
  }

  String _messageFor(Object error) {
    if (error is ApiException) return error.message;
    return '登录失败，请重试';
  }
}
