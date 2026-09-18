import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

Future<T?> showBiteSyncModalBottomSheet<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool isScrollControlled = false,
  bool showDragHandle = false,
}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: isScrollControlled,
    showDragHandle: showDragHandle,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    clipBehavior: Clip.antiAlias,
    builder: (sheetContext) => Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
      child: Material(
        color:
            Theme.of(sheetContext).bottomSheetTheme.backgroundColor ??
            Theme.of(sheetContext).colorScheme.surface,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppRadius.lg),
        ),
        clipBehavior: Clip.antiAlias,
        child: builder(sheetContext),
      ),
    ),
  );
}
