import '../../../core/network/api_exception.dart';

/// How a meal was created. Phase 2 only supports [manual]; the remaining
/// values are reserved for Phase 3 AI features.
enum MealSource {
  manual,
  ai,
  text;

  String toWire() {
    switch (this) {
      case MealSource.manual:
        return 'manual';
      case MealSource.ai:
        return 'ai';
      case MealSource.text:
        return 'text';
    }
  }

  static MealSource fromWire(String wire) {
    switch (wire) {
      case 'manual':
        return MealSource.manual;
      case 'ai':
        return MealSource.ai;
      case 'text':
        return MealSource.text;
    }
    throw MalformedResponseException('未知的 meal source: $wire');
  }
}
