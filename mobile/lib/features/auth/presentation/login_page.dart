import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../domain/auth_state.dart';
import 'auth_controller.dart';

/// Google sign-in landing page.
///
/// Requirements from the project brief: logo/app name, a short welcome
/// blurb, a "Sign in with Google" button, a loading state, and a failure
/// message — with the auth layer built so Apple sign-in can be added
/// alongside Google later without rewriting this page.
class LoginPage extends ConsumerWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authControllerProvider);
    final isLoading = authState is AuthLoading;
    final errorMessage = authState is AuthUnauthenticated
        ? authState.errorMessage
        : null;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(flex: 3),
              _Logo(),
              const SizedBox(height: AppSpacing.lg),
              const Text(
                'BiteSync',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              const Text(
                '轻松记录每一餐，掌握每日营养',
                style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
              ),
              const Spacer(flex: 4),
              if (errorMessage != null) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: AppColors.warningLight,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  child: Text(
                    errorMessage,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: AppColors.warning,
                      fontSize: 13,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
              ],
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: isLoading
                      ? null
                      : () => ref
                            .read(authControllerProvider.notifier)
                            .signInWithGoogle(),
                  icon: isLoading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation(Colors.white),
                          ),
                        )
                      : const Icon(Icons.g_mobiledata, size: 24),
                  label: Text(isLoading ? '登录中…' : '使用 Google 登录'),
                ),
              ),
              const SizedBox(height: AppSpacing.xxl),
            ],
          ),
        ),
      ),
    );
  }
}

class _Logo extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 88,
      height: 88,
      decoration: BoxDecoration(
        color: AppColors.primaryLight,
        borderRadius: BorderRadius.circular(AppRadius.lg + 8),
      ),
      alignment: Alignment.center,
      child: const Text('🥗', style: TextStyle(fontSize: 40)),
    );
  }
}
