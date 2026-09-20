import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/theme/jarvis_colors.dart';

class AiCoreOrb extends StatefulWidget {
  final double size;
  final bool compact;

  const AiCoreOrb({
    super.key,
    this.size = 100,
    this.compact = false,
  });

  @override
  State<AiCoreOrb> createState() => _AiCoreOrbState();
}

class _AiCoreOrbState extends State<AiCoreOrb>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return SizedBox(
          width: widget.size,
          height: widget.size,
          child: CustomPaint(
            painter: _AiCorePainter(
              progress: _controller.value,
            ),
          ),
        );
      },
    );
  }
}

class _AiCorePainter extends CustomPainter {
  final double progress;

  _AiCorePainter({
    required this.progress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(
      size.width / 2,
      size.height / 2,
    );

    final radius = size.width * 0.30;

    // Outer glow.
    final glowPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          JarvisColors.cyan.withValues(alpha: 0.28),
          JarvisColors.blue.withValues(alpha: 0.10),
          Colors.transparent,
        ],
      ).createShader(
        Rect.fromCircle(
          center: center,
          radius: size.width * 0.48,
        ),
      );

    canvas.drawCircle(
      center,
      size.width * 0.48,
      glowPaint,
    );

    // Rotating outer rings.
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(progress * math.pi * 2);

    final ringPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..color = JarvisColors.cyan.withValues(alpha: 0.55);

    canvas.drawArc(
      Rect.fromCircle(
        center: Offset.zero,
        radius: radius + size.width * 0.10,
      ),
      0,
      math.pi * 1.25,
      false,
      ringPaint,
    );

    canvas.drawArc(
      Rect.fromCircle(
        center: Offset.zero,
        radius: radius + size.width * 0.16,
      ),
      math.pi,
      math.pi * 0.85,
      false,
      ringPaint,
    );

    canvas.restore();

    // Core.
    final corePaint = Paint()
      ..shader = const RadialGradient(
        colors: [
          Color(0xFFE8FFFF),
          Color(0xFF00E5FF),
          Color(0xFF306CFF),
          Color(0xFF151B55),
        ],
      ).createShader(
        Rect.fromCircle(
          center: center,
          radius: radius,
        ),
      );

    canvas.drawCircle(
      center,
      radius,
      corePaint,
    );

    // Core border.
    final borderPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..color = JarvisColors.cyan.withValues(alpha: 0.8);

    canvas.drawCircle(
      center,
      radius,
      borderPaint,
    );

    // Center point.
    final pointPaint = Paint()
      ..color = Colors.white
      ..maskFilter = const MaskFilter.blur(
        BlurStyle.normal,
        4,
      );

    canvas.drawCircle(
      center,
      radius * 0.20,
      pointPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _AiCorePainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}