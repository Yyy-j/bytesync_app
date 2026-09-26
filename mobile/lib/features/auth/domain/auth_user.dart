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
    this.onboardingCompletedAt,
    this.birthYear,
    this.sexForEnergyEstimate,
    this.heightCm,
    this.targetWeightKg,
    this.targetDate,
    this.activityLevel,
  });

  final String id;
  final String provider;
  final String? email;
  final String? displayName;
  final DateTime? onboardingCompletedAt;
  final int? birthYear;
  final String? sexForEnergyEstimate;
  final double? heightCm;
  final double? targetWeightKg;
  final DateTime? targetDate;
  final String? activityLevel;

  bool get onboardingCompleted => onboardingCompletedAt != null;

  /// A display-safe label; never returns an empty string.
  String get label {
    if (displayName != null && displayName!.isNotEmpty) return displayName!;
    if (email != null && email!.isNotEmpty) return email!.split('@').first;
    return appL10n.commonDefaultUser;
  }

  AuthUser copyWith({String? displayName, DateTime? onboardingCompletedAt}) =>
      AuthUser(
        id: id,
        provider: provider,
        email: email,
        displayName: displayName ?? this.displayName,
        onboardingCompletedAt:
            onboardingCompletedAt ?? this.onboardingCompletedAt,
        birthYear: birthYear,
        sexForEnergyEstimate: sexForEnergyEstimate,
        heightCm: heightCm,
        targetWeightKg: targetWeightKg,
        targetDate: targetDate,
        activityLevel: activityLevel,
      );
}
