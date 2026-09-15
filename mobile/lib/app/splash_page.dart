import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bytesync/l10n/l10n.dart';

import '../core/theme/app_theme.dart';
import '../features/auth/domain/auth_state.dart';
import '../features/auth/presentation/auth_controller.dart';

/// Shown briefly on app start while [AuthController] restores a session
/// from secure storage.
class SplashPage extends ConsumerWidget {
  const SplashPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final authState = ref.watch(authControllerProvider);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('🥗', style: TextStyle(fontSize: 48)),
            SizedBox(height: AppSpacing.lg),
            if (authState case AuthRestoreFailed(:final message)) ...[
              Padding(
                padding: EdgeInsets.symmetric(horizontal: AppSpacing.xl),
                child: Text(message, textAlign: TextAlign.center),
              ),
              SizedBox(height: AppSpacing.md),
              FilledButton(
                onPressed: () => ref
                    .read(authControllerProvider.notifier)
                    .retryRestoreSession(),
                child: Text(appL10n.commonRetry),
              ),
            ] else
              CircularProgressIndicator(color: theme.colorScheme.primary),
          ],
        ),
      ),
    );
  }
}
