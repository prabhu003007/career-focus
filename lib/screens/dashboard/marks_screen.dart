import 'package:flutter/material.dart';

import '../../core/theme/jarvis_colors.dart';
import '../../core/theme/jarvis_effects.dart';
import 'exam_marks_screen.dart';

class MarksScreen extends StatelessWidget {
  const MarksScreen({
    super.key,
  });

  void _openExam(
    BuildContext context, {
    required String examType,
    required String title,
    required Color accent,
  }) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ExamMarksScreen(
          examType: examType,
          title: title,
          accent: accent,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF020711),
      body: Stack(
        children: [
          const Positioned.fill(
            child: _MarksGrid(),
          ),

          SafeArea(
            child: Column(
              children: [
                _buildHeader(context),

                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(
                      18,
                      8,
                      18,
                      30,
                    ),
                    child: Column(
                      children: [
                        _buildIntro(),

                        const SizedBox(height: 22),

                        _buildExamCard(
                          context,
                          title: 'ASSESS 1',
                          subtitle:
                              'FIRST ASSESSMENT MARKS',
                          icon: Icons.looks_one_rounded,
                          accent: JarvisColors.cyan,
                          examType: 'assess1',
                        ),

                        const SizedBox(height: 14),

                        _buildExamCard(
                          context,
                          title: 'ASSESS 2',
                          subtitle:
                              'SECOND ASSESSMENT MARKS',
                          icon: Icons.looks_two_rounded,
                          accent: const Color(
                            0xFFB77CFF,
                          ),
                          examType: 'assess2',
                        ),

                        const SizedBox(height: 14),

                        _buildExamCard(
                          context,
                          title: 'END SEM',
                          subtitle:
                              'END SEMESTER MARKS',
                          icon: Icons.school_rounded,
                          accent: const Color(
                            0xFF00F5D4,
                          ),
                          examType: 'endSem',
                        ),

                        const SizedBox(height: 24),

                        _buildFooter(),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(
    BuildContext context,
  ) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        18,
        16,
        18,
        12,
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                borderRadius:
                    BorderRadius.circular(13),
                color: JarvisColors.cyan
                    .withValues(alpha: 0.08),
                border: Border.all(
                  color: JarvisColors.cyan
                      .withValues(alpha: 0.28),
                ),
              ),
              child: const Icon(
                Icons.arrow_back_rounded,
                color: JarvisColors.cyan,
                size: 20,
              ),
            ),
          ),

          const SizedBox(width: 12),

          const Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  'MARKS MATRIX',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.5,
                  ),
                ),
                SizedBox(height: 3),
                Text(
                  'ACADEMIC ASSESSMENT CONTROL',
                  style: TextStyle(
                    color: Color(0xFF6D819C),
                    fontSize: 8,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                  ),
                ),
              ],
            ),
          ),

          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: JarvisColors.cyan
                  .withValues(alpha: 0.07),
              border: Border.all(
                color: JarvisColors.cyan
                    .withValues(alpha: 0.25),
              ),
            ),
            child: const Icon(
              Icons.analytics_rounded,
              color: JarvisColors.cyan,
              size: 20,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIntro() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF07111F),
        borderRadius:
            BorderRadius.circular(22),
        border: Border.all(
          color: JarvisColors.cyan
              .withValues(alpha: 0.18),
        ),
        boxShadow: [
          BoxShadow(
            color: JarvisColors.cyan
                .withValues(alpha: 0.035),
            blurRadius: 25,
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: JarvisColors.cyan
                  .withValues(alpha: 0.08),
              border: Border.all(
                color: JarvisColors.cyan
                    .withValues(alpha: 0.28),
              ),
            ),
            child: const Icon(
              Icons.bar_chart_rounded,
              color: JarvisColors.cyan,
              size: 26,
            ),
          ),

          const SizedBox(width: 14),

          const Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  'ASSESSMENT CONTROL',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.1,
                  ),
                ),
                SizedBox(height: 5),
                Text(
                  'Select an assessment to enter subject-wise marks out of 100.',
                  style: TextStyle(
                    color: Color(0xFF8194AA),
                    fontSize: 10,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExamCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color accent,
    required String examType,
  }) {
    return GestureDetector(
      onTap: () {
        _openExam(
          context,
          examType: examType,
          title: title,
          accent: accent,
        );
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(17),
        decoration: BoxDecoration(
          color: const Color(0xFF07111F),
          borderRadius:
              BorderRadius.circular(22),
          border: Border.all(
            color: accent.withValues(
              alpha: 0.25,
            ),
          ),
          boxShadow: [
            BoxShadow(
              color: accent.withValues(
                alpha: 0.045,
              ),
              blurRadius: 22,
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                borderRadius:
                    BorderRadius.circular(17),
                color: accent.withValues(
                  alpha: 0.08,
                ),
                border: Border.all(
                  color: accent.withValues(
                    alpha: 0.30,
                  ),
                ),
                boxShadow:
                    JarvisEffects.glow(
                  color: accent,
                  blur: 16,
                  opacity: 0.10,
                ),
              ),
              child: Icon(
                icon,
                color: accent,
                size: 28,
              ),
            ),

            const SizedBox(width: 15),

            Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.1,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: Color(0xFF71849C),
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),

            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: accent.withValues(
                  alpha: 0.07,
                ),
                border: Border.all(
                  color: accent.withValues(
                    alpha: 0.20,
                  ),
                ),
              ),
              child: Icon(
                Icons.arrow_forward_rounded,
                color: accent,
                size: 18,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFooter() {
    return Row(
      mainAxisAlignment:
          MainAxisAlignment.center,
      children: [
        Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: JarvisColors.green,
            boxShadow: JarvisEffects.glow(
              color: JarvisColors.green,
              blur: 7,
              opacity: 0.45,
            ),
          ),
        ),
        const SizedBox(width: 8),
        const Text(
          'MARK DATA READY',
          style: TextStyle(
            color: Color(0xFF60758D),
            fontSize: 8,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.1,
          ),
        ),
      ],
    );
  }
}

class _MarksGrid extends StatelessWidget {
  const _MarksGrid();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _MarksGridPainter(),
      child: const SizedBox.expand(),
    );
  }
}

class _MarksGridPainter
    extends CustomPainter {
  @override
  void paint(
    Canvas canvas,
    Size size,
  ) {
    final paint = Paint()
      ..color = JarvisColors.cyan
          .withValues(alpha: 0.018)
      ..strokeWidth = 0.5;

    const spacing = 40.0;

    for (
      double x = 0;
      x < size.width;
      x += spacing
    ) {
      canvas.drawLine(
        Offset(x, 0),
        Offset(x, size.height),
        paint,
      );
    }

    for (
      double y = 0;
      y < size.height;
      y += spacing
    ) {
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(
    covariant _MarksGridPainter oldDelegate,
  ) {
    return false;
  }
}