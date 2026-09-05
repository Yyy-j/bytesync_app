import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';

/// Shown briefly on app start while [AuthController] restores a session
/// from secure storage.
class SplashPage extends StatelessWidget {
  const SplashPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('🥗', style: TextStyle(fontSize: 48)),
            SizedBox(height: AppSpacing.lg),
            CircularProgressIndicator(color: AppColors.primary),
          ],
        ),
      ),
    );
  }
}
