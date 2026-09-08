import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../../auth/domain/auth_state.dart';
import '../../auth/presentation/auth_controller.dart';
import '../data/pair_providers.dart';
import '../data/pair_repository.dart';
import '../domain/pair_state.dart';

final pairControllerProvider =
    NotifierProvider<PairController, PairState>(PairController.new);

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
      final joinedPair = await _repository.joinPair(inviteCode: inviteCode.trim());
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
    if (error is! ApiException) return '操作失败，请稍后重试';
    if (error is NetworkException) return '网络连接失败，请检查网络后重试';
    if (error is UnauthorizedException) return '登录已过期，请重新登录';
    if (error is ConflictException) {
      final message = error.message.toLowerCase();
      if (message.contains('full') || message.contains('满')) {
        return '这个配对已经有两位成员了';
      }
      if (message.contains('already') || message.contains('paired') || message.contains('加入')) {
        return '你已经加入配对，不能重复操作';
      }
      return '当前配对状态发生冲突，请刷新后重试';
    }
    if (error is ValidationException || error is NotFoundException) {
      return '邀请码无效或已失效，请检查后重试';
    }
    return '配对操作失败，请稍后重试';
  }
}
