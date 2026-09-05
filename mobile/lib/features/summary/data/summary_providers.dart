import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/core_providers.dart';
import 'remote_summary_repository.dart';
import 'summary_repository.dart';

final summaryRepositoryProvider = Provider<SummaryRepository>((ref) {
  return RemoteSummaryRepository(
    ref.watch(dioProvider),
    ref.watch(dioErrorMapperProvider),
  );
});
