import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/core_providers.dart';
import '../../auth/data/auth_providers.dart';
import 'pair_repository.dart';
import 'remote_pair_repository.dart';

final pairRepositoryProvider = Provider<PairRepository>((ref) {
  return RemotePairRepository(
    dio: ref.watch(dioProvider),
    errorMapper: ref.watch(dioErrorMapperProvider),
    authRepository: ref.watch(authRepositoryProvider),
  );
});