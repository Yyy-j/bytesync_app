import 'package:bytesync/l10n/l10n.dart';

/// Typed exceptions surfaced by the network / repository layer to the
/// controllers.
///
/// Repositories translate every raw error ([DioException], JSON decode
/// failure, mapping failure, ...) into one of these types so the UI layer
/// never has to know about `dio`, HTTP, or JSON.
///
/// Every subclass carries a user-facing [message] (Chinese, already
/// localized for MVP) and, when known, a [statusCode].
sealed class ApiException implements Exception {
  const ApiException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() => '$runtimeType($statusCode: $message)';
}

/// 400 / 422 — invalid request body or invalid domain state.
class ValidationException extends ApiException {
  ValidationException([String? message, int? statusCode])
    : super(message ?? appL10n.errorInvalidRequest, statusCode: statusCode);
}

/// 401 — missing or invalid Bearer token. The auth interceptor already
/// cleared the local session by the time this reaches the UI.
class UnauthorizedException extends ApiException {
  UnauthorizedException([String? message])
    : super(message ?? appL10n.authSessionExpired, statusCode: 401);
}

/// 403 — authenticated but not allowed.
class ForbiddenException extends ApiException {
  ForbiddenException([String? message])
    : super(message ?? appL10n.errorForbidden, statusCode: 403);
}

/// 404 — resource does not exist.
class NotFoundException extends ApiException {
  NotFoundException([String? message])
    : super(message ?? appL10n.errorNotFound, statusCode: 404);
}

/// 409 — write conflict. Currently used for:
/// - Optimistic-concurrency (`expected_updated_at` mismatch on PATCH).
/// - "already paired" on `POST /pairs`.
/// - "pair full" on `POST /pairs/join`.
class ConflictException extends ApiException {
  ConflictException([String? message])
    : super(message ?? appL10n.errorConflict, statusCode: 409);
}

/// 5xx — the server accepted the request but failed to process it.
class ServerException extends ApiException {
  ServerException([String? message, int? statusCode])
    : super(message ?? appL10n.errorServer, statusCode: statusCode);
}

/// Dio-level connectivity failure (timeout, DNS, no route to host, ...).
class NetworkException extends ApiException {
  NetworkException([String? message])
    : super(message ?? appL10n.errorNetworkRetry);
}

/// Response body could not be decoded / mapped into the expected shape.
/// Treated as a server-side bug; the UI shows a generic error.
class MalformedResponseException extends ApiException {
  MalformedResponseException([String? message])
    : super(message ?? appL10n.errorMalformedData);
}

/// Fallback for unknown errors. Should be rare; whenever this shows up in
/// logs it's a sign the error mapper is missing a case.
class UnknownApiException extends ApiException {
  UnknownApiException([String? message])
    : super(message ?? appL10n.errorUnknown);
}
