import 'record_draft.dart';

sealed class RecordState {
  const RecordState();
}

enum RecordAnalysisKind { text, image }

class RecordIdle extends RecordState {
  const RecordIdle();
}

class RecordAnalyzing extends RecordState {
  const RecordAnalyzing({required this.kind, this.draft});

  final RecordAnalysisKind kind;
  final RecordDraft? draft;
}

class RecordResult extends RecordState {
  const RecordResult(this.draft);

  final RecordDraft draft;
}

class RecordError extends RecordState {
  const RecordError(this.message, {this.draft});

  final String message;
  final RecordDraft? draft;
}
