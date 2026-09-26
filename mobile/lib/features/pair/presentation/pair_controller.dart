import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bytesync/l10n/l10n.dart';

import '../../../core/network/api_exception.dart';
import '../../auth/domain/auth_state.dart';
import '../../auth/presentation/auth_controller.dart';
import '../data/pair_providers.dart';
import '../data/pair_repository.dart';
import '../domain/pair_state.dart';

final pairControllerProvider = NotifierProvider<PairController, PairState>(
  PairController.new,
);

class PairController extends Notifier<PairState> {
  late final PairRepository _repository;
  late final _PairLifecycleObserver _lifecycleObserver;
  int _refreshGeneration = 0;
  bool _mutationInFlight = false;

  @override
  PairState build() {
    _repository = ref.watch(pairRepositoryProvider);
    _lifecycleObserver = _PairLifecycleObserver(_onAppLifecycleStateChanged);
    WidgetsBinding.instance.addObserver(_lifecycleObserver);
    ref.onDispose(() {
      _refreshGeneration++;
      WidgetsBinding.instance.removeObserver(_lifecycleObserver);
    });
    ref.listen<AuthState>(authControllerProvider, (previous, next) {
      if (next is AuthAuthenticated) {
        unawaited(refresh());
      } else {
        _refreshGeneration++;
        state = const PairInitial();
      }
    });

    if (ref.read(authControllerProvider) is AuthAuthenticated) {
      unawaited(refresh());
    }
    return const PairInitial();
  }

  Future<void> refresh({bool showLoading = true}) async {
    if (_mutationInFlight) return;
    final generation = ++_refreshGeneration;
    if (ref.read(authControllerProvider) is! AuthAuthenticated) {
      state = const PairInitial();
      return;
    }

    if (showLoading) state = const PairLoading();
    try {
      final pair = await _repository.getCurrentPair();
      if (generation != _refreshGeneration) return;
      state = pair == null ? const PairNotFound() : PairConnected(pair);
    } catch (error) {
      if (generation != _refreshGeneration) return;
      state = PairFailure(_messageFor(error));
    }
  }

  void _onAppLifecycleStateChanged(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed &&
        ref.read(authControllerProvider) is AuthAuthenticated) {
      unawaited(refresh(showLoading: false));
    }
  }

  Future<void> createPair() async {
    await _runMutation(() async {
      final pair = await _repository.createPair();
      final refreshedPair = await _repository.getCurrentPair();
      state = PairConnected(refreshedPair ?? pair, showInviteCode: true);
    });
  }

  Future<void> joinPair(String inviteCode) async {
    await _runMutation(() async {
      final joinedPair = await _repository.joinPair(
        inviteCode: inviteCode.trim(),
      );
      final refreshedPair = await _repository.getCurrentPair();
      state = PairConnected(refreshedPair ?? joinedPair);
    });
  }

  Future<void> regenerateInviteCode() async {
    await _runLifecycleMutation(() async {
      final pair = await _repository.regenerateInviteCode();
      state = PairConnected(pair, showInviteCode: true);
    });
  }

  Future<void> cancelPair() async {
    await _runLifecycleMutation(() async {
      await _repository.cancelPair();
      state = const PairNotFound();
    });
  }

  Future<void> endPair() async {
    await _runLifecycleMutation(() async {
      await _repository.endPair();
      state = const PairNotFound();
    });
  }

  void continueToHome() {
    final current = state;
    if (current is PairConnected && current.showInviteCode) {
      state = PairConnected(current.pair);
    }
  }

  Future<void> _runMutation(Future<void> Function() operation) async {
    _refreshGeneration++;
    _mutationInFlight = true;
    state = const PairLoading();
    try {
      await operation();
    } catch (error) {
      state = PairFailure(_messageFor(error));
    } finally {
      _mutationInFlight = false;
    }
  }

  Future<void> _runLifecycleMutation(Future<void> Function() operation) async {
    final previousState = state;
    _refreshGeneration++;
    _mutationInFlight = true;
    state = const PairLoading();
    try {
      await operation();
    } catch (error) {
      if (error is ConflictException) {
        _mutationInFlight = false;
        await refresh(showLoading: false);
        throw ConflictException(appL10n.pairLifecycleConflict);
      } else {
        state = previousState;
      }
      rethrow;
    } finally {
      _mutationInFlight = false;
    }
  }

  String _messageFor(Object error) {
    if (error is! ApiException) return appL10n.errorOperationFailed;
    if (error is NetworkException) return appL10n.errorNetworkRetry;
    if (error is UnauthorizedException) return appL10n.authSessionExpired;
    if (error is ConflictException) {
      if (error.message == appL10n.pairLifecycleConflict) {
        return appL10n.pairLifecycleConflict;
      }
      final message = error.message.toLowerCase();
      if (message.contains('full') || message.contains('满')) {
        return appL10n.pairFull;
      }
      if (message.contains('already') ||
          message.contains('paired') ||
          message.contains('加入')) {
        return appL10n.pairAlreadyJoined;
      }
      return appL10n.pairConflict;
    }
    if (error is ValidationException || error is NotFoundException) {
      return appL10n.pairInvalidInviteCode;
    }
    return appL10n.pairOperationFailed;
  }

  String messageFor(Object error) => _messageFor(error);
}

class _PairLifecycleObserver extends WidgetsBindingObserver {
  _PairLifecycleObserver(this.onStateChanged);

  final ValueChanged<AppLifecycleState> onStateChanged;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    onStateChanged(state);
  }
}
