import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

/// A rounded card matching the mini-program's `.card` utility class
/// (`background: card-bg; border-radius: lg; padding: lg; shadow: soft`).
class AppCard extends StatelessWidget {
  const AppCard({
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.lg),
    this.backgroundColor,
    this.borderColor,
    super.key,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color? backgroundColor;
  final Color? borderColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final border = borderColor != null
        ? Border.all(color: borderColor!)
        : theme.brightness == Brightness.dark
        ? Border.all(color: Colors.white.withValues(alpha: 0.10))
        : null;

    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: backgroundColor ?? theme.cardColor,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: border,
        boxShadow: [
          BoxShadow(
            color: theme.brightness == Brightness.dark
                ? Colors.transparent
                : const Color(0x0D000000),
            blurRadius: 20,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }
}
