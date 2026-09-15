import 'package:bytesync/l10n/l10n.dart';

/// The authenticated BiteSync user.
///
/// Fields that the current backend `/users/me` returns:
/// - [id], [email] (nullable), [provider].
///
/// [displayName] is populated from the Google SDK at sign-in time
/// (best-effort). On cold restore it may be `null`; the UI falls back to
/// the email prefix / initials.
class AuthUser {
  const AuthUser({
    required this.id,
    required this.provider,
    this.email,
    this.displayName,
  });

  final String id;
  final String provider;
  final String? email;
  final String? displayName;

  /// A display-safe label; never returns an empty string.
  String get label {
    if (displayName != null && displayName!.isNotEmpty) return displayName!;
    if (email != null && email!.isNotEmpty) return email!.split('@').first;
    return appL10n.commonDefaultUser;
  }

  AuthUser copyWith({String? displayName}) => AuthUser(
    id: id,
    provider: provider,
    email: email,
    displayName: displayName ?? this.displayName,
  );
}
