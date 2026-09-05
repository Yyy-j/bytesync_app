import '../../../core/network/api_exception.dart';

/// How the calories/protein/carbs/fat of a meal are split between the two
/// paired users.
///
/// See `.scratch/bitesync-frontend-phase2/SPEC.md` §4.2 for the frozen
/// wire mapping and the (me, partner) ratio pair.
enum MealShareMode {
  /// 100% self, 0% partner. 1 row stored.
  solo,

  /// 0% self, 100% partner. 1 row stored (owned by partner).
  partnerOnly,

  /// 50 / 50. 2 rows stored, linked by `sharedMealId`.
  sharedHalf,

  /// self 1/3, partner 2/3. 2 rows, linked.
  sharedMeOneThird,

  /// self 2/3, partner 1/3. 2 rows, linked.
  sharedMeTwoThirds;

  /// The share ratio for the current user's ("self") slice.
  double get meRatio {
    switch (this) {
      case MealShareMode.solo:
        return 1;
      case MealShareMode.partnerOnly:
        return 0;
      case MealShareMode.sharedHalf:
        return 0.5;
      case MealShareMode.sharedMeOneThird:
        return 1 / 3;
      case MealShareMode.sharedMeTwoThirds:
        return 2 / 3;
    }
  }

  /// The share ratio for the partner's slice.
  double get partnerRatio => 1 - meRatio;

  /// True when this mode results in two linked rows on the wire.
  bool get isShared =>
      this == MealShareMode.sharedHalf ||
      this == MealShareMode.sharedMeOneThird ||
      this == MealShareMode.sharedMeTwoThirds;

  /// Wire-format snake_case name (see `API_CONTRACT.md` §6).
  String toWire() {
    switch (this) {
      case MealShareMode.solo:
        return 'solo';
      case MealShareMode.partnerOnly:
        return 'partner_only';
      case MealShareMode.sharedHalf:
        return 'shared_half';
      case MealShareMode.sharedMeOneThird:
        return 'shared_me_one_third';
      case MealShareMode.sharedMeTwoThirds:
        return 'shared_me_two_thirds';
    }
  }

  static MealShareMode fromWire(String wire) {
    switch (wire) {
      case 'solo':
        return MealShareMode.solo;
      case 'partner_only':
        return MealShareMode.partnerOnly;
      case 'shared_half':
        return MealShareMode.sharedHalf;
      case 'shared_me_one_third':
        return MealShareMode.sharedMeOneThird;
      case 'shared_me_two_thirds':
        return MealShareMode.sharedMeTwoThirds;
    }
    throw MalformedResponseException('未知的 share_mode: $wire');
  }
}
