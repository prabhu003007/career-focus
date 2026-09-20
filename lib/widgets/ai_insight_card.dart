import 'package:flutter/material.dart';

import '../core/theme/jarvis_colors.dart';
import 'glass_panel.dart';

class AiInsightCard extends StatelessWidget {
  final String title;
  final String message;
  final IconData icon;

  const AiInsightCard({
    super.key,
    required this.title,
    required this.message,
    this.icon = Icons.psychology_outlined,
  });

  @override
  Widget build(BuildContext context) {
    return GlassPanel(
      radius: 18,
      borderColor: JarvisColors.purple,
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: JarvisColors.purple.withValues(alpha: 0.12),
              border: Border.all(
                color: JarvisColors.purple.withValues(alpha: 0.40),
              ),
            ),
            child: Icon(
              icon,
              color: JarvisColors.purple,
              size: 22,
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.auto_awesome,
                      size: 14,
                      color: JarvisColors.cyan,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        title.toUpperCase(),
                        style: TextStyle(
                          color: JarvisColors.cyan,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 7),
                Text(
                  message,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.78),
                    fontSize: 13,
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}