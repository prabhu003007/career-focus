import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/theme/jarvis_colors.dart';
import '../../core/theme/jarvis_effects.dart';
import '../../models/subject.dart';
import '../../services/api_service.dart';
import '../../services/profile_service.dart';
import '../../services/token_service.dart';
import '../../widgets/ai_core_orb.dart';
import '../../widgets/animated_grid.dart' as jarvis_grid;
import '../../widgets/glass_panel.dart';
import '../dashboard/marks_screen.dart';
import '../dashboard/progress_screen.dart';
import '../dashboard/schedule_screen.dart';
import '../dashboard/subjects_screen.dart';
import '../profile/profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  final ApiService _api = ApiService();
  final ProfileService _profileService = ProfileService();
  final TokenService _tokenService = TokenService();

  late final AnimationController _animationController;

  List<Subject> _subjects = [];

  String _userName = 'Student';
  int _academicYear = 1;
  bool _loading = true;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();

    _loadDashboard();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadDashboard() async {
    try {
      final token = await _tokenService.getToken();

      if (token == null || token.isEmpty) {
        if (!mounted) return;

        setState(() {
          _loading = false;
        });

        return;
      }

      final results = await Future.wait([
        _api.getSubjects(token),
        _profileService.getProfile(token),
      ]);

      final subjects = results[0] as List<Subject>;

      final profileResponse = results[1] as Map<String, dynamic>;

      final rawProfile = profileResponse['profile'];

      final profile = rawProfile is Map
          ? Map<String, dynamic>.from(rawProfile)
          : <String, dynamic>{};

      if (!mounted) return;

      setState(() {
        _subjects = subjects;

        final name = profile['name']?.toString().trim();

        _userName = name == null || name.isEmpty ? 'Student' : name;

        _academicYear =
            int.tryParse(profile['academicYear']?.toString() ?? '1') ?? 1;

        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _loading = false;
      });
    }
  }

  void _openSchedule() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const ScheduleScreen(),
      ),
    );
  }

  void _openProgress() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const ProgressScreen(),
      ),
    );
  }

  

  void _openMarks() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const MarksScreen(),
      ),
    );
  }

  Future<void> _openProfile() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const ProfileScreen(),
      ),
    );

    if (!mounted) return;

    _loadDashboard();
  }

  String _yearLabel() {
    switch (_academicYear) {
      case 1:
        return '1ST YEAR';
      case 2:
        return '2ND YEAR';
      case 3:
        return '3RD YEAR';
      default:
        return '4TH YEAR';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF030711),
      body: Stack(
        children: [
          const Positioned.fill(
            child: jarvis_grid.AnimatedGrid(
              opacity: 0.08,
              child: SizedBox.expand(),
            ),
          ),

          Positioned.fill(
            child: IgnorePointer(
              child: AnimatedBuilder(
                animation: _animationController,
                builder: (_, _) {
                  return CustomPaint(
                    painter: _AmbientPainter(
                      progress: _animationController.value,
                    ),
                  );
                },
              ),
            ),
          ),

          SafeArea(
            child: RefreshIndicator(
              color: JarvisColors.cyan,
              backgroundColor: const Color(0xFF0B1324),
              onRefresh: _loadDashboard,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(
                  18,
                  16,
                  18,
                  30,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildTopBar(),

                    const SizedBox(height: 22),

                    _buildHero(),

                    const SizedBox(height: 18),

                    _buildMetrics(),

                    const SizedBox(height: 24),

                    _sectionHeader(
                      'COMMAND CENTER',
                      'ACADEMIC CONTROL',
                    ),

                    const SizedBox(height: 12),

                    _buildCommandCenter(),

                    const SizedBox(height: 24),

                    _buildAcademicInsight(),

                    const SizedBox(height: 24),

                    _buildSystemStatus(),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // TOP BAR
  // ===========================================================================

  Widget _buildTopBar() {
    return Row(
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(13),
            gradient: JarvisEffects.cyanPurpleGradient(),
            boxShadow: JarvisEffects.glow(
              color: JarvisColors.cyan,
              blur: 18,
              opacity: 0.28,
            ),
          ),
          child: const Icon(
            Icons.psychology_outlined,
            color: Colors.white,
            size: 23,
          ),
        ),

        const SizedBox(width: 12),

        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'CAREER FOCUS',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.8,
                ),
              ),
              SizedBox(height: 2),
              Text(
                'ACADEMIC INTELLIGENCE SYSTEM',
                style: TextStyle(
                  color: Color(0xFF6D819C),
                  fontSize: 8,
                  letterSpacing: 1.1,
                ),
              ),
            ],
          ),
        ),

        GestureDetector(
          onTap: _openProfile,
          child: Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: JarvisColors.purple.withValues(
                alpha: 0.10,
              ),
              border: Border.all(
                color: JarvisColors.purple.withValues(
                  alpha: 0.35,
                ),
              ),
            ),
            child: const Icon(
              Icons.person_outline_rounded,
              color: Color(0xFFC29BFF),
              size: 20,
            ),
          ),
        ),
      ],
    );
  }

  // ===========================================================================
  // HERO
  // ===========================================================================

  Widget _buildHero() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(26),
      child: GlassPanel(
        radius: 26,
        padding: const EdgeInsets.all(18),
        borderColor: JarvisColors.cyan,
        child: SizedBox(
          height: 205,
          child: Stack(
            clipBehavior: Clip.hardEdge,
            children: [
              const Positioned(
                right: 2,
                top: 18,
                child: Opacity(
                  opacity: 0.92,
                  child: AiCoreOrb(
                    size: 132,
                  ),
                ),
              ),

              Positioned(
                left: 0,
                right: 128,
                top: 0,
                bottom: 0,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'WELCOME BACK',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: JarvisColors.cyan,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 2,
                      ),
                    ),

                    const SizedBox(height: 4),

                    Text(
                      _userName.toUpperCase(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 25,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.1,
                      ),
                    ),

                    const SizedBox(height: 3),

                    Text(
                      _yearLabel(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF7B8FA7),
                        fontSize: 8,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.3,
                      ),
                    ),

                    const SizedBox(height: 6),

                    const Text(
                      'Your academic command center is ready. Let the planner optimize your study path.',
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Color(0xFF9AAABD),
                        fontSize: 10,
                        height: 1.35,
                      ),
                    ),

                    const SizedBox(height: 8),

                    Flexible(
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: JarvisColors.cyan.withValues(
                                alpha: 0.08,
                              ),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: JarvisColors.cyan.withValues(
                                  alpha: 0.25,
                                ),
                              ),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.auto_awesome,
                                  size: 12,
                                  color: JarvisColors.cyan,
                                ),
                                SizedBox(width: 6),
                                Text(
                                  'ADAPTIVE PLANNER',
                                  style: TextStyle(
                                    color: Color(0xFFBCEFFF),
                                    fontSize: 9,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 1,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ===========================================================================
  // METRICS
  // ===========================================================================

  Widget _buildMetrics() {
    return Row(
      children: [
        Expanded(
          child: _metricCard(
            icon: Icons.menu_book_rounded,
            title: 'SUBJECTS',
            value: _loading ? '—' : '${_subjects.length}',
            subtitle: 'Active academic units',
            accent: JarvisColors.cyan,
          ),
        ),

        const SizedBox(width: 10),

        Expanded(
          child: _metricCard(
            icon: Icons.auto_awesome,
            title: 'PLANNER',
            value: 'READY',
            subtitle: 'Adaptive planner',
            accent: const Color(0xFFB77CFF),
          ),
        ),
      ],
    );
  }

  Widget _metricCard({
    required IconData icon,
    required String title,
    required String value,
    required String subtitle,
    required Color accent,
  }) {
    return GlassPanel(
      radius: 20,
      padding: const EdgeInsets.all(14),
      borderColor: accent,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(13),
              color: accent.withValues(alpha: 0.10),
              border: Border.all(
                color: accent.withValues(alpha: 0.30),
              ),
            ),
            child: Icon(
              icon,
              color: accent,
              size: 21,
            ),
          ),

          const SizedBox(height: 10),

          Text(
            title,
            style: const TextStyle(
              color: Color(0xFF70839A),
              fontSize: 8,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.1,
            ),
          ),

          const SizedBox(height: 3),

          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 17,
              fontWeight: FontWeight.w900,
            ),
          ),

          Text(
            subtitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Color(0xFF657991),
              fontSize: 8,
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // SECTION HEADER
  // ===========================================================================

  Widget _sectionHeader(
    String title,
    String subtitle,
  ) {
    return Row(
      children: [
        Container(
          width: 3,
          height: 32,
          decoration: BoxDecoration(
            color: JarvisColors.cyan,
            borderRadius: BorderRadius.circular(3),
            boxShadow: JarvisEffects.glow(
              color: JarvisColors.cyan,
              blur: 9,
              opacity: 0.6,
            ),
          ),
        ),

        const SizedBox(width: 10),

        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              subtitle,
              style: const TextStyle(
                color: Color(0xFF657991),
                fontSize: 8,
                letterSpacing: 1,
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ===========================================================================
  // COMMAND CENTER
  // ===========================================================================

  Widget _buildCommandCenter() {
    return Column(
      children: [
        _commandCard(
          title: 'SUBJECT MATRIX',
          subtitle: 'Manage subjects & topics',
          icon: Icons.menu_book_rounded,
          accent: JarvisColors.cyan,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const SubjectsScreen(),
              ),
            );
          },
        ),

        const SizedBox(height: 10),

        
        const SizedBox(height: 10),

        _commandCard(
          title: 'STUDY SCHEDULE',
          subtitle: 'Adaptive daily mission',
          icon: Icons.calendar_month_rounded,
          accent: JarvisColors.cyan,
          onTap: _openSchedule,
        ),

        const SizedBox(height: 10),

        _commandCard(
          title: 'MARKS MATRIX',
          subtitle: 'Assessments & academic analysis',
          icon: Icons.analytics_rounded,
          accent: const Color(0xFF00F5D4),
          onTap: _openMarks,
        ),

        const SizedBox(height: 10),

        _commandCard(
          title: 'ACADEMIC ANALYTICS',
          subtitle: 'Performance intelligence',
          icon: Icons.insights_rounded,
          accent: const Color(0xFF8B7CFF),
          onTap: _openProgress,
        ),
      ],
    );
  }

  Widget _commandCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color accent,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: GlassPanel(
        radius: 18,
        padding: const EdgeInsets.all(15),
        borderColor: accent,
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                color: accent.withValues(alpha: 0.10),
                border: Border.all(
                  color: accent.withValues(alpha: 0.30),
                ),
              ),
              child: Icon(
                icon,
                color: accent,
                size: 23,
              ),
            ),

            const SizedBox(width: 13),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: Color(0xFF71849C),
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),

            Icon(
              Icons.arrow_forward_ios_rounded,
              size: 14,
              color: accent,
            ),
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // ACADEMIC INSIGHT
  // ===========================================================================

  Widget _buildAcademicInsight() {
    return GlassPanel(
      radius: 20,
      padding: const EdgeInsets.all(16),
      borderColor: const Color(0xFFB77CFF),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFFB77CFF).withValues(
                alpha: 0.12,
              ),
              border: Border.all(
                color: const Color(0xFFB77CFF).withValues(
                  alpha: 0.35,
                ),
              ),
            ),
            child: const Icon(
              Icons.psychology_rounded,
              color: Color(0xFFB77CFF),
              size: 22,
            ),
          ),

          const SizedBox(width: 12),

          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'ACADEMIC INSIGHT',
                  style: TextStyle(
                    color: Color(0xFFB77CFF),
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.5,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  'Your academic data continuously informs the adaptive planner. Add topics and exam marks to activate personalized recommendations.',
                  style: TextStyle(
                    color: Color(0xFF9AAABD),
                    fontSize: 11,
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

  // ===========================================================================
  // SYSTEM STATUS
  // ===========================================================================

  Widget _buildSystemStatus() {
    return GlassPanel(
      radius: 18,
      padding: const EdgeInsets.all(15),
      borderColor: const Color(0xFF20334B),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(
                Icons.memory_rounded,
                size: 16,
                color: JarvisColors.cyan,
              ),

              const SizedBox(width: 8),

              const Expanded(
                child: Text(
                  'SYSTEM STATUS',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.2,
                  ),
                ),
              ),

              const Text(
                'ONLINE',
                style: TextStyle(
                  color: JarvisColors.green,
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          _statusRow(
            'DATABASE',
            'CONNECTED',
            JarvisColors.green,
          ),

          const SizedBox(height: 8),

          _statusRow(
            'STUDY PLANNER',
            'READY',
            JarvisColors.cyan,
          ),

          const SizedBox(height: 8),

          _statusRow(
            'PROFILE CORE',
            'SYNCED',
            const Color(0xFFB77CFF),
          ),
        ],
      ),
    );
  }

  Widget _statusRow(
    String label,
    String status,
    Color color,
  ) {
    return Row(
      children: [
        Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color,
            boxShadow: JarvisEffects.glow(
              color: color,
              blur: 7,
              opacity: 0.5,
            ),
          ),
        ),

        const SizedBox(width: 8),

        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              color: Color(0xFF71849C),
              fontSize: 9,
              letterSpacing: 0.8,
            ),
          ),
        ),

        Text(
          status,
          style: TextStyle(
            color: color,
            fontSize: 9,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.8,
          ),
        ),
      ],
    );
  }
}

// =============================================================================
// AMBIENT BACKGROUND PAINTER
// =============================================================================

class _AmbientPainter extends CustomPainter {
  final double progress;

  _AmbientPainter({
    required this.progress,
  });

  @override
  void paint(
    Canvas canvas,
    Size size,
  ) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5
      ..color = const Color(0xFF00E5FF).withValues(
        alpha: 0.035,
      );

    final center = Offset(
      size.width * 0.82,
      size.height * 0.16,
    );

    final maxRadius = size.width * 0.65;

    for (int i = 0; i < 7; i++) {
      final radius =
          maxRadius * ((i + 1) / 7) +
          math.sin(
                progress * math.pi * 2 + i,
              ) *
              5;

      canvas.drawCircle(
        center,
        radius,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(
    covariant _AmbientPainter oldDelegate,
  ) {
    return oldDelegate.progress != progress;
  }
}