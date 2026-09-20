import 'dart:ui';

import 'package:flutter/material.dart';

class JarvisEffects {
  static List<BoxShadow> glow({
    Color color = const Color(0xFF00E5FF),
    double blur = 18,
    double spread = 0,
    double opacity = 0.35,
  }) {
    return [
      BoxShadow(
        color: color.withValues(alpha: opacity),
        blurRadius: blur,
        spreadRadius: spread,
      ),
    ];
  }

  static BoxDecoration glass({
    Color color = const Color(0xFF0D1728),
    double opacity = 0.72,
    double radius = 18,
    Color borderColor = const Color(0xFF00E5FF),
    double borderOpacity = 0.18,
  }) {
    return BoxDecoration(
      color: color.withValues(alpha: opacity),
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(
        color: borderColor.withValues(alpha: borderOpacity),
      ),
      boxShadow: glow(
        color: borderColor,
        blur: 20,
        opacity: 0.10,
      ),
    );
  }

  static ImageFilter blur({
    double sigmaX = 12,
    double sigmaY = 12,
  }) {
    return ImageFilter.blur(
      sigmaX: sigmaX,
      sigmaY: sigmaY,
    );
  }

  static LinearGradient cyanPurpleGradient() {
    return const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        Color(0xFF00E5FF),
        Color(0xFF6C63FF),
        Color(0xFFB84DFF),
      ],
    );
  }

  static LinearGradient backgroundGradient() {
    return const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        Color(0xFF030711),
        Color(0xFF081426),
        Color(0xFF050914),
      ],
    );
  }
}