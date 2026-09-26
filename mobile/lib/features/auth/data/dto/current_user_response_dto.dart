import '../../../../core/network/api_exception.dart';

/// Wire shape of `GET /users/me` response body.
///
/// This auth-specific parser intentionally ignores the `goals` object.
/// Profile and nutrition-goal screens use their own DTO because the goal
/// keys differ from `GET /summary/daily`.
class CurrentUserResponseDto {
  const CurrentUserResponseDto({
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

  factory CurrentUserResponseDto.fromJson(Map<String, dynamic> json) {
    final id = json['id'];
    if (id is! String || id.isEmpty) {
      throw MalformedResponseException('缺少用户 id');
    }
    final provider = json['provider'];
    if (provider is! String || provider.isEmpty) {
      throw MalformedResponseException('缺少 provider');
    }
    return CurrentUserResponseDto(
      id: id,
      provider: provider,
      email: json['email'] as String?,
      displayName: json['display_name'] as String?,
      onboardingCompletedAt: _date(json['onboarding_completed_at']),
      birthYear: json['birth_year'] as int?,
      sexForEnergyEstimate: json['sex_for_energy_estimate'] as String?,
      heightCm: (json['height_cm'] as num?)?.toDouble(),
      targetWeightKg: (json['target_weight_kg'] as num?)?.toDouble(),
      targetDate: _date(json['target_date']),
      activityLevel: json['activity_level'] as String?,
    );
  }

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

  static DateTime? _date(Object? value) =>
      value is String ? DateTime.tryParse(value) : null;
}
