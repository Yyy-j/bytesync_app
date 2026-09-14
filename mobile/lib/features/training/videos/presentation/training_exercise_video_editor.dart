import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import 'training_exercise_video_controller.dart';

Future<void> openTrainingVideoUrl(BuildContext context, Uri url) async {
  var opened = false;
  try {
    opened = await launchUrl(url, mode: LaunchMode.externalApplication);
  } catch (_) {
    opened = false;
  }
  if (!opened && context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('无法打开教学视频链接')),
    );
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
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          state is TrainingExerciseVideoFailure
              ? state.message
              : '教学视频列表尚未加载完成',
        ),
      ),
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
        title: Text('$exerciseName · 教学视频'),
        content: TextField(
          controller: controller,
          autofocus: true,
          keyboardType: TextInputType.url,
          maxLength: 2048,
          decoration: InputDecoration(
            labelText: '外部视频链接',
            hintText: 'https://...',
            errorText: error,
          ),
        ),
        actions: [
          if (existing != null)
            TextButton(
              onPressed: () => Navigator.pop(
                dialogContext,
                const _VideoEditorAction.delete(),
              ),
              child: const Text('删除链接'),
            ),
          if (existing != null)
            TextButton(
              onPressed: () => openTrainingVideoUrl(context, existing.videoUrl),
              child: const Text('查看'),
            ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () {
              final value = controller.text.trim();
              final uri = Uri.tryParse(value);
              if (value.isEmpty ||
                  uri == null ||
                  !uri.hasAuthority ||
                  (uri.scheme != 'http' && uri.scheme != 'https')) {
                setState(() => error = '请输入有效的 http / https 链接');
                return;
              }
              Navigator.pop(
                dialogContext,
                _VideoEditorAction.save(value),
              );
            },
            child: const Text('保存'),
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
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          result.isSuccess
              ? action.delete
                    ? '教学视频链接已删除'
                    : '教学视频链接已保存'
              : result.errorMessage!,
        ),
      ),
    );
  }
}

class _VideoEditorAction {
  const _VideoEditorAction.save(this.videoUrl) : delete = false;
  const _VideoEditorAction.delete() : videoUrl = null, delete = true;

  final String? videoUrl;
  final bool delete;
}
