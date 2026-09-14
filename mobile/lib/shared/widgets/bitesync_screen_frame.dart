import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

class BiteSyncScreenFrame extends StatelessWidget {
  const BiteSyncScreenFrame({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = isDark ? AppColors.darkPrimary : AppColors.primary;
    return Stack(
      fit: StackFit.expand,
      children: [
        child,
        Positioned.fill(
          child: IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                border: Border.all(color: color, width: 3),
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: color.withValues(alpha: isDark ? 0.28 : 0.22),
                    blurRadius: isDark ? 11 : 9,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}