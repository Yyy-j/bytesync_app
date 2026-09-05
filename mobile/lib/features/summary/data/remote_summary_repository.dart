import 'package:dio/dio.dart';
import 'package:intl/intl.dart';

import '../../../core/network/api_endpoints.dart';
import '../../../core/network/dio_error_mapper.dart';
import '../domain/daily_summary.dart';
import 'summary_repository.dart';

/// Real implementation of [SummaryRepository], calling the FastAPI
/// backend.
///
class RemoteSummaryRepository implements SummaryRepository {
  RemoteSummaryRepository(this._dio, this._errorMapper);

  final Dio _dio;
  final DioErrorMapper _errorMapper;

  @override
  Future<DailySummary> getDailySummary(DateTime date) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        ApiEndpoints.summaryDaily,
        queryParameters: {'date': DateFormat('yyyy-MM-dd').format(date)},
      );
      return DailySummary.fromJson(response.data!);
    } catch (e) {
      throw _errorMapper.map(e);
    }
  }
}
