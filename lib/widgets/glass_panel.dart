import 'dart:ui';

import 'package:flutter/material.dart';

import '../core/theme/jarvis_effects.dart';

class GlassPanel extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry margin;
  final double radius;
  final double blur;
  final Color? color;
  final Color? borderColor;

  const GlassPanel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.margin = EdgeInsets.zero,
    this.radius = 18,
    this.blur = 12,
    this.color,
    this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    final panelColor =
        color ?? const Color(0xFF0D1728);

    final panelBorder =
        borderColor ?? const Color(0xFF00E5FF);

    return Container(
      margin: margin,
      decoration: JarvisEffects.glass(
        color: panelColor,
        radius: radius,
        borderColor: panelBorder,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: blur,
            sigmaY: blur,
          ),
          child: Padding(
            padding: padding,
            child: child,
          ),
        ),
      ),
    );
  }
}

class NeonDivider extends StatelessWidget {
  final double height;
  final EdgeInsetsGeometry margin;

  const NeonDivider({
    super.key,
    this.height = 1,
    this.margin = const EdgeInsets.symmetric(vertical: 12),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      margin: margin,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Colors.transparent,
            Color(0xFF00E5FF),
            Color(0xFF6C63FF),
            Colors.transparent,
          ],
        ),
      ),
    );
  }
}