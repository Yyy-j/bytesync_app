import 'dart:async';

/// A tiny broadcaster the [AuthInterceptor] uses to notify the
/// [AuthController] that a 401 has been observed on any request.
///
/// Kept separate from Riverpod / the auth feature so `core/network` never
/// imports from `features/auth`. The auth feature subscribes to this
/// stream on startup.
class AuthEventBus {
  final _controller = StreamController<AuthEvent>.broadcast();

  Stream<AuthEvent> get stream => _controller.stream;

  void emitUnauthorized() {
    _controller.add(AuthEvent.unauthorized);
  }

  Future<void> dispose() => _controller.close();
}

enum AuthEvent { unauthorized }
