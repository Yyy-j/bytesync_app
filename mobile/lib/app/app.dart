import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/theme/app_theme.dart';
import '../core/theme/theme_controller.dart';
import '../core/providers/core_providers.dart';
import '../features/auth/domain/auth_state.dart';
import '../features/auth/presentation/auth_controller.dart';
import '../l10n/l10n.dart';
import '../shared/widgets/bitesync_screen_frame.dart';
import '../shared/widgets/dismiss_keyboard.dart';
import 'router.dart';

class BiteSyncApp extends ConsumerStatefulWidget {
  const BiteSyncApp({super.key});

  @override
  ConsumerState<BiteSyncApp> createState() => _BiteSyncAppState();
}

class _BiteSyncAppState extends ConsumerState<BiteSyncApp>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed &&
        ref.read(authControllerProvider) is AuthAuthenticated) {
      unawaited(_refreshSessionIfStale());
    }
  }

  Future<void> _refreshSessionIfStale() async {
    try {
      await ref.read(authSessionManagerProvider).refreshIfStale();
    } catch (_) {
      // Foreground renewal is silent and never changes auth on local failures.
    }
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(routerProvider);
    final themeController = ref.watch(themeModeControllerProvider);

    return MaterialApp.router(
      onGenerateTitle: (context) => context.l10n.appTitle,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      debugShowCheckedModeBanner: false,
      theme: buildLightTheme(),
      darkTheme: buildDarkTheme(),
      themeMode: themeController.mode,
      routerConfig: router,
      builder: (context, child) => BiteSyncScreenFrame(
        child: DismissKeyboard(child: child ?? const SizedBox.shrink()),
      ),
    );
  }
}
