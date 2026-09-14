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
    this.dishes = const [],
    this.aiHint,
    this.originalInput,
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
      dishes: input.dishes
          .where((dish) => dish.calories != null)
          .map(
            (dish) => <String, dynamic>{
              'name': dish.name,
              'calories': dish.calories!,
            },
          )
          .toList(growable: false),
      aiHint: input.aiHint,
      originalInput: input.originalInput,
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
  final List<Map<String, dynamic>> dishes;
  final String? aiHint;
  final String? originalInput;

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
    'dishes': dishes,
    'ai_hint': aiHint,
    'original_input': originalInput,
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
    this.dishes,
    this.aiHint,
    this.originalInput,
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
      dishes: patch.dishes
          ?.where((dish) => dish.calories != null)
          .map(
            (dish) => <String, dynamic>{
              'name': dish.name,
              'calories': dish.calories!,
            },
          )
          .toList(growable: false),
      aiHint: patch.aiHint,
      originalInput: patch.originalInput,
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
  final List<Map<String, dynamic>>? dishes;
  final String? aiHint;
  final String? originalInput;
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
    if (dishes != null) json['dishes'] = dishes;
    if (aiHint != null) json['ai_hint'] = aiHint;
    if (originalInput != null) json['original_input'] = originalInput;
    if (expectedUpdatedAt != null) {
      json['expected_updated_at'] = expectedUpdatedAt;
    }
    return json;
  }
}
