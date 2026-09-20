import 'package:flutter/material.dart';

import '../core/theme/jarvis_colors.dart';

class AnimatedGrid extends StatefulWidget {
  final Widget child;
  final double opacity;

  const AnimatedGrid({
    super.key,
    required this.child,
    this.opacity = 0.16,
  });

  @override
  State<AnimatedGrid> createState() => _AnimatedGridState();
}

class _AnimatedGridState extends State<AnimatedGrid>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        CustomPaint(
          painter: _GridPainter(
            progress: _controller.value,
            opacity: widget.opacity,
          ),
        ),
        widget.child,
      ],
    );
  }
}

class _GridPainter extends CustomPainter {
  final double progress;
  final double opacity;

  _GridPainter({
    required this.progress,
    required this.opacity,
  });

  @override
  void paint(Canvas canvas, Size size) {
    const spacing = 32.0;

    final paint = Paint()
      ..color = JarvisColors.cyan.withValues(
        alpha: opacity,
      )
      ..strokeWidth = 0.5;

    // Vertical grid lines.
    for (double x = 0; x <= size.width; x += spacing) {
      canvas.drawLine(
        Offset(x, 0),
        Offset(x, size.height),
        paint,
      );
    }

    // Horizontal grid lines with subtle movement.
    final offset =
        (progress * spacing) % spacing;

    for (
      double y = -spacing + offset;
      y <= size.height;
      y += spacing
    ) {
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        paint,
      );
    }

    // Subtle glowing points.
    final pointPaint = Paint()
      ..color = JarvisColors.cyan.withValues(
        alpha: opacity * 2,
      );

    for (double x = 0; x <= size.width; x += spacing * 4) {
      for (double y = 0; y <= size.height; y += spacing * 4) {
        final pulse =
            0.5 + 0.5 * ((progress * 2) % 1);

        canvas.drawCircle(
          Offset(x, y),
          1.2 + pulse,
          pointPaint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(
    covariant _GridPainter oldDelegate,
  ) {
    return oldDelegate.progress != progress ||
        oldDelegate.opacity != opacity;
  }
}