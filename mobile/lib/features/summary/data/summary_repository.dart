import '../domain/daily_summary.dart';

/// Summary-facing operations. The summary page depends only on this
/// interface — never on whether requests are mocked or hit the real
/// backend.
abstract interface class SummaryRepository {
  Future<DailySummary> getDailySummary(DateTime date);
}
