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

  @override
  PairState build() {
    _repository = ref.watch(pairRepositoryProvider);
    ref.listen<AuthState>(authControllerProvider, (previous, next) {
      if (next is AuthAuthenticated) {
        refresh();
      } else {
        state = const PairInitial();
      }
    });

    if (ref.read(authControllerProvider) is AuthAuthenticated) {
      refresh();
    }
    return const PairInitial();
  }

  Future<void> refresh() async {
    if (ref.read(authControllerProvider) is! AuthAuthenticated) {
      state = const PairInitial();
      return;
    }

    state = const PairLoading();
    try {
      final pair = await _repository.getCurrentPair();
      state = pair == null ? const PairNotFound() : PairConnected(pair);
    } catch (error) {
      state = PairFailure(_messageFor(error));
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

  void continueToHome() {
    final current = state;
    if (current is PairConnected && current.showInviteCode) {
      state = PairConnected(current.pair);
    }
  }

  Future<void> _runMutation(Future<void> Function() operation) async {
    state = const PairLoading();
    try {
      await operation();
    } catch (error) {
      state = PairFailure(_messageFor(error));
    }
  }

  String _messageFor(Object error) {
    if (error is! ApiException) return appL10n.errorOperationFailed;
    if (error is NetworkException) return appL10n.errorNetworkRetry;
    if (error is UnauthorizedException) return appL10n.authSessionExpired;
    if (error is ConflictException) {
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
}
