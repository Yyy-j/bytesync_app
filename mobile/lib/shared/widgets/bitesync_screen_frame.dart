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
            child: CustomPaint(
              painter: _ScreenFramePainter(color),
            ),
          ),
        ),
      ],
    );
  }
}

class _ScreenFramePainter extends CustomPainter {
  const _ScreenFramePainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    const strokeWidth = 3.0;
    final inset = strokeWidth / 2 + 1;
    final shortestSide = size.shortestSide;
    final radius = (shortestSide * 0.12).clamp(44.0, 56.0).toDouble();
    final rect = Rect.fromLTWH(
      inset,
      inset,
      size.width - inset * 2,
      size.height - inset * 2,
    );
    final border = RRect.fromRectAndRadius(rect, Radius.circular(radius));

    canvas.drawRRect(
      border,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..color = color,
    );
  }

  @override
  bool shouldRepaint(covariant _ScreenFramePainter oldDelegate) {
    return oldDelegate.color != color;
  }
}