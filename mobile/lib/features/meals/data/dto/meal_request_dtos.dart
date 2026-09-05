import '../../domain/meal_patch.dart';

/// Wire shape of `POST /meals` request body. Matches
/// `API_CONTRACT.md` §2.2.
class CreateMealRequestDto {
  const CreateMealRequestDto({
    required this.name,
    required this.source,
    required this.baseCalories,
    required this.baseProtein,
    required this.baseCarbs,
    required this.baseFat,
    required this.portionRatio,
    required this.shareMode,
    required this.mealTime,
  });

  factory CreateMealRequestDto.fromInput(NewMealInput input) {
    return CreateMealRequestDto(
      name: input.name,
      source: input.source.toWire(),
      baseCalories: input.baseCalories,
      baseProtein: input.baseProtein,
      baseCarbs: input.baseCarbs,
      baseFat: input.baseFat,
      portionRatio: input.portionRatio,
      shareMode: input.shareMode.toWire(),
      mealTime: input.mealTime,
    );
  }

  final String name;
  final String source;
  final num baseCalories;
  final num baseProtein;
  final num baseCarbs;
  final num baseFat;
  final double portionRatio;
  final String shareMode;
  final String mealTime;

  Map<String, dynamic> toJson() => {
    'name': name,
    'source': source,
    'base_calories': baseCalories,
    'base_protein': baseProtein,
    'base_carbs': baseCarbs,
    'base_fat': baseFat,
    'portion_ratio': portionRatio,
    'share_mode': shareMode,
    'meal_time': mealTime,
  };
}

/// Wire shape of `PATCH /meals/{id}` request body. Only non-null fields
/// are sent.
class UpdateMealRequestDto {
  const UpdateMealRequestDto({
    this.name,
    this.baseCalories,
    this.baseProtein,
    this.baseCarbs,
    this.baseFat,
    this.portionRatio,
    this.shareMode,
    this.mealTime,
    this.expectedUpdatedAt,
  });

  factory UpdateMealRequestDto.fromPatch(MealPatch patch) {
    return UpdateMealRequestDto(
      name: patch.name,
      baseCalories: patch.baseCalories,
      baseProtein: patch.baseProtein,
      baseCarbs: patch.baseCarbs,
      baseFat: patch.baseFat,
      portionRatio: patch.portionRatio,
      shareMode: patch.shareMode?.toWire(),
      mealTime: patch.mealTime,
      expectedUpdatedAt: patch.expectedUpdatedAt?.toIso8601String(),
    );
  }

  final String? name;
  final num? baseCalories;
  final num? baseProtein;
  final num? baseCarbs;
  final num? baseFat;
  final double? portionRatio;
  final String? shareMode;
  final String? mealTime;
  final String? expectedUpdatedAt;

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    if (name != null) json['name'] = name;
    if (baseCalories != null) json['base_calories'] = baseCalories;
    if (baseProtein != null) json['base_protein'] = baseProtein;
    if (baseCarbs != null) json['base_carbs'] = baseCarbs;
    if (baseFat != null) json['base_fat'] = baseFat;
    if (portionRatio != null) json['portion_ratio'] = portionRatio;
    if (shareMode != null) json['share_mode'] = shareMode;
    if (mealTime != null) json['meal_time'] = mealTime;
    if (expectedUpdatedAt != null) {
      json['expected_updated_at'] = expectedUpdatedAt;
    }
    return json;
  }
}
