import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../models/subject.dart';
import '../../models/topic.dart';
import '../../services/api_service.dart';
import '../../services/token_service.dart';

class ProgressScreen extends StatefulWidget {
  const ProgressScreen({super.key});

  @override
  State<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends State<ProgressScreen>
    with TickerProviderStateMixin {
  final ApiService _api = ApiService();
  final TokenService _tokenService = TokenService();

  late final AnimationController _backgroundController;
  late final AnimationController _entryController;

  bool _loading = true;
  String? _error;

  List<Subject> _subjects = [];
  final Map<String, List<Topic>> _subjectTopics = {};

  @override
  void initState() {
    super.initState();

    _backgroundController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();

    _entryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _loadAnalytics();
  }

  @override
  void dispose() {
    _backgroundController.dispose();
    _entryController.dispose();
    super.dispose();
  }

  // ============================================================
  // DATA
  // ============================================================

  Future<void> _loadAnalytics() async {
    if (mounted) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }

    try {
      final token = await _tokenService.getToken();

      if (token == null || token.isEmpty) {
        throw Exception(
          'Session expired. Please sign in again.',
        );
      }

      final subjects = await _api.getSubjects(token);

      final topicLists = await Future.wait(
        subjects.map(
          (subject) => _api.getTopicsBySubject(
            token,
            subject.id,
          ),
        ),
      );

      _subjectTopics.clear();

      for (int i = 0; i < subjects.length; i++) {
        _subjectTopics[subjects[i].id] = topicLists[i];
      }

      if (!mounted) return;

      setState(() {
        _subjects = subjects;
        _loading = false;
      });

      _entryController.forward(from: 0.0);
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _loading = false;
        _error = e.toString().replaceFirst(
              'Exception: ',
              '',
            );
      });
    }
  }

  // ============================================================
  // TOPIC DATA
  // ============================================================

  List<Topic> _allTopics() {
    final result = <Topic>[];

    for (final topics in _subjectTopics.values) {
      result.addAll(topics);
    }

    return result;
  }

  DateTime _dateOnly(DateTime value) {
    return DateTime(
      value.year,
      value.month,
      value.day,
    );
  }

  DateTime _currentMonday() {
    final today = _dateOnly(DateTime.now());

    return today.subtract(
      Duration(
        days: today.weekday - DateTime.monday,
      ),
    );
  }

  List<int> _weeklyCompletionData() {
    final monday = _currentMonday();

    final values = List<int>.filled(
      6,
      0,
    );

    for (final topic in _allTopics()) {
      if (!topic.completed ||
          topic.completedAt == null) {
        continue;
      }

      final completedDate =
          _dateOnly(topic.completedAt!);

      final difference =
          completedDate.difference(monday).inDays;

      if (difference >= 0 && difference <= 5) {
        values[difference]++;
      }
    }

    return values;
  }

  // ============================================================
  // EXAM VALUES
  // ============================================================

  double? _examValue(
    Subject subject,
    ExamType type,
  ) {
    switch (type) {
      case ExamType.assess1:
        return subject.exams.assess1;

      case ExamType.assess2:
        return subject.exams.assess2;

      case ExamType.endSem:
        return subject.exams.endSem;
    }
  }

  Color _barColor(int index) {
    const colors = [
      Color(0xFF00E5FF),
      Color(0xFF9C5CFF),
      Color(0xFFFF3FA4),
      Color(0xFFFFB52E),
      Color(0xFF00F58C),
      Color(0xFF4D8DFF),
      Color(0xFFFFE45E),
      Color(0xFFFF6666),
      Color(0xFF25D9D0),
      Color(0xFFB4FF4A),
    ];

    return colors[index % colors.length];
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF020711),
      body: Stack(
        children: [
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _backgroundController,
              builder: (context, child) {
                return CustomPaint(
                  painter: _HudBackgroundPainter(
                    animation:
                        _backgroundController.value,
                  ),
                );
              },
            ),
          ),
          SafeArea(
            child: _buildBody(),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return _buildLoading();
    }

    if (_error != null) {
      return _buildError();
    }

    return RefreshIndicator(
      color: const Color(0xFF00E5FF),
      backgroundColor: const Color(0xFF081323),
      onRefresh: _loadAnalytics,
      child: ListView(
        physics:
            const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          14.0,
          14.0,
          14.0,
          35.0,
        ),
        children: [
          _buildHeader(),

          const SizedBox(height: 16.0),

          // 1. TASK PERFORMANCE
          _AnimatedSection(
            controller: _entryController,
            start: 0.05,
            child: _buildTaskPerformanceCard(),
          ),

          const SizedBox(height: 16.0),

          // 2. ASSESS 1
          _AnimatedSection(
            controller: _entryController,
            start: 0.25,
            child: _buildExamCard(
              type: ExamType.assess1,
              title: 'ASSESS 1 PERFORMANCE',
              subtitle: 'MARKS ACROSS SUBJECTS',
              color: const Color(0xFF9C5CFF),
            ),
          ),

          const SizedBox(height: 16.0),

          // 3. ASSESS 2
          _AnimatedSection(
            controller: _entryController,
            start: 0.45,
            child: _buildExamCard(
              type: ExamType.assess2,
              title: 'ASSESS 2 PERFORMANCE',
              subtitle: 'MARKS ACROSS SUBJECTS',
              color: const Color(0xFFFF3FA4),
            ),
          ),

          const SizedBox(height: 16.0),

          // 4. END SEM
          _AnimatedSection(
            controller: _entryController,
            start: 0.65,
            child: _buildExamCard(
              type: ExamType.endSem,
              title: 'END SEM PERFORMANCE',
              subtitle: 'GRADE POINTS ACROSS SUBJECTS',
              color: const Color(0xFFFFB52E),
            ),
          ),

          const SizedBox(height: 22.0),

          const _Footer(),
        ],
      ),
    );
  }

  // ============================================================
  // HEADER
  // ============================================================

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          width: 54.0,
          height: 54.0,
          decoration: BoxDecoration(
            borderRadius:
                BorderRadius.circular(16.0),
            color: const Color(0xFF061A2A),
            border: Border.all(
              color: const Color(0xFF00E5FF)
                  .withValues(alpha: 0.8),
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF00E5FF)
                    .withValues(alpha: 0.20),
                blurRadius: 22.0,
              ),
            ],
          ),
          child: const Icon(
            Icons.analytics_rounded,
            color: Color(0xFF00E5FF),
            size: 30.0,
          ),
        ),

        const SizedBox(width: 13.0),

        const Expanded(
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Text(
                'ANALYTICS',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22.0,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2.0,
                ),
              ),
              SizedBox(height: 4.0),
              Text(
                'ACADEMIC PERFORMANCE',
                style: TextStyle(
                  color: Color(0xFF91B4D2),
                  fontSize: 9.0,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.8,
                ),
              ),
            ],
          ),
        ),

        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 12.0,
            vertical: 9.0,
          ),
          decoration: BoxDecoration(
            borderRadius:
                BorderRadius.circular(18.0),
            color: const Color(0xFF03251D),
            border: Border.all(
              color: const Color(0xFF00FF9D)
                  .withValues(alpha: 0.7),
            ),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _LiveDot(),
              SizedBox(width: 7.0),
              Text(
                'LIVE',
                style: TextStyle(
                  color: Color(0xFF00FF9D),
                  fontSize: 8.0,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ============================================================
  // TASK PERFORMANCE CARD
  // ============================================================

  Widget _buildTaskPerformanceCard() {
    final values =
        _weeklyCompletionData();

    return _GlassCard(
      borderColor:
          const Color(0xFF00E5FF),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          const _CardHeader(
            icon: Icons.task_alt_rounded,
            title: 'TASK PERFORMANCE',
            subtitle:
                'TOPICS COMPLETED THIS WEEK',
            color: Color(0xFF00E5FF),
          ),

          const SizedBox(height: 18.0),

          SizedBox(
            height: 330.0,
            child: _TaskPerformanceChart(
              values: values,
            ),
          ),

          const SizedBox(height: 4.0),

          const Text(
            'MONDAY — SATURDAY',
            style: TextStyle(
              color: Color(0xFF60758B),
              fontSize: 8.0,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.1,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // EXAM CARD
  // ============================================================

  Widget _buildExamCard({
    required ExamType type,
    required String title,
    required String subtitle,
    required Color color,
  }) {
    return _GlassCard(
      borderColor: color,
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          _CardHeader(
            icon: type == ExamType.endSem
                ? Icons.school_rounded
                : Icons.description_rounded,
            title: title,
            subtitle: subtitle,
            color: color,
          ),

          const SizedBox(height: 18.0),

          SizedBox(
            height: 360.0,
            child: _ExamPerformanceChart(
              subjects: _subjects,
              type: type,
              valueResolver: _examValue,
              colorResolver: _barColor,
            ),
          ),

          const SizedBox(height: 5.0),

          Text(
            type == ExamType.endSem
                ? 'Y-AXIS: GRADE POINTS • SCALE 5 — 10'
                : 'Y-AXIS: MARKS • SCALE 0 — 100',
            style: const TextStyle(
              color: Color(0xFF60758B),
              fontSize: 8.0,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.0,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // LOADING
  // ============================================================

  Widget _buildLoading() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 82.0,
            height: 82.0,
            child: AnimatedBuilder(
              animation:
                  _backgroundController,
              builder:
                  (context, child) {
                return CustomPaint(
                  painter: _LoadingPainter(
                    progress:
                        _backgroundController
                            .value,
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 18.0),

          const Text(
            'LOADING ANALYTICS',
            style: TextStyle(
              color: Color(0xFF00E5FF),
              fontSize: 10.0,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.8,
            ),
          ),

          const SizedBox(height: 7.0),

          const Text(
            'SYNCHRONIZING STUDY DATA',
            style: TextStyle(
              color: Color(0xFF51647A),
              fontSize: 8.0,
              letterSpacing: 1.2,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // ERROR
  // ============================================================

  Widget _buildError() {
    return Center(
      child: Padding(
        padding:
            const EdgeInsets.all(25.0),
        child: _GlassCard(
          borderColor:
              const Color(0xFFFF4D7D),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.warning_amber_rounded,
                color: Color(0xFFFF4D7D),
                size: 45.0,
              ),

              const SizedBox(height: 15.0),

              const Text(
                'ANALYTICS UNAVAILABLE',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 13.0,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.2,
                ),
              ),

              const SizedBox(height: 10.0),

              Text(
                _error ??
                    'Unable to load data.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Color(0xFF8190A4),
                  fontSize: 11.0,
                ),
              ),

              const SizedBox(height: 18.0),

              ElevatedButton(
                onPressed: _loadAnalytics,
                style:
                    ElevatedButton.styleFrom(
                  backgroundColor:
                      const Color(0xFF00E5FF),
                  foregroundColor:
                      const Color(0xFF001018),
                ),
                child:
                    const Text('RETRY'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// EXAM TYPE
// ============================================================================

enum ExamType {
  assess1,
  assess2,
  endSem,
}

// ============================================================================
// ANIMATED SECTION
// ============================================================================

class _AnimatedSection
    extends StatelessWidget {
  final AnimationController controller;
  final double start;
  final Widget child;

  const _AnimatedSection({
    required this.controller,
    required this.start,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (
        context,
        child,
      ) {
        final raw =
            ((controller.value - start) /
                    (1.0 - start))
                .clamp(0.0, 1.0)
                .toDouble();

        final value =
            Curves.easeOutCubic
                .transform(raw);

        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(
              0.0,
              30.0 * (1.0 - value),
            ),
            child: child,
          ),
        );
      },
      child: child,
    );
  }
}

// ============================================================================
// GLASS CARD
// ============================================================================

class _GlassCard
    extends StatelessWidget {
  final Widget child;
  final Color borderColor;

  const _GlassCard({
    required this.child,
    required this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
          const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        borderRadius:
            BorderRadius.circular(22.0),
        color: const Color(0xFF071321)
            .withValues(alpha: 0.94),
        border: Border.all(
          color: borderColor.withValues(
            alpha: 0.48,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: borderColor.withValues(
              alpha: 0.10,
            ),
            blurRadius: 32.0,
            spreadRadius: 1.0,
          ),
        ],
      ),
      child: child,
    );
  }
}

// ============================================================================
// CARD HEADER
// ============================================================================

class _CardHeader
    extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;

  const _CardHeader({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 44.0,
          height: 44.0,
          decoration: BoxDecoration(
            borderRadius:
                BorderRadius.circular(13.0),
            color:
                color.withValues(alpha: 0.10),
            border: Border.all(
              color:
                  color.withValues(alpha: 0.52),
            ),
            boxShadow: [
              BoxShadow(
                color:
                    color.withValues(alpha: 0.15),
                blurRadius: 15.0,
              ),
            ],
          ),
          child: Icon(
            icon,
            color: color,
            size: 22.0,
          ),
        ),

        const SizedBox(width: 12.0),

        Expanded(
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11.0,
                  fontWeight:
                      FontWeight.w900,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 5.0),
              Text(
                subtitle,
                style: TextStyle(
                  color:
                      color.withValues(
                    alpha: 0.75,
                  ),
                  fontSize: 7.0,
                  fontWeight:
                      FontWeight.w800,
                  letterSpacing: 1.0,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ============================================================================
// TASK PERFORMANCE CHART
// ============================================================================

class _TaskPerformanceChart
    extends StatelessWidget {
  final List<int> values;

  const _TaskPerformanceChart({
    required this.values,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(
        begin: 0.0,
        end: 1.0,
      ),
      duration:
          const Duration(milliseconds: 1200),
      curve: Curves.easeOutCubic,
      builder: (
        context,
        animation,
        child,
      ) {
        return CustomPaint(
          painter: _TaskPerformancePainter(
            values: values,
            animation: animation,
          ),
          size: Size.infinite,
        );
      },
    );
  }
}

class _TaskPerformancePainter
    extends CustomPainter {
  final List<int> values;
  final double animation;

  _TaskPerformancePainter({
    required this.values,
    required this.animation,
  });

  @override
  void paint(
    Canvas canvas,
    Size size,
  ) {
    const double left = 38.0;
    const double right = 12.0;
    const double top = 22.0;
    const double bottom = 55.0;

    final double chartWidth =
        size.width - left - right;

    final double chartHeight =
        size.height - top - bottom;

    int maximum = 5;

    for (final value in values) {
      if (value > maximum) {
        maximum = value;
      }
    }

    final double scaleMaximum =
        math.max(5, maximum).toDouble();

    _drawGrid(
      canvas: canvas,
      size: size,
      left: left,
      right: right,
      top: top,
      bottom: bottom,
      chartHeight: chartHeight,
      maximum: scaleMaximum,
    );

    if (values.isEmpty) {
      return;
    }

    final double slotWidth =
        chartWidth / values.length;

    for (int i = 0;
        i < values.length;
        i++) {
      final double value =
          values[i].toDouble();

      final double progress =
          (value / scaleMaximum)
              .clamp(0.0, 1.0)
              .toDouble();

      final double animatedProgress =
          progress * animation;

      final double barHeight =
          chartHeight *
              animatedProgress;

      final double xCenter =
          left +
              slotWidth * (i + 0.5);

      final Color color =
          _dayColor(i);

      if (barHeight > 1.0) {
        _drawGlassBar(
          canvas: canvas,
          xCenter: xCenter,
          baseline:
              top + chartHeight,
          width: math.min(
            42.0,
            slotWidth * 0.52,
          ).toDouble(),
          height: barHeight,
          color: color,
        );
      }

      final valuePainter =
          TextPainter(
        text: TextSpan(
          text: value.round().toString(),
          style: TextStyle(
            color: Colors.white,
            fontSize: 9.0,
            fontWeight:
                FontWeight.w900,
            shadows: [
              Shadow(
                color:
                    color.withValues(
                  alpha: 0.90,
                ),
                blurRadius: 9.0,
              ),
            ],
          ),
        ),
        textDirection:
            TextDirection.ltr,
      )..layout();

      final double valueY =
          value > 0
              ? math.max(
                  top,
                  top +
                      chartHeight -
                      barHeight -
                      25.0,
                ).toDouble()
              : top +
                  chartHeight -
                  20.0;

      valuePainter.paint(
        canvas,
        Offset(
          xCenter -
              valuePainter.width / 2.0,
          valueY,
        ),
      );

      final labelPainter =
          TextPainter(
        text: TextSpan(
          text: const [
            'MON',
            'TUE',
            'WED',
            'THU',
            'FRI',
            'SAT',
          ][i],
          style: TextStyle(
            color:
                color.withValues(
              alpha: 0.95,
            ),
            fontSize: 8.0,
            fontWeight:
                FontWeight.w900,
            letterSpacing: 0.5,
          ),
        ),
        textDirection:
            TextDirection.ltr,
      )..layout();

      labelPainter.paint(
        canvas,
        Offset(
          xCenter -
              labelPainter.width / 2.0,
          top +
              chartHeight +
              16.0,
        ),
      );
    }
  }

  void _drawGrid({
    required Canvas canvas,
    required Size size,
    required double left,
    required double right,
    required double top,
    required double bottom,
    required double chartHeight,
    required double maximum,
  }) {
    final paint = Paint()
      ..color = const Color(0xFF1B344B)
          .withValues(alpha: 0.75)
      ..strokeWidth = 0.7;

    for (int i = 0; i <= 4; i++) {
      final double y =
          top +
              chartHeight *
                  i /
                  4.0;

      canvas.drawLine(
        Offset(left, y),
        Offset(
          size.width - right,
          y,
        ),
        paint,
      );

      final double value =
          maximum *
              (1.0 - i / 4.0);

      final painter =
          TextPainter(
        text: TextSpan(
          text: value.round().toString(),
          style: const TextStyle(
            color: Color(0xFF687C91),
            fontSize: 8.0,
            fontWeight:
                FontWeight.w700,
          ),
        ),
        textDirection:
            TextDirection.ltr,
      )..layout();

      painter.paint(
        canvas,
        Offset(
          left -
              painter.width -
              7.0,
          y -
              painter.height /
                  2.0,
        ),
      );
    }
  }

  Color _dayColor(int index) {
    const colors = [
      Color(0xFF00E5FF),
      Color(0xFF9C5CFF),
      Color(0xFFFF3FA4),
      Color(0xFFFFB52E),
      Color(0xFF00F58C),
      Color(0xFFFF6666),
    ];

    return colors[
        index % colors.length];
  }

  void _drawGlassBar({
    required Canvas canvas,
    required double xCenter,
    required double baseline,
    required double width,
    required double height,
    required Color color,
  }) {
    _draw3DGlassBar(
      canvas: canvas,
      xCenter: xCenter,
      baseline: baseline,
      width: width,
      height: height,
      color: color,
    );
  }

  @override
  bool shouldRepaint(
    covariant _TaskPerformancePainter
        oldDelegate,
  ) {
    return oldDelegate.animation !=
            animation ||
        oldDelegate.values != values;
  }
}

// ============================================================================
// EXAM PERFORMANCE CHART
// ============================================================================

class _ExamPerformanceChart
    extends StatelessWidget {
  final List<Subject> subjects;
  final ExamType type;
  final double? Function(
    Subject,
    ExamType,
  ) valueResolver;
  final Color Function(int) colorResolver;

  const _ExamPerformanceChart({
    required this.subjects,
    required this.type,
    required this.valueResolver,
    required this.colorResolver,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(
        begin: 0.0,
        end: 1.0,
      ),
      duration:
          const Duration(milliseconds: 1250),
      curve: Curves.easeOutCubic,
      builder: (
        context,
        animation,
        child,
      ) {
        return CustomPaint(
          painter: _ExamPerformancePainter(
            subjects: subjects,
            type: type,
            values: subjects
                .map(
                  (subject) =>
                      valueResolver(
                        subject,
                        type,
                      ),
                )
                .toList(),
            colors: List.generate(
              subjects.length,
              colorResolver,
            ),
            animation: animation,
          ),
          size: Size.infinite,
        );
      },
    );
  }
}

class _ExamPerformancePainter
    extends CustomPainter {
  final List<Subject> subjects;
  final ExamType type;
  final List<double?> values;
  final List<Color> colors;
  final double animation;

  _ExamPerformancePainter({
    required this.subjects,
    required this.type,
    required this.values,
    required this.colors,
    required this.animation,
  });

  bool get isEndSem =>
      type == ExamType.endSem;

  double get minimum =>
      isEndSem ? 5.0 : 0.0;

  double get maximum =>
      isEndSem ? 10.0 : 100.0;

  @override
  void paint(
    Canvas canvas,
    Size size,
  ) {
    if (subjects.isEmpty) {
      _drawNoSubjects(canvas, size);
      return;
    }

    const double left = 40.0;
    const double right = 12.0;
    const double top = 20.0;
    const double bottom = 62.0;

    final double chartWidth =
        size.width - left - right;

    final double chartHeight =
        size.height - top - bottom;

    _drawGrid(
      canvas: canvas,
      size: size,
      left: left,
      right: right,
      top: top,
      chartHeight: chartHeight,
    );

    final double slotWidth =
        chartWidth /
            subjects.length;

    for (int i = 0;
        i < subjects.length;
        i++) {
      final double? rawValue =
          values[i];

      final Color color =
          colors[i];

      final double xCenter =
          left +
              slotWidth *
                  (i + 0.5);

      if (rawValue != null) {
        final double value =
            rawValue.clamp(
          minimum,
          maximum,
        ).toDouble();

        final double normalized =
            (value - minimum) /
                (maximum - minimum);

        final double barHeight =
            chartHeight *
                normalized *
                animation;

        if (barHeight > 1.0) {
          _draw3DGlassBar(
            canvas: canvas,
            xCenter: xCenter,
            baseline:
                top + chartHeight,
            width: math.min(
              42.0,
              slotWidth * 0.50,
            ).toDouble(),
            height: barHeight,
            color: color,
          );
        }

        final String valueText =
            isEndSem
                ? value.toStringAsFixed(
                    1,
                  )
                : value.toStringAsFixed(
                    0,
                  );

        final valuePainter =
            TextPainter(
          text: TextSpan(
            text: valueText,
            style: TextStyle(
              color: Colors.white,
              fontSize: 9.0,
              fontWeight:
                  FontWeight.w900,
              shadows: [
                Shadow(
                  color:
                      color.withValues(
                    alpha: 0.95,
                  ),
                  blurRadius: 9.0,
                ),
              ],
            ),
          ),
          textDirection:
              TextDirection.ltr,
        )..layout();

        final double valueY =
            math.max(
              top,
              top +
                  chartHeight -
                  barHeight -
                  25.0,
            ).toDouble();

        valuePainter.paint(
          canvas,
          Offset(
            xCenter -
                valuePainter.width /
                    2.0,
            valueY,
          ),
        );
      } else {
        final noDataPainter =
            TextPainter(
          text: const TextSpan(
            text: '—',
            style: TextStyle(
              color:
                  Color(0xFF566B80),
              fontSize: 13.0,
              fontWeight:
                  FontWeight.w700,
            ),
          ),
          textDirection:
              TextDirection.ltr,
        )..layout();

        noDataPainter.paint(
          canvas,
          Offset(
            xCenter -
                noDataPainter.width /
                    2.0,
            top +
                chartHeight -
                24.0,
          ),
        );
      }

      final subjectName =
          subjects[i]
              .name
              .trim()
              .isEmpty
          ? 'SUBJECT ${i + 1}'
          : subjects[i]
              .name
              .toUpperCase();

      final labelPainter =
          TextPainter(
        text: TextSpan(
          text: subjectName,
          style: TextStyle(
            color:
                color.withValues(
              alpha: 0.96,
            ),
            fontSize: 7.5,
            fontWeight:
                FontWeight.w900,
            letterSpacing: 0.3,
          ),
        ),
        textDirection:
            TextDirection.ltr,
        textAlign:
            TextAlign.center,
        maxLines: 2,
        ellipsis: '…',
      )..layout(
          maxWidth:
              slotWidth - 6.0,
        );

      labelPainter.paint(
        canvas,
        Offset(
          xCenter -
              labelPainter.width /
                  2.0,
          top +
              chartHeight +
              16.0,
        ),
      );
    }
  }

  void _drawGrid({
    required Canvas canvas,
    required Size size,
    required double left,
    required double right,
    required double top,
    required double chartHeight,
  }) {
    final paint = Paint()
      ..color = const Color(0xFF1B344B)
          .withValues(alpha: 0.75)
      ..strokeWidth = 0.7;

    for (int i = 0; i <= 5; i++) {
      final double fraction =
          i / 5.0;

      final double y =
          top +
              chartHeight *
                  fraction;

      canvas.drawLine(
        Offset(left, y),
        Offset(
          size.width - right,
          y,
        ),
        paint,
      );

      final double value =
          maximum -
              (maximum - minimum) *
                  fraction;

      final String label =
          isEndSem
              ? value.toStringAsFixed(0)
              : value.toStringAsFixed(0);

      final painter =
          TextPainter(
        text: TextSpan(
          text: label,
          style: const TextStyle(
            color: Color(0xFF687C91),
            fontSize: 8.0,
            fontWeight:
                FontWeight.w700,
          ),
        ),
        textDirection:
            TextDirection.ltr,
      )..layout();

      painter.paint(
        canvas,
        Offset(
          left -
              painter.width -
              7.0,
          y -
              painter.height /
                  2.0,
        ),
      );
    }

    canvas.drawLine(
      Offset(left, top),
      Offset(
        left,
        top + chartHeight,
      ),
      Paint()
        ..color =
            const Color(0xFF3A526A)
        ..strokeWidth = 1.0,
    );

    canvas.drawLine(
      Offset(
        left,
        top + chartHeight,
      ),
      Offset(
        size.width - right,
        top + chartHeight,
      ),
      Paint()
        ..color =
            const Color(0xFF3A526A)
        ..strokeWidth = 1.0,
    );
  }

  void _drawNoSubjects(
    Canvas canvas,
    Size size,
  ) {
    const text =
        'NO SUBJECT DATA';

    final painter =
        TextPainter(
      text: const TextSpan(
        text: text,
        style: TextStyle(
          color: Color(0xFF596D82),
          fontSize: 10.0,
          fontWeight:
              FontWeight.w800,
          letterSpacing: 1.2,
        ),
      ),
      textDirection:
          TextDirection.ltr,
    )..layout();

    painter.paint(
      canvas,
      Offset(
        size.width / 2.0 -
            painter.width / 2.0,
        size.height / 2.0 -
            painter.height / 2.0,
      ),
    );
  }

  @override
  bool shouldRepaint(
    covariant _ExamPerformancePainter
        oldDelegate,
  ) {
    return oldDelegate.animation !=
            animation ||
        oldDelegate.values != values ||
        oldDelegate.subjects !=
            subjects;
  }
}

// ============================================================================
// COMMON 3D GLASS BAR
// ============================================================================

void _draw3DGlassBar({
  required Canvas canvas,
  required double xCenter,
  required double baseline,
  required double width,
  required double height,
  required Color color,
}) {
  const double depth = 10.0;
  const double topDepth = 12.0;

  final double left =
      xCenter - width / 2.0;

  final double right =
      xCenter + width / 2.0;

  final double frontRight =
      right - depth;

  final double top =
      baseline - height;

  // ------------------------------------------------------------
  // OUTER GLOW
  // ------------------------------------------------------------

  canvas.drawRRect(
    RRect.fromRectAndRadius(
      Rect.fromLTWH(
        left + 1.0,
        top + topDepth,
        math.max(
          1.0,
          width -
              depth -
              2.0,
        ).toDouble(),
        math.max(
          1.0,
          height -
              topDepth,
        ).toDouble(),
      ),
      const Radius.circular(7.0),
    ),
    Paint()
      ..color =
          color.withValues(
        alpha: 0.36,
      )
      ..maskFilter =
          const MaskFilter.blur(
        BlurStyle.normal,
        15.0,
      ),
  );

  // ------------------------------------------------------------
  // FRONT FACE
  // ------------------------------------------------------------

  final front = Path()
    ..moveTo(
      left,
      top + topDepth,
    )
    ..lineTo(
      frontRight,
      top + topDepth,
    )
    ..lineTo(
      frontRight,
      baseline,
    )
    ..lineTo(
      left,
      baseline,
    )
    ..close();

  canvas.drawPath(
    front,
    Paint()
      ..shader = LinearGradient(
        begin:
            Alignment.topCenter,
        end:
            Alignment.bottomCenter,
        colors: [
          color.withValues(
            alpha: 0.96,
          ),
          color.withValues(
            alpha: 0.58,
          ),
          color.withValues(
            alpha: 0.16,
          ),
        ],
      ).createShader(
        Rect.fromLTWH(
          left,
          top + topDepth,
          width - depth,
          height,
        ),
      ),
  );

  // ------------------------------------------------------------
  // RIGHT DEPTH
  // ------------------------------------------------------------

  final side = Path()
    ..moveTo(
      frontRight,
      top + topDepth,
    )
    ..lineTo(
      right,
      top,
    )
    ..lineTo(
      right,
      baseline - topDepth,
    )
    ..lineTo(
      frontRight,
      baseline,
    )
    ..close();

  canvas.drawPath(
    side,
    Paint()
      ..shader = LinearGradient(
        begin:
            Alignment.topLeft,
        end:
            Alignment.bottomRight,
        colors: [
          color.withValues(
            alpha: 0.68,
          ),
          color.withValues(
            alpha: 0.13,
          ),
        ],
      ).createShader(
        Rect.fromLTWH(
          right - depth,
          top,
          depth,
          height,
        ),
      ),
  );

  // ------------------------------------------------------------
  // TOP GLASS FACE
  // ------------------------------------------------------------

  final topFace = Path()
    ..moveTo(
      left,
      top + topDepth,
    )
    ..lineTo(
      frontRight,
      top + topDepth,
    )
    ..lineTo(
      right,
      top,
    )
    ..lineTo(
      left + depth,
      top,
    )
    ..close();

  canvas.drawPath(
    topFace,
    Paint()
      ..shader = LinearGradient(
        begin:
            Alignment.topLeft,
        end:
            Alignment.bottomRight,
        colors: [
          Colors.white.withValues(
            alpha: 0.56,
          ),
          color.withValues(
            alpha: 0.88,
          ),
          color.withValues(
            alpha: 0.24,
          ),
        ],
      ).createShader(
        Rect.fromLTWH(
          left,
          top,
          width,
          topDepth,
        ),
      ),
  );

  // ------------------------------------------------------------
  // GLASS EDGES
  // ------------------------------------------------------------

  final edgePaint = Paint()
    ..style =
        PaintingStyle.stroke
    ..strokeWidth = 1.15
    ..color =
        color.withValues(
      alpha: 0.98,
    );

  canvas.drawPath(
    front,
    edgePaint,
  );

  canvas.drawPath(
    side,
    edgePaint,
  );

  canvas.drawPath(
    topFace,
    edgePaint,
  );

  // ------------------------------------------------------------
  // REFLECTION
  // ------------------------------------------------------------

  final reflection = Path()
    ..moveTo(
      left + 4.0,
      top + topDepth + 5.0,
    )
    ..lineTo(
      left + width * 0.38,
      top + topDepth + 5.0,
    )
    ..lineTo(
      left + width * 0.21,
      baseline - 7.0,
    )
    ..lineTo(
      left + 4.0,
      baseline - 7.0,
    )
    ..close();

  canvas.drawPath(
    reflection,
    Paint()
      ..shader = LinearGradient(
        begin:
            Alignment.topLeft,
        end:
            Alignment.bottomRight,
        colors: [
          Colors.white.withValues(
            alpha: 0.20,
          ),
          Colors.transparent,
        ],
      ).createShader(
        Rect.fromLTWH(
          left,
          top,
          width,
          height,
        ),
      ),
  );

  // ------------------------------------------------------------
  // TOP HIGHLIGHT
  // ------------------------------------------------------------

  canvas.drawLine(
    Offset(
      left + 5.0,
      top + topDepth + 2.0,
    ),
    Offset(
      frontRight - 5.0,
      top + topDepth + 2.0,
    ),
    Paint()
      ..color =
          Colors.white.withValues(
        alpha: 0.65,
      )
      ..strokeWidth = 1.5,
  );

  // ------------------------------------------------------------
  // FLOOR GLOW
  // ------------------------------------------------------------

  canvas.drawOval(
    Rect.fromCenter(
      center: Offset(
        xCenter -
            depth * 0.20,
        baseline + 2.0,
      ),
      width:
          width * 1.05,
      height: 10.0,
    ),
    Paint()
      ..color =
          color.withValues(
        alpha: 0.45,
      )
      ..maskFilter =
          const MaskFilter.blur(
        BlurStyle.normal,
        10.0,
      ),
  );
}

// ============================================================================
// HUD BACKGROUND
// ============================================================================

class _HudBackgroundPainter
    extends CustomPainter {
  final double animation;

  _HudBackgroundPainter({
    required this.animation,
  });

  @override
  void paint(
    Canvas canvas,
    Size size,
  ) {
    canvas.drawRect(
      Offset.zero & size,
      Paint()
        ..color =
            const Color(0xFF020711),
    );

    final gridPaint = Paint()
      ..color =
          const Color(0xFF0D2236)
              .withValues(
        alpha: 0.48,
      )
      ..strokeWidth = 0.5;

    const double grid = 32.0;

    for (
      double x = 0.0;
      x <= size.width;
      x += grid
    ) {
      canvas.drawLine(
        Offset(x, 0.0),
        Offset(x, size.height),
        gridPaint,
      );
    }

    for (
      double y = 0.0;
      y <= size.height;
      y += grid
    ) {
      canvas.drawLine(
        Offset(0.0, y),
        Offset(size.width, y),
        gridPaint,
      );
    }

    final cyanCenter =
        Offset(
      size.width *
          (0.12 +
              animation * 0.12),
      size.height * 0.10,
    );

    canvas.drawCircle(
      cyanCenter,
      220.0,
      Paint()
        ..shader =
            RadialGradient(
          colors: [
            const Color(
              0xFF00E5FF,
            ).withValues(
              alpha: 0.075,
            ),
            Colors.transparent,
          ],
        ).createShader(
          Rect.fromCircle(
            center: cyanCenter,
            radius: 220.0,
          ),
        ),
    );

    final purpleCenter =
        Offset(
      size.width *
          (0.90 -
              animation * 0.10),
      size.height * 0.65,
    );

    canvas.drawCircle(
      purpleCenter,
      240.0,
      Paint()
        ..shader =
            RadialGradient(
          colors: [
            const Color(
              0xFFB77CFF,
            ).withValues(
              alpha: 0.055,
            ),
            Colors.transparent,
          ],
        ).createShader(
          Rect.fromCircle(
            center:
                purpleCenter,
            radius: 240.0,
          ),
        ),
    );

    final scanY =
        animation * size.height;

    canvas.drawLine(
      Offset(0.0, scanY),
      Offset(
        size.width,
        scanY,
      ),
      Paint()
        ..color =
            const Color(0xFF00E5FF)
                .withValues(
          alpha: 0.025,
        )
        ..strokeWidth = 1.0,
    );
  }

  @override
  bool shouldRepaint(
    covariant _HudBackgroundPainter
        oldDelegate,
  ) {
    return oldDelegate.animation !=
        animation;
  }
}

// ============================================================================
// LOADING
// ============================================================================

class _LoadingPainter
    extends CustomPainter {
  final double progress;

  _LoadingPainter({
    required this.progress,
  });

  @override
  void paint(
    Canvas canvas,
    Size size,
  ) {
    final center = Offset(
      size.width / 2.0,
      size.height / 2.0,
    );

    final radius =
        size.width * 0.25;

    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..shader =
            const RadialGradient(
          colors: [
            Color(0xFFFFFFFF),
            Color(0xFF00E5FF),
            Color(0xFF154D9C),
          ],
        ).createShader(
          Rect.fromCircle(
            center: center,
            radius: radius,
          ),
        ),
    );

    canvas.save();

    canvas.translate(
      center.dx,
      center.dy,
    );

    canvas.rotate(
      progress *
          math.pi *
          2.0,
    );

    canvas.drawArc(
      Rect.fromCircle(
        center: Offset.zero,
        radius:
            radius + 13.0,
      ),
      0.0,
      math.pi * 1.5,
      false,
      Paint()
        ..style =
            PaintingStyle.stroke
        ..strokeWidth = 2.0
        ..color =
            const Color(0xFF00E5FF),
    );

    canvas.restore();
  }

  @override
  bool shouldRepaint(
    covariant _LoadingPainter
        oldDelegate,
  ) {
    return oldDelegate.progress !=
        progress;
  }
}

// ============================================================================
// LIVE DOT
// ============================================================================

class _LiveDot
    extends StatefulWidget {
  const _LiveDot();

  @override
  State<_LiveDot> createState() =>
      _LiveDotState();
}

class _LiveDotState
    extends State<_LiveDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController
      _controller;

  @override
  void initState() {
    super.initState();

    _controller =
        AnimationController(
      vsync: this,
      duration:
          const Duration(
        milliseconds: 900,
      ),
    )..repeat(
        reverse: true,
      );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (
        context,
        child,
      ) {
        return Container(
          width: 7.0,
          height: 7.0,
          decoration:
              BoxDecoration(
            shape:
                BoxShape.circle,
            color:
                const Color(
              0xFF00FF9D,
            ),
            boxShadow: [
              BoxShadow(
                color:
                    const Color(
                  0xFF00FF9D,
                ).withValues(
                  alpha:
                      0.25 +
                          _controller
                                  .value *
                              0.55,
                ),
                blurRadius: 7.0,
              ),
            ],
          ),
        );
      },
    );
  }
}

// ============================================================================
// FOOTER
// ============================================================================

class _Footer
    extends StatelessWidget {
  const _Footer();

  @override
  Widget build(
    BuildContext context,
  ) {
    return const Row(
      mainAxisAlignment:
          MainAxisAlignment.center,
      children: [
        SizedBox(
          width: 30.0,
          child: Divider(
            color:
                Color(0xFF203449),
          ),
        ),
        SizedBox(width: 10.0),
        Text(
          'ACADEMIC DATA  •  LIVE SYNCHRONIZATION',
          style: TextStyle(
            color:
                Color(0xFF506278),
            fontSize: 7.0,
            fontWeight:
                FontWeight.w700,
            letterSpacing: 1.2,
          ),
        ),
        SizedBox(width: 10.0),
        SizedBox(
          width: 30.0,
          child: Divider(
            color:
                Color(0xFF203449),
          ),
        ),
      ],
    );
  }
}