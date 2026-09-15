import 'package:google_sign_in/google_sign_in.dart';
import 'package:bytesync/l10n/l10n.dart';

import '../../../core/config/app_config.dart';
import '../../../core/network/api_exception.dart';

/// Raw result of a successful Google sign-in, before the backend has
/// exchanged it for a BiteSync app session.
class GoogleAuthResult {
  const GoogleAuthResult({
    required this.idToken,
    required this.email,
    this.displayName,
  });

  final String idToken;
  final String email;
  final String? displayName;
}

/// Thin wrapper around the `google_sign_in` plugin.
///
/// Isolates the SDK so a) the [AuthRepository] stays small, and b) if a
/// second provider (Apple) is added later, this file is the only Google-
/// specific one.
class GoogleAuthClient {
  GoogleAuthClient({GoogleSignIn? googleSignIn})
    : _googleSignIn = googleSignIn ?? GoogleSignIn.instance;

  final GoogleSignIn _googleSignIn;
  bool _initialized = false;

  Future<void> _ensureInitialized() async {
    if (_initialized) return;
    if (AppConfig.googleClientId.isEmpty) {
      throw ValidationException(appL10n.authGoogleNotConfigured);
    }
    await _googleSignIn.initialize(
      clientId: AppConfig.googleClientId,
      serverClientId: AppConfig.googleServerClientId.isNotEmpty
          ? AppConfig.googleServerClientId
          : null,
    );
    _initialized = true;
  }

  /// Starts the interactive Google sign-in flow.
  ///
  /// Throws:
  /// - [ValidationException] if Google sign-in isn't configured or the
  ///   SDK didn't return an id_token.
  /// - [UnknownApiException] on canceled / failed sign-in with the
  ///   underlying reason.
  Future<GoogleAuthResult> signIn() async {
    await _ensureInitialized();
    try {
      final account = await _googleSignIn.authenticate();
      final idToken = account.authentication.idToken;
      if (idToken == null) {
        throw ValidationException(appL10n.authGoogleCredentialMissing);
      }
      return GoogleAuthResult(
        idToken: idToken,
        email: account.email,
        displayName: account.displayName,
      );
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled) {
        throw UnknownApiException(appL10n.authSignInCancelled);
      }
      throw UnknownApiException(
        appL10n.authGoogleSignInFailed((e.description ?? e.code).toString()),
      );
    }
  }

  Future<void> signOut() async {
    if (!_initialized) return;
    await _googleSignIn.signOut();
  }
}
