import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

/// A rounded card matching the mini-program's `.card` utility class
/// (`background: card-bg; border-radius: lg; padding: lg; shadow: soft`).
class AppCard extends StatelessWidget {
  const AppCard({
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.lg),
    super.key,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Theme.of(context).brightness == Brightness.dark
            ? Border.all(color: Colors.white.withValues(alpha: 0.10))
            : null,
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).brightness == Brightness.dark
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
