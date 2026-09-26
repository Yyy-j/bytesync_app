import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/core_providers.dart';
import 'body_repository.dart';
import 'remote_body_repository.dart';

final bodyRepositoryProvider = Provider<BodyRepository>(
  (ref) => RemoteBodyRepository(
    ref.watch(dioProvider),
    ref.watch(dioErrorMapperProvider),
  ),
);
