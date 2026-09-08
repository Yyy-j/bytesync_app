import 'package:flutter/foundation.dart';

import 'pair.dart';

@immutable
sealed class PairState {
  const PairState();
}

class PairInitial extends PairState {
  const PairInitial();
}

class PairLoading extends PairState {
  const PairLoading();
}

class PairNotFound extends PairState {
  const PairNotFound();
}

class PairConnected extends PairState {
  const PairConnected(this.pair, {this.showInviteCode = false});

  final Pair pair;
  final bool showInviteCode;
}

class PairFailure extends PairState {
  const PairFailure(this.message);

  final String message;
}
