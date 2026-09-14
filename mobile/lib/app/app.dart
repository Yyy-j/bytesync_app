import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/theme/app_theme.dart';
import '../core/theme/theme_controller.dart';
import '../shared/widgets/bitesync_screen_frame.dart';
import '../shared/widgets/dismiss_keyboard.dart';
import 'router.dart';

class BiteSyncApp extends ConsumerWidget {
  const BiteSyncApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final themeController = ref.watch(themeModeControllerProvider);

    return MaterialApp.router(
      title: 'BiteSync',
      debugShowCheckedModeBanner: false,
      theme: buildLightTheme(),
      darkTheme: buildDarkTheme(),
      themeMode: themeController.mode,
      routerConfig: router,
      builder: (context, child) => BiteSyncScreenFrame(
        child: DismissKeyboard(
          child: child ?? const SizedBox.shrink(),
        ),
      ),
    );
  }
}
