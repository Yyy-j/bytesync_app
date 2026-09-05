import 'package:dio/dio.dart';

import 'api_exception.dart';

/// Converts any error caught during a Dio request into a typed
/// [ApiException]. Every `Remote*Repository` funnels its `catch` through
/// this so:
///
/// - the UI never sees a raw [DioException];
/// - the mapping is centralized (one table to review);
/// - message extraction from FastAPI's `{"detail": "..."}` /
///   `{"detail": [ValidationError, ...]}` shapes is handled once.
class DioErrorMapper {
  const DioErrorMapper();

  ApiException map(Object error) {
    if (error is ApiException) return error;
    if (error is DioException) return _fromDio(error);
    return UnknownApiException(error.toString());
  }

  ApiException _fromDio(DioException error) {
    // Connectivity / timeout errors — no response received.
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.connectionError:
        return const NetworkException();
      default:
        break;
    }

    final response = error.response;
    if (response == null) return const NetworkException();

    final statusCode = response.statusCode ?? 0;
    final detail = _extractDetail(response.data);

    if (statusCode == 400) return ValidationException(detail, statusCode);
    if (statusCode == 401) return UnauthorizedException(detail);
    if (statusCode == 403) return ForbiddenException(detail);
    if (statusCode == 404) return NotFoundException(detail);
    if (statusCode == 409) return ConflictException(detail);
    if (statusCode == 422) return ValidationException(detail, statusCode);
    if (statusCode >= 500 && statusCode < 600) {
      return ServerException(detail, statusCode);
    }
    return UnknownApiException(detail ?? 'HTTP $statusCode');
  }

  /// FastAPI error bodies come in three shapes:
  /// - `{"detail": "human readable"}`
  /// - `{"detail": [{"loc": [...], "msg": "...", "type": "..."}, ...]}`
  /// - opaque body / non-JSON
  ///
  /// Returns a best-effort human-readable string or `null` if nothing
  /// useful can be extracted (caller falls back to the default per-code
  /// message).
  String? _extractDetail(dynamic body) {
    if (body is Map) {
      final detail = body['detail'];
      if (detail is String) return detail;
      if (detail is List && detail.isNotEmpty) {
        final first = detail.first;
        if (first is Map && first['msg'] is String) {
          return first['msg'] as String;
        }
      }
    }
    return null;
  }
}
