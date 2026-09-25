import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:bytesync/l10n/l10n.dart';

import '../../../../shared/widgets/bitesync_snackbar.dart';
import 'training_exercise_video_controller.dart';

Future<void> openTrainingVideoUrl(BuildContext context, Uri url) async {
  var opened = false;
  try {
    opened = await launchUrl(url, mode: LaunchMode.externalApplication);
  } catch (_) {
    opened = false;
  }
  if (!opened && context.mounted) {
    BiteSyncSnackBar.show(context, message: appL10n.trainingVideoOpenFailed);
  }
}

Future<void> showTrainingVideoEditor(
  BuildContext context,
  WidgetRef ref, {
  required String exerciseId,
  required String exerciseName,
}) async {
  var state = ref.read(trainingExerciseVideoControllerProvider);
  if (state is! TrainingExerciseVideoReady) {
    await ref.read(trainingExerciseVideoControllerProvider.notifier).refresh();
    if (!context.mounted) return;
    state = ref.read(trainingExerciseVideoControllerProvider);
  }
  if (state is! TrainingExerciseVideoReady || state.mutating) {
    BiteSyncSnackBar.show(
      context,
      message: state is TrainingExerciseVideoFailure
          ? state.message
          : appL10n.trainingVideoListLoading,
    );
    return;
  }
  final existing = state.videos[exerciseId];
  final controller = TextEditingController(
    text: existing?.videoUrl.toString() ?? '',
  );
  String? error;
  final action = await showDialog<_VideoEditorAction>(
    context: context,
    builder: (dialogContext) => StatefulBuilder(
      builder: (context, setState) => AlertDialog(
        title: Text(appL10n.trainingVideoTitle(exerciseName)),
        content: TextField(
          controller: controller,
          autofocus: true,
          keyboardType: TextInputType.url,
          maxLength: 2048,
          decoration: InputDecoration(
            labelText: appL10n.trainingVideoExternalLink,
            hintText: appL10n.trainingVideoUrlHint,
            errorText: error,
          ),
        ),
        actions: [
          if (existing != null)
            TextButton(
              onPressed: () =>
                  Navigator.pop(dialogContext, _VideoEditorAction.delete()),
              child: Text(appL10n.trainingVideoDeleteLink),
            ),
          if (existing != null)
            TextButton(
              onPressed: () => openTrainingVideoUrl(context, existing.videoUrl),
              child: Text(appL10n.commonView),
            ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(appL10n.commonCancel),
          ),
          FilledButton(
            onPressed: () {
              final value = controller.text.trim();
              final uri = Uri.tryParse(value);
              if (value.isEmpty ||
                  uri == null ||
                  !uri.hasAuthority ||
                  (uri.scheme != 'http' && uri.scheme != 'https')) {
                setState(() => error = appL10n.trainingVideoInvalidUrl);
                return;
              }
              Navigator.pop(dialogContext, _VideoEditorAction.save(value));
            },
            child: Text(appL10n.commonSave),
          ),
        ],
      ),
    ),
  );
  controller.dispose();
  if (action == null || !context.mounted) return;

  final result = action.delete
      ? await ref
            .read(trainingExerciseVideoControllerProvider.notifier)
            .delete(exerciseId)
      : await ref
            .read(trainingExerciseVideoControllerProvider.notifier)
            .save(exerciseId, action.videoUrl!);
  if (context.mounted) {
    BiteSyncSnackBar.show(
      context,
      message: result.isSuccess
          ? action.delete
                ? appL10n.trainingVideoDeleted
                : appL10n.trainingVideoSaved
          : result.errorMessage!,
    );
  }
}

class _VideoEditorAction {
  const _VideoEditorAction.save(this.videoUrl) : delete = false;
  const _VideoEditorAction.delete() : videoUrl = null, delete = true;

  final String? videoUrl;
  final bool delete;
}
