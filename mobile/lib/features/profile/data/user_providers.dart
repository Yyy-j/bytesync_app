import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/core_providers.dart';
import 'remote_user_repository.dart';
import 'user_repository.dart';

final userRepositoryProvider = Provider<UserRepository>((ref) {
  return RemoteUserRepository(
    ref.watch(dioProvider),
    ref.watch(dioErrorMapperProvider),
  );
});
