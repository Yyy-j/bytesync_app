import 'training_day.dart';

class TrainingTemplate {
  const TrainingTemplate({
    required this.id,
    required this.version,
    required this.days,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final int version;
  final List<TrainingDay> days;
  final DateTime createdAt;
  final DateTime updatedAt;
}
