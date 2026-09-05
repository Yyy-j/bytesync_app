import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/core_providers.dart';
import 'auth_repository.dart';
import 'google_auth_client.dart';
import 'remote_auth_repository.dart';

final googleAuthClientProvider = Provider<GoogleAuthClient>((ref) {
  return GoogleAuthClient();
});

/// The single provider every widget / controller depends on.
///
/// In production it returns [RemoteAuthRepository]. In tests, the test
/// case overrides this provider with a fake — see
/// `test/support/fake_auth_repository.dart`.
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return RemoteAuthRepository(
    dio: ref.watch(dioProvider),
    storage: ref.watch(secureStorageServiceProvider),
    googleAuthClient: ref.watch(googleAuthClientProvider),
    errorMapper: ref.watch(dioErrorMapperProvider),
  );
});
