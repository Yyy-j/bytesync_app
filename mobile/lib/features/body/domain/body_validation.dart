DateTime dateOnly(DateTime value) =>
    DateTime(value.year, value.month, value.day);

bool isWeightChanging(double currentWeight, double targetWeight) =>
    (targetWeight - currentWeight).abs() > 0.1;

bool canUseAdultRecommendation(int birthYear, {DateTime? today}) =>
    (today ?? DateTime.now()).year - birthYear > 18;

bool isValidGoalTimeline({
  required double currentWeight,
  required double targetWeight,
  required DateTime targetDate,
  DateTime? today,
}) {
  if (!isWeightChanging(currentWeight, targetWeight)) return true;
  final normalizedToday = dateOnly(today ?? DateTime.now());
  return dateOnly(targetDate).isAfter(normalizedToday);
}
