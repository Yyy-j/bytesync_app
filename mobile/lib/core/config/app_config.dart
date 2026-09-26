/// Centralized runtime configuration for the BiteSync Flutter app.
///
/// Every environment-dependent value here comes from a `--dart-define` at
/// build/run time. Example:
///   flutter run \
///     --dart-define=API_BASE_URL=https://api.example.com \
///     --dart-define=GOOGLE_CLIENT_ID=xxx \
///     --dart-define=GOOGLE_SERVER_CLIENT_ID=yyy
///
/// No widget or repository should hardcode a host / URL — everything reads
/// from [AppConfig] so switching environments (dev NAS → prod HTTPS) never
/// requires touching UI or repository code.
///
/// **There is no `USE_MOCK_BACKEND` switch.** Production always talks to
/// the real backend; mock/fake implementations live only under
/// `test/support/` and are wired into `ProviderScope.overrides` from within
/// tests.
class AppConfig {
  const AppConfig._();

  /// Base URL of the FastAPI backend.
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://yyynas.tail935349.ts.net',
  );

  /// Network timeouts, in milliseconds.
  static const int connectTimeoutMs = 10000;
  static const int receiveTimeoutMs = 10000;

  /// AI recognition may make a second upstream request when Gemini's
  /// primary model is temporarily overloaded, so it needs a wider response
  /// window than ordinary API calls.
  static const int aiReceiveTimeoutMs = 70000;

  /// Google OAuth client id used by `google_sign_in`.
  ///
  /// Empty by default: fill in via `--dart-define=GOOGLE_CLIENT_ID=...`
  /// once the OAuth client is provisioned. The login page treats an empty
  /// value as "Google sign-in not configured yet" rather than crashing.
  static const String googleClientId = String.fromEnvironment(
    'GOOGLE_CLIENT_ID',
    defaultValue: '25428716712-6ou134auo1b4lmj5pnc9jn20f5oh8uuu.apps.googleusercontent.com',
  );

  /// Server client id (Web client) used to request an ID token that the
  /// FastAPI backend can verify. Also empty by default.
  static const String googleServerClientId = String.fromEnvironment(
    'GOOGLE_SERVER_CLIENT_ID',
    defaultValue: '25428716712-l0shacb415h281dmr7q1hd3fs6c3vha3.apps.googleusercontent.com',
  );
}
