import 'package:flutter/foundation.dart';

import 'auth_user.dart';

/// Overall authentication state consumed by the router (to decide whether
/// to show the login page) and by the login page (to render
/// loading/error/idle UI).
@immutable
sealed class AuthState {
  const AuthState();
}

/// Session is still being restored from secure storage on app start.
class AuthInitial extends AuthState {
  const AuthInitial();
}

/// No signed-in user; optionally carrying the last error message.
class AuthUnauthenticated extends AuthState {
  const AuthUnauthenticated({this.errorMessage});

  final String? errorMessage;
}

/// A sign-in attempt is in flight.
class AuthLoading extends AuthState {
  const AuthLoading();
}

/// A user is signed in.
class AuthAuthenticated extends AuthState {
  const AuthAuthenticated(this.user);

  final AuthUser user;
}
