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
  const ValidationException([String? message, int? statusCode])
    : super(message ?? '请求参数有误，请检查后重试', statusCode: statusCode);
}

/// 401 — missing or invalid Bearer token. The auth interceptor already
/// cleared the local session by the time this reaches the UI.
class UnauthorizedException extends ApiException {
  const UnauthorizedException([String? message])
    : super(message ?? '登录已过期，请重新登录', statusCode: 401);
}

/// 403 — authenticated but not allowed.
class ForbiddenException extends ApiException {
  const ForbiddenException([String? message])
    : super(message ?? '暂无权限', statusCode: 403);
}

/// 404 — resource does not exist.
class NotFoundException extends ApiException {
  const NotFoundException([String? message])
    : super(message ?? '请求的内容不存在', statusCode: 404);
}

/// 409 — write conflict. Currently used for:
/// - Optimistic-concurrency (`expected_updated_at` mismatch on PATCH).
/// - "already paired" on `POST /pairs`.
/// - "pair full" on `POST /pairs/join`.
class ConflictException extends ApiException {
  const ConflictException([String? message])
    : super(message ?? '这条记录已在其他设备被修改，请刷新后重试', statusCode: 409);
}

/// 5xx — the server accepted the request but failed to process it.
class ServerException extends ApiException {
  const ServerException([String? message, int? statusCode])
    : super(message ?? '服务器开小差了，请稍后重试', statusCode: statusCode);
}

/// Dio-level connectivity failure (timeout, DNS, no route to host, ...).
class NetworkException extends ApiException {
  const NetworkException([String? message])
    : super(message ?? '网络连接失败，请检查网络后重试');
}

/// Response body could not be decoded / mapped into the expected shape.
/// Treated as a server-side bug; the UI shows a generic error.
class MalformedResponseException extends ApiException {
  const MalformedResponseException([String? message])
    : super(message ?? '数据格式异常，请稍后重试');
}

/// Fallback for unknown errors. Should be rare; whenever this shows up in
/// logs it's a sign the error mapper is missing a case.
class UnknownApiException extends ApiException {
  const UnknownApiException([String? message]) : super(message ?? '出错了，请稍后重试');
}
