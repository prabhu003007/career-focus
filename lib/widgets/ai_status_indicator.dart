import 'package:flutter/material.dart';

import '../core/theme/jarvis_colors.dart';

class AiStatusIndicator extends StatelessWidget {
  final String label;
  final bool active;
  final Color? color;

  const AiStatusIndicator({
    super.key,
    this.label = 'AI ONLINE',
    this.active = true,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final indicatorColor =
        color ?? JarvisColors.cyan;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: active
                ? indicatorColor
                : Colors.white.withValues(alpha: 0.25),
            boxShadow: active
                ? [
                    BoxShadow(
                      color: indicatorColor.withValues(alpha: 0.65),
                      blurRadius: 8,
                      spreadRadius: 1,
                    ),
                  ]
                : null,
          ),
        ),
        const SizedBox(width: 7),
        Text(
          label,
          style: TextStyle(
            color: active
                ? indicatorColor
                : Colors.white.withValues(alpha: 0.45),
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.1,
          ),
        ),
      ],
    );
  }
}