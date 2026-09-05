/// The authenticated BiteSync user.
///
/// Fields that the current backend `/users/me` returns:
/// - [id], [email] (nullable), [provider].
///
/// [displayName] / [avatarUrl] are populated from the Google SDK at
/// sign-in time (best-effort). On cold restore they may be `null`; the UI
/// falls back to email prefix / initials. The backend can optionally add
/// these to `CurrentUserResponse` in the future (see
/// `API_CONTRACT.md` §5) without any Flutter change.
class AuthUser {
  const AuthUser({
    required this.id,
    required this.provider,
    this.email,
    this.displayName,
    this.avatarUrl,
  });

  final String id;
  final String provider;
  final String? email;
  final String? displayName;
  final String? avatarUrl;

  /// A display-safe label; never returns an empty string.
  String get label {
    if (displayName != null && displayName!.isNotEmpty) return displayName!;
    if (email != null && email!.isNotEmpty) return email!.split('@').first;
    return 'BiteSync 用户';
  }

  AuthUser copyWith({String? displayName, String? avatarUrl}) => AuthUser(
    id: id,
    provider: provider,
    email: email,
    displayName: displayName ?? this.displayName,
    avatarUrl: avatarUrl ?? this.avatarUrl,
  );
}
