import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/theme/jarvis_colors.dart';
import '../../services/api_service.dart';
import '../../services/notification_service.dart';
import '../../services/token_service.dart';
import 'study_plan_screen.dart';

class ScheduleScreen extends StatefulWidget {
  const ScheduleScreen({super.key});

  @override
  State<ScheduleScreen> createState() =>
      _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen>
    with SingleTickerProviderStateMixin {
  final ApiService _api = ApiService();
  final TokenService _tokenService = TokenService();
  final NotificationService _notificationService =
      NotificationService.instance;

  late final AnimationController _animationController;

  bool _loading = true;
  bool _working = false;

  Map<String, dynamic>? _schedule;

  // ============================================================
  // SCHEDULE STATE
  // ============================================================

  bool get _hasActiveSchedule {
    final schedule = _schedule;

    if (schedule == null) {
      return false;
    }

    final rawAssignments =
        schedule['assignments'];

    if (rawAssignments is! List) {
      return false;
    }

    for (final item in rawAssignments) {
      if (item is! Map) {
        continue;
      }

      final assignment =
          Map<String, dynamic>.from(item);

      if (assignment['status']?.toString() !=
          'planned') {
        continue;
      }

      final topicId =
          assignment['topicId']
              ?.toString()
              .trim();

      final unitId =
          assignment['unitId']
              ?.toString()
              .trim();

      final subjectId =
          assignment['subjectId']
              ?.toString()
              .trim();

      final date =
          assignment['date']
              ?.toString()
              .trim();

      final topicName =
          assignment['topicName']
              ?.toString()
              .trim();

      if (topicId != null &&
          topicId.isNotEmpty &&
          unitId != null &&
          unitId.isNotEmpty &&
          subjectId != null &&
          subjectId.isNotEmpty &&
          date != null &&
          date.isNotEmpty &&
          topicName != null &&
          topicName.isNotEmpty) {
        return true;
      }
    }

    return false;
  }

  // ============================================================
  // TODAY
  // ============================================================

  String get _today {
    final now = DateTime.now();

    return '${now.year}-'
        '${now.month.toString().padLeft(2, '0')}-'
        '${now.day.toString().padLeft(2, '0')}';
  }

  // ============================================================
  // LIFECYCLE
  // ============================================================

  @override
  void initState() {
    super.initState();

    _animationController =
        AnimationController(
      vsync: this,
      duration:
          const Duration(seconds: 6),
    )..repeat();

    _loadSchedule();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  // ============================================================
  // ASSIGNMENTS
  // ============================================================

  List<Map<String, dynamic>>
      get _assignments {
    final raw =
        _schedule?['assignments'];

    if (raw is! List) {
      return <Map<String, dynamic>>[];
    }

    return raw
        .whereType<Map>()
        .map(
          (item) =>
              Map<String, dynamic>.from(
            item,
          ),
        )
        .toList();
  }

  List<Map<String, dynamic>>
      get _todayAssignments {
    return _assignments.where(
      (item) {
        return item['date']?.toString() ==
                _today &&
            item['status']?.toString() !=
                'skipped';
      },
    ).toList();
  }

  List<Map<String, dynamic>>
      get _activeAssignments {
    return _assignments.where(
      (item) {
        return item['status']?.toString() ==
            'planned';
      },
    ).toList();
  }

  List<String> get _activeDates {
    final dates =
        <String>{};

    for (final assignment
        in _activeAssignments) {
      final date =
          assignment['date']
              ?.toString();

      if (date != null &&
          date.isNotEmpty) {
        dates.add(date);
      }
    }

    final result =
        dates.toList()..sort();

    return result;
  }

  int get _todayCompleted {
    return _todayAssignments.where(
      (item) {
        return item['status']
                ?.toString() ==
            'completed';
      },
    ).length;
  }

  int get _todayRemaining {
    return _todayAssignments.where(
      (item) {
        return item['status']
                ?.toString() ==
            'planned';
      },
    ).length;
  }

  double get _todayProgress {
    final total =
        _todayAssignments.length;

    if (total == 0) {
      return 0;
    }

    return (_todayCompleted /
            total)
        .clamp(0.0, 1.0);
  }

  // ============================================================
  // LOAD SCHEDULE
  // ============================================================

  Future<void> _loadSchedule() async {
    try {
      final token =
          await _tokenService.getToken();

      if (token == null ||
          token.isEmpty) {
        if (!mounted) {
          return;
        }

        setState(() {
          _loading = false;
          _schedule = null;
        });

        return;
      }

      final schedule =
          await _api.getSchedule(
        token,
      );

      if (!mounted) {
        return;
      }

      /*
       * A schedule document by itself does NOT mean that
       * scheduling has been completed.
       *
       * Only a valid planned assignment activates the
       * schedule UI.
       */
      final hasValidPlan =
          schedule != null &&
          _containsValidPlannedAssignment(
            schedule,
          );

      setState(() {
        _schedule =
            hasValidPlan
                ? schedule
                : null;

        _loading = false;
      });

      if (hasValidPlan) {
        await _syncNotifications(
          schedule,
        );
      }
    } catch (error) {
      debugPrint(
        'Schedule load error: $error',
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _loading = false;
        _schedule = null;
      });
    }
  }

  bool _containsValidPlannedAssignment(
    Map<String, dynamic> schedule,
  ) {
    final rawAssignments =
        schedule['assignments'];

    if (rawAssignments is! List) {
      return false;
    }

    for (final item
        in rawAssignments) {
      if (item is! Map) {
        continue;
      }

      final assignment =
          Map<String, dynamic>.from(
        item,
      );

      if (assignment['status']
              ?.toString() !=
          'planned') {
        continue;
      }

      final topicId =
          assignment['topicId']
              ?.toString()
              .trim();

      final unitId =
          assignment['unitId']
              ?.toString()
              .trim();

      final subjectId =
          assignment['subjectId']
              ?.toString()
              .trim();

      final date =
          assignment['date']
              ?.toString()
              .trim();

      final topicName =
          assignment['topicName']
              ?.toString()
              .trim();

      if (topicId != null &&
          topicId.isNotEmpty &&
          unitId != null &&
          unitId.isNotEmpty &&
          subjectId != null &&
          subjectId.isNotEmpty &&
          date != null &&
          date.isNotEmpty &&
          topicName != null &&
          topicName.isNotEmpty) {
        return true;
      }
    }

    return false;
  }

  // ============================================================
  // OPEN STUDY PLANNER
  // ============================================================

  Future<void> _openStudyPlanner() async {
    if (_working) {
      return;
    }

    final result =
        await Navigator.of(context)
            .push<bool>(
      MaterialPageRoute(
        builder: (_) =>
            const StudyPlanScreen(),
      ),
    );

    if (!mounted) {
      return;
    }

    if (result == true) {
      setState(() {
        _loading = true;
      });

      await _loadSchedule();

      if (!mounted) {
        return;
      }

      if (_hasActiveSchedule) {
        _showMessage(
          'Study schedule generated successfully.',
        );
      }
    }
  }

  // ============================================================
  // NOTIFICATIONS
  // ============================================================

  Future<void> _syncNotifications(
    Map<String, dynamic> schedule,
  ) async {
    try {
      final assignments =
          schedule['assignments'];

      if (assignments is! List) {
        return;
      }

      await _notificationService
          .scheduleFromAssignments(
        assignments:
            assignments,
      );

      debugPrint(
        'Study notifications synchronized.',
      );
    } catch (error) {
      debugPrint(
        'Notification synchronization error: $error',
      );
    }
  }

  // ============================================================
  // COMPLETE TOPIC
  // ============================================================

  Future<void> _completeTopic(
    Map<String, dynamic> assignment,
  ) async {
    final token =
        await _tokenService.getToken();

    if (token == null ||
        token.isEmpty) {
      _showMessage(
        'Session expired.',
        error: true,
      );
      return;
    }

    /*
     * Backend enrichment returns topicId directly on the
     * assignment. Do not expect a nested topic object.
     */
    final topicId =
        assignment['topicId']
            ?.toString();

    final date =
        assignment['date']
            ?.toString();

    if (topicId == null ||
        topicId.isEmpty ||
        date == null ||
        date.isEmpty) {
      _showMessage(
        'Scheduled topic information is unavailable.',
        error: true,
      );
      return;
    }

    try {
      setState(() {
        _working = true;
      });

      await _api.completeScheduledTopic(
        token,
        topicId: topicId,
        date: date,
      );

      await _loadSchedule();

      if (!mounted) {
        return;
      }

      setState(() {
        _working = false;
      });

      _showMessage(
        'Topic completed.',
      );
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _working = false;
      });

      _showMessage(
        _cleanError(error),
        error: true,
      );
    }
  }

  // ============================================================
  // THAT'S ALL FOR TODAY
  // ============================================================

  Future<void> _finishToday() async {
    if (_todayRemaining == 0) {
      _showMessage(
        'All scheduled topics are complete.',
      );
      return;
    }

    final remaining =
        _todayRemaining;

    final action =
        await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (
        dialogContext,
      ) {
        return AlertDialog(
          backgroundColor:
              const Color(
            0xFF0A1322,
          ),
          shape:
              RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(
              22,
            ),
          ),
          title:
              const Text(
            'TODAY\'S MISSION',
            style:
                TextStyle(
              color:
                  Colors.white,
              fontWeight:
                  FontWeight.w900,
              letterSpacing:
                  1,
            ),
          ),
          content:
              Text(
            'Still $remaining topic${remaining == 1 ? '' : 's'} are pending.',
            style:
                const TextStyle(
              color:
                  Color(
                0xFF91A4BA,
              ),
              height:
                  1.5,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                  'cancel',
                );
              },
              child:
                  const Text(
                'CANCEL',
              ),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                  'skip',
                );
              },
              child:
                  const Text(
                'SKIP',
              ),
            ),
          ],
        );
      },
    );

    if (action != 'skip') {
      return;
    }

    await _skipRemaining();
  }

  // ============================================================
  // SKIP / RESCHEDULE
  // ============================================================

  Future<void> _skipRemaining() async {
    if (_todayRemaining <= 0) {
      return;
    }

    final token =
        await _tokenService.getToken();

    if (token == null ||
        token.isEmpty) {
      _showMessage(
        'Session expired.',
        error: true,
      );
      return;
    }

    try {
      setState(() {
        _working = true;
      });

      await _api.skipRemainingTopics(
        token,
        date: _today,
      );

      await _loadSchedule();

      if (!mounted) {
        return;
      }

      setState(() {
        _working = false;
      });

      await showDialog<void>(
        context: context,
        builder: (
          dialogContext,
        ) {
          return AlertDialog(
            backgroundColor:
                const Color(
              0xFF0A1322,
            ),
            shape:
                RoundedRectangleBorder(
              borderRadius:
                  BorderRadius.circular(
                22,
              ),
            ),
            title:
                const Text(
              'SCHEDULE UPDATED',
              style:
                  TextStyle(
                color:
                    Colors.white,
                fontWeight:
                    FontWeight.w900,
                letterSpacing:
                    1,
              ),
            ),
            content:
                const Text(
              'Incomplete topics are rescheduled to upcoming days.',
              style:
                  TextStyle(
                color:
                    Color(
                  0xFF91A4BA,
                ),
                height:
                    1.5,
              ),
            ),
            actions: [
              FilledButton(
                onPressed: () {
                  Navigator.pop(
                    dialogContext,
                  );
                },
                child:
                    const Text(
                  'OK',
                ),
              ),
            ],
          );
        },
      );
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _working = false;
      });

      _showMessage(
        _cleanError(error),
        error: true,
      );
    }
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(
    BuildContext context,
  ) {
    return Scaffold(
      backgroundColor:
          const Color(
        0xFF030711,
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child:
                IgnorePointer(
              child:
                  AnimatedBuilder(
                animation:
                    _animationController,
                builder:
                    (
                  context,
                  child,
                ) {
                  return CustomPaint(
                    painter:
                        _ScheduleBackgroundPainter(
                      progress:
                          _animationController
                              .value,
                    ),
                  );
                },
              ),
            ),
          ),
          SafeArea(
            child: _loading
                ? _buildLoading()
                : RefreshIndicator(
                    color:
                        JarvisColors.cyan,
                    backgroundColor:
                        const Color(
                      0xFF0B1324,
                    ),
                    onRefresh:
                        _loadSchedule,
                    child:
                        ListView(
                      physics:
                          const AlwaysScrollableScrollPhysics(),
                      padding:
                          const EdgeInsets.fromLTRB(
                        18,
                        16,
                        18,
                        42,
                      ),
                      children: [
                        _buildHeader(),

                        const SizedBox(
                          height: 20,
                        ),

                        if (!_hasActiveSchedule)
                          _buildNoPlan()
                        else
                          _buildActivePlan(),
                      ],
                    ),
                  ),
          ),
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
          width: 46,
          height: 46,
          decoration:
              BoxDecoration(
            borderRadius:
                BorderRadius.circular(
              15,
            ),
            color:
                JarvisColors.cyan
                    .withValues(
              alpha: 0.08,
            ),
            border:
                Border.all(
              color:
                  JarvisColors.cyan
                      .withValues(
                alpha: 0.28,
              ),
            ),
            boxShadow: [
              BoxShadow(
                color:
                    JarvisColors.cyan
                        .withValues(
                  alpha: 0.08,
                ),
                blurRadius:
                    20,
              ),
            ],
          ),
          child:
              const Icon(
            Icons
                .calendar_month_rounded,
            color:
                JarvisColors.cyan,
          ),
        ),

        const SizedBox(
          width: 12,
        ),

        const Expanded(
          child:
              Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Text(
                'STUDY SCHEDULE',
                style:
                    TextStyle(
                  color:
                      Colors.white,
                  fontSize:
                      17,
                  fontWeight:
                      FontWeight.w900,
                  letterSpacing:
                      1.5,
                ),
              ),
              SizedBox(
                height: 4,
              ),
              Text(
                'ACADEMIC COMMAND CENTER',
                style:
                    TextStyle(
                  color:
                      Color(
                    0xFF627994,
                  ),
                  fontSize:
                      8,
                  fontWeight:
                      FontWeight.w700,
                  letterSpacing:
                      1.1,
                ),
              ),
            ],
          ),
        ),

        _statusBadge(),
      ],
    );
  }

  Widget _statusBadge() {
    final active =
        _hasActiveSchedule;

    return Container(
      padding:
          const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 7,
      ),
      decoration:
          BoxDecoration(
        borderRadius:
            BorderRadius.circular(
          30,
        ),
        color:
            (active
                    ? JarvisColors.green
                    : JarvisColors.cyan)
                .withValues(
          alpha: 0.08,
        ),
        border:
            Border.all(
          color:
              (active
                      ? JarvisColors.green
                      : JarvisColors.cyan)
                  .withValues(
            alpha: 0.25,
          ),
        ),
      ),
      child:
          Row(
        mainAxisSize:
            MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration:
                BoxDecoration(
              shape:
                  BoxShape.circle,
              color: active
                  ? JarvisColors.green
                  : JarvisColors.cyan,
            ),
          ),
          const SizedBox(
            width: 6,
          ),
          Text(
            active
                ? 'ACTIVE'
                : 'READY',
            style:
                TextStyle(
              color: active
                  ? const Color(
                      0xFF6EE7B7,
                    )
                  : const Color(
                      0xFF67E8F9,
                    ),
              fontSize:
                  8,
              fontWeight:
                  FontWeight.w800,
              letterSpacing:
                  1,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // NO PLAN
  // ============================================================

  Widget _buildNoPlan() {
    return Column(
      children: [
        const SizedBox(
          height: 30,
        ),

        _buildCoreOrb(),

        const SizedBox(
          height: 24,
        ),

        _panel(
          radius: 26,
          borderColor:
              JarvisColors.cyan,
          padding:
              const EdgeInsets.all(
            22,
          ),
          child:
              Column(
            children: [
              const Text(
                'NO STUDY SCHEDULE',
                textAlign:
                    TextAlign.center,
                style:
                    TextStyle(
                  color:
                      Colors.white,
                  fontSize:
                      18,
                  fontWeight:
                      FontWeight.w900,
                  letterSpacing:
                      1.1,
                ),
              ),

              const SizedBox(
                height: 10,
              ),

              const Text(
                'Configure your subjects, deadlines, units and topics to build your study schedule.',
                textAlign:
                    TextAlign.center,
                style:
                    TextStyle(
                  color:
                      Color(
                    0xFF71869D,
                  ),
                  fontSize:
                      10,
                  height:
                      1.55,
                ),
              ),

              const SizedBox(
                height: 22,
              ),

              _buildGenerateButton(),
            ],
          ),
        ),
      ],
    );
  }

  // ============================================================
  // ACTIVE PLAN
  // ============================================================

  Widget _buildActivePlan() {
    return Column(
      children: [
        _buildPlanOverview(),

        const SizedBox(
          height: 14,
        ),

        _buildViewScheduleButton(),

        const SizedBox(
          height: 18,
        ),

        _buildTodayHeader(),

        const SizedBox(
          height: 12,
        ),

        if (_todayAssignments.isEmpty)
          _buildTodayClear()
        else
          ..._todayAssignments.map(
            _buildTodayTask,
          ),

        if (_todayRemaining > 0) ...[
          const SizedBox(
            height: 14,
          ),
          _buildFinishTodayButton(),
        ],
      ],
    );
  }

  // ============================================================
  // PLAN OVERVIEW
  // ============================================================

  Widget _buildPlanOverview() {
    return _panel(
      radius: 24,
      borderColor:
          const Color(
        0xFF304B69,
      ),
      padding:
          const EdgeInsets.all(
        18,
      ),
      child:
          Row(
        children: [
          _buildProgressOrb(),

          const SizedBox(
            width: 15,
          ),

          Expanded(
            child:
                Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                const Text(
                  'PLAN ACTIVE',
                  style:
                      TextStyle(
                    color:
                        JarvisColors.cyan,
                    fontSize:
                        9,
                    fontWeight:
                        FontWeight.w900,
                    letterSpacing:
                        1.5,
                  ),
                ),

                const SizedBox(
                  height: 6,
                ),

                Text(
                  '${_activeAssignments.length} ACTIVE TOPICS',
                  style:
                      const TextStyle(
                    color:
                        Colors.white,
                    fontSize:
                        17,
                    fontWeight:
                        FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressOrb() {
    final progress =
        _todayProgress;

    return SizedBox(
      width: 76,
      height: 76,
      child:
          Stack(
        alignment:
            Alignment.center,
        children: [
          SizedBox(
            width: 72,
            height: 72,
            child:
                CircularProgressIndicator(
              value:
                  progress,
              strokeWidth:
                  4,
              backgroundColor:
                  const Color(
                0xFF16263A,
              ),
              valueColor:
                  const AlwaysStoppedAnimation<
                      Color>(
                JarvisColors.cyan,
              ),
            ),
          ),
          Text(
            '${(progress * 100).round()}%',
            style:
                const TextStyle(
              color:
                  Colors.white,
              fontSize:
                  13,
              fontWeight:
                  FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // VIEW SCHEDULE
  // ============================================================

  Widget _buildViewScheduleButton() {
    return SizedBox(
      width:
          double.infinity,
      height: 55,
      child:
          FilledButton(
        onPressed:
            _activeDates.isEmpty
                ? null
                : _openScheduleDates,
        style:
            FilledButton.styleFrom(
          backgroundColor:
              const Color(
            0xFF0A1728,
          ),
          disabledBackgroundColor:
              const Color(
            0xFF111B2B,
          ),
          shape:
              RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(
              17,
            ),
            side:
                BorderSide(
              color:
                  JarvisColors.cyan
                      .withValues(
                alpha:
                    0.42,
              ),
            ),
          ),
        ),
        child:
            const Row(
          mainAxisAlignment:
              MainAxisAlignment.center,
          children: [
            Icon(
              Icons
                  .view_agenda_rounded,
              color:
                  JarvisColors.cyan,
              size:
                  20,
            ),
            SizedBox(
              width: 9,
            ),
            Text(
              'VIEW SCHEDULE',
              style:
                  TextStyle(
                color:
                    Colors.white,
                fontSize:
                    10,
                fontWeight:
                    FontWeight.w900,
                letterSpacing:
                    1.4,
              ),
            ),
            SizedBox(
              width: 8,
            ),
            Icon(
              Icons
                  .arrow_forward_ios_rounded,
              color:
                  Color(
                0xFF617A94,
              ),
              size:
                  12,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openScheduleDates() async {
    final schedule =
        _schedule;

    if (schedule == null) {
      return;
    }

    await Navigator.of(
      context,
    ).push(
      MaterialPageRoute(
        builder: (_) =>
            ScheduleDatesScreen(
          schedule:
              schedule,
        ),
      ),
    );

    if (!mounted) {
      return;
    }

    await _loadSchedule();
  }

  // ============================================================
  // TODAY HEADER
  // ============================================================

  Widget _buildTodayHeader() {
    return Row(
      children: [
        Container(
          width: 3,
          height: 28,
          decoration:
              BoxDecoration(
            color:
                JarvisColors.cyan,
            borderRadius:
                BorderRadius.circular(
              4,
            ),
          ),
        ),

        const SizedBox(
          width: 9,
        ),

        const Expanded(
          child:
              Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Text(
                'TODAY\'S MISSION',
                style:
                    TextStyle(
                  color:
                      Colors.white,
                  fontSize:
                      12,
                  fontWeight:
                      FontWeight.w900,
                  letterSpacing:
                      1.3,
                ),
              ),
              SizedBox(
                height: 3,
              ),
              Text(
                'COMPLETE OR RESCHEDULE',
                style:
                    TextStyle(
                  color:
                      Color(
                    0xFF60758F,
                  ),
                  fontSize:
                      7,
                  letterSpacing:
                      1,
                ),
              ),
            ],
          ),
        ),

        Text(
          '$_todayCompleted/$_todayAssignments.length',
          style:
              const TextStyle(
            color:
                JarvisColors.cyan,
            fontSize:
                13,
            fontWeight:
                FontWeight.w900,
          ),
        ),
      ],
    );
  }

  // ============================================================
  // TODAY TASK
  // ============================================================

  Widget _buildTodayTask(
    Map<String, dynamic> assignment,
  ) {
    final completed =
        assignment['status']
                ?.toString() ==
            'completed';

    return Padding(
      padding:
          const EdgeInsets.only(
        bottom: 9,
      ),
      child:
          _panel(
        radius:
            18,
        borderColor:
            completed
                ? JarvisColors.green
                : const Color(
                    0xFF263D59,
                  ),
        padding:
            const EdgeInsets.all(
          13,
        ),
        child:
            Row(
          children: [
            Container(
              width:
                  39,
              height:
                  39,
              decoration:
                  BoxDecoration(
                shape:
                    BoxShape.circle,
                color:
                    (completed
                            ? JarvisColors
                                .green
                            : JarvisColors
                                .cyan)
                        .withValues(
                  alpha:
                      0.08,
                ),
                border:
                    Border.all(
                  color:
                      (completed
                              ? JarvisColors
                                  .green
                              : JarvisColors
                                  .cyan)
                          .withValues(
                    alpha:
                        0.28,
                  ),
                ),
              ),
              child:
                  Icon(
                completed
                    ? Icons
                        .check_rounded
                    : Icons
                        .play_arrow_rounded,
                color:
                    completed
                        ? JarvisColors
                            .green
                        : JarvisColors
                            .cyan,
                size:
                    19,
              ),
            ),

            const SizedBox(
              width: 11,
            ),

            Expanded(
              child:
                  Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Text(
                    _topicName(
                      assignment,
                    ),
                    maxLines:
                        2,
                    overflow:
                        TextOverflow.ellipsis,
                    style:
                        TextStyle(
                      color: completed
                          ? const Color(
                              0xFFB7F7D6,
                            )
                          : Colors
                              .white,
                      fontSize:
                          11,
                      fontWeight:
                          FontWeight.w800,
                    ),
                  ),

                  const SizedBox(
                    height: 5,
                  ),

                  Text(
                    '${_subjectName(assignment)}  •  ${_unitNumber(assignment)}',
                    maxLines:
                        1,
                    overflow:
                        TextOverflow.ellipsis,
                    style:
                        TextStyle(
                      color: completed
                          ? JarvisColors
                              .green
                          : const Color(
                              0xFF6D839B,
                            ),
                      fontSize:
                          7,
                      fontWeight:
                          FontWeight.w700,
                      letterSpacing:
                          0.7,
                    ),
                  ),
                ],
              ),
            ),

            if (!completed)
              IconButton(
                onPressed:
                    _working
                        ? null
                        : () =>
                            _confirmComplete(
                              assignment,
                            ),
                icon:
                    const Icon(
                  Icons
                      .check_circle_outline_rounded,
                  color:
                      Color(
                    0xFF67E8F9,
                  ),
                  size:
                      22,
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // COMPLETE CONFIRMATION
  // ============================================================

  Future<void> _confirmComplete(
    Map<String, dynamic> assignment,
  ) async {
    final confirmed =
        await showDialog<bool>(
      context: context,
      builder: (
        dialogContext,
      ) {
        return AlertDialog(
          backgroundColor:
              const Color(
            0xFF0B1324,
          ),
          shape:
              RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(
              20,
            ),
          ),
          title:
              const Text(
            'COMPLETE TOPIC',
            style:
                TextStyle(
              color:
                  Colors.white,
              fontWeight:
                  FontWeight.w900,
            ),
          ),
          content:
              Text(
            'Mark "${_topicName(assignment)}" as completed?',
            style:
                const TextStyle(
              color:
                  Color(
                0xFF9AAFC4,
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                  false,
                );
              },
              child:
                  const Text(
                'CANCEL',
              ),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                  true,
                );
              },
              child:
                  const Text(
                'COMPLETE',
              ),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      await _completeTopic(
        assignment,
      );
    }
  }

  // ============================================================
  // FINISH TODAY
  // ============================================================

  Widget _buildFinishTodayButton() {
    return SizedBox(
      width:
          double.infinity,
      height:
          53,
      child:
          OutlinedButton(
        onPressed:
            _working
                ? null
                : _finishToday,
        style:
            OutlinedButton.styleFrom(
          foregroundColor:
              const Color(
            0xFFFFC857,
          ),
          side:
              BorderSide(
            color:
                const Color(
              0xFFFFC857,
            ).withValues(
              alpha:
                  0.35,
            ),
          ),
          shape:
              RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(
              16,
            ),
          ),
        ),
        child:
            const Text(
          'THAT\'S ALL FOR TODAY',
          style:
              TextStyle(
            fontSize:
                9,
            fontWeight:
                FontWeight.w900,
            letterSpacing:
                1.3,
          ),
        ),
      ),
    );
  }

  // ============================================================
  // TODAY CLEAR
  // ============================================================

  Widget _buildTodayClear() {
    return _panel(
      radius:
          20,
      borderColor:
          JarvisColors.green,
      padding:
          const EdgeInsets.all(
        24,
      ),
      child:
          const Column(
        children: [
          Icon(
            Icons
                .check_circle_outline_rounded,
            color:
                JarvisColors.green,
            size:
                43,
          ),
          SizedBox(
            height: 10,
          ),
          Text(
            'TODAY IS CLEAR',
            style:
                TextStyle(
              color:
                  Colors.white,
              fontSize:
                  16,
              fontWeight:
                  FontWeight.w900,
              letterSpacing:
                  1,
            ),
          ),
          SizedBox(
            height: 6,
          ),
          Text(
            'No unfinished topics remain for today.',
            textAlign:
                TextAlign.center,
            style:
                TextStyle(
              color:
                  Color(
                0xFF71859B,
              ),
              fontSize:
                  10,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // GENERATE BUTTON
  // ============================================================

  Widget _buildGenerateButton() {
    return SizedBox(
      width:
          double.infinity,
      height:
          53,
      child:
          FilledButton(
        onPressed:
            _working
                ? null
                : _openStudyPlanner,
        style:
            FilledButton.styleFrom(
          backgroundColor:
              const Color(
            0xFF0A1728,
          ),
          shape:
              RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(
              16,
            ),
            side:
                BorderSide(
              color:
                  JarvisColors.cyan
                      .withValues(
                alpha:
                    0.45,
              ),
            ),
          ),
        ),
        child:
            const Row(
          mainAxisAlignment:
              MainAxisAlignment.center,
          children: [
            Icon(
              Icons
                  .calendar_month_rounded,
              color:
                  JarvisColors.cyan,
              size:
                  18,
            ),
            SizedBox(
              width: 8,
            ),
            Text(
              'GENERATE STUDY SCHEDULE',
              style:
                  TextStyle(
                color:
                    Colors.white,
                fontSize:
                    10,
                fontWeight:
                    FontWeight.w900,
                letterSpacing:
                    1.2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // CORE ORB
  // ============================================================

  Widget _buildCoreOrb() {
    return SizedBox(
      width:
          130,
      height:
          130,
      child:
          Stack(
        alignment:
            Alignment.center,
        children: [
          AnimatedBuilder(
            animation:
                _animationController,
            builder:
                (
              context,
              child,
            ) {
              return Transform.rotate(
                angle:
                    _animationController
                            .value *
                        math.pi *
                        2,
                child:
                    Container(
                  width:
                      120,
                  height:
                      120,
                  decoration:
                      BoxDecoration(
                    shape:
                        BoxShape.circle,
                    border:
                        Border.all(
                      color:
                          JarvisColors.cyan
                              .withValues(
                        alpha:
                            0.22,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
          Container(
            width:
                74,
            height:
                74,
            decoration:
                BoxDecoration(
              shape:
                  BoxShape.circle,
              color:
                  JarvisColors.cyan
                      .withValues(
                alpha:
                    0.07,
              ),
              border:
                  Border.all(
                color:
                    JarvisColors.cyan
                        .withValues(
                  alpha:
                      0.42,
                ),
              ),
              boxShadow: [
                BoxShadow(
                  color:
                      JarvisColors.cyan
                          .withValues(
                    alpha:
                        0.18,
                  ),
                  blurRadius:
                      30,
                ),
              ],
            ),
            child:
                const Icon(
              Icons
                  .calendar_month_rounded,
              color:
                  JarvisColors.cyan,
              size:
                  31,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // ASSIGNMENT DATA
  // ============================================================

  String _subjectName(
    Map<String, dynamic> assignment,
  ) {
    final name =
        assignment['subjectName']
            ?.toString()
            .trim();

    if (name != null &&
        name.isNotEmpty) {
      return name;
    }

    return 'SUBJECT';
  }

  String _topicName(
    Map<String, dynamic> assignment,
  ) {
    final name =
        assignment['topicName']
            ?.toString()
            .trim();

    if (name != null &&
        name.isNotEmpty) {
      return name;
    }

    return 'TOPIC';
  }

  String _unitNumber(
    Map<String, dynamic> assignment,
  ) {
    final value =
        assignment['unitNumber'];

    if (value == null) {
      return 'UNIT —';
    }

    return 'UNIT ${value.toString()}';
  }

  // ============================================================
  // HELPERS
  // ============================================================

  String _cleanError(
    Object error,
  ) {
    return error
        .toString()
        .replaceFirst(
          'Exception: ',
          '',
        );
  }

  void _showMessage(
    String message, {
    bool error = false,
  }) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(
      context,
    ).hideCurrentSnackBar();

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(
      SnackBar(
        behavior:
            SnackBarBehavior.floating,
        backgroundColor:
            error
                ? const Color(
                    0xFF7F1D1D,
                  )
                : const Color(
                    0xFF10284A,
                  ),
        shape:
            RoundedRectangleBorder(
          borderRadius:
              BorderRadius.circular(
            16,
          ),
        ),
        content:
            Text(
          message,
          style:
              const TextStyle(
            color:
                Colors.white,
            fontWeight:
                FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _panel({
    required Widget child,
    required double radius,
    required Color borderColor,
    required EdgeInsets padding,
  }) {
    return Container(
      width:
          double.infinity,
      padding:
          padding,
      decoration:
          BoxDecoration(
        color:
            const Color(
          0xCC081221,
        ),
        borderRadius:
            BorderRadius.circular(
          radius,
        ),
        border:
            Border.all(
          color:
              borderColor.withValues(
            alpha:
                0.55,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color:
                Colors.black.withValues(
              alpha:
                  0.24,
            ),
            blurRadius:
                18,
            offset:
                const Offset(
              0,
              8,
            ),
          ),
        ],
      ),
      child:
          child,
    );
  }

  Widget _buildLoading() {
    return Center(
      child:
          Column(
        mainAxisAlignment:
            MainAxisAlignment.center,
        children: [
          SizedBox(
            width:
                78,
            height:
                78,
            child:
                CircularProgressIndicator(
              strokeWidth:
                  2.5,
              color:
                  JarvisColors.cyan,
              backgroundColor:
                  const Color(
                0xFF17283D,
              ),
            ),
          ),
          const SizedBox(
            height: 18,
          ),
          const Text(
            'LOADING SCHEDULE',
            style:
                TextStyle(
              color:
                  JarvisColors.cyan,
              fontSize:
                  10,
              fontWeight:
                  FontWeight.w900,
              letterSpacing:
                  1.8,
            ),
          ),
        ],
      ),
    );
  }
}

// ================================================================
// DATE LIST
// ================================================================

class ScheduleDatesScreen
    extends StatelessWidget {
  final Map<String, dynamic> schedule;

  const ScheduleDatesScreen({
    super.key,
    required this.schedule,
  });

  List<Map<String, dynamic>>
      get _activeAssignments {
    final raw =
        schedule['assignments'];

    if (raw is! List) {
      return <Map<String, dynamic>>[];
    }

    return raw
        .whereType<Map>()
        .map(
          (item) =>
              Map<String, dynamic>.from(
            item,
          ),
        )
        .where(
          (item) =>
              item['status']
                  ?.toString() ==
              'planned',
        )
        .where(
          (item) {
            final topicId =
                item['topicId']
                    ?.toString()
                    .trim();

            final topicName =
                item['topicName']
                    ?.toString()
                    .trim();

            final date =
                item['date']
                    ?.toString()
                    .trim();

            return topicId != null &&
                topicId.isNotEmpty &&
                topicName != null &&
                topicName.isNotEmpty &&
                date != null &&
                date.isNotEmpty;
          },
        )
        .toList();
  }

  List<String> get _dates {
    final values =
        <String>{};

    for (final assignment
        in _activeAssignments) {
      final date =
          assignment['date']
              ?.toString();

      if (date != null &&
          date.isNotEmpty) {
        values.add(date);
      }
    }

    return values.toList()
      ..sort();
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    return Scaffold(
      backgroundColor:
          const Color(
        0xFF030711,
      ),
      appBar:
          AppBar(
        backgroundColor:
            Colors.transparent,
        elevation:
            0,
        title:
            const Text(
          'SCHEDULE',
          style:
              TextStyle(
            color:
                Colors.white,
            fontSize:
                15,
            fontWeight:
                FontWeight.w900,
            letterSpacing:
                1.8,
          ),
        ),
      ),
      body:
          _dates.isEmpty
              ? const Center(
                  child:
                      Text(
                    'NO ACTIVE SCHEDULE',
                    style:
                        TextStyle(
                      color:
                          Color(
                        0xFF71869D,
                      ),
                      fontWeight:
                          FontWeight.w700,
                      letterSpacing:
                          1,
                    ),
                  ),
                )
              : ListView.builder(
                  padding:
                      const EdgeInsets.fromLTRB(
                    18,
                    10,
                    18,
                    35,
                  ),
                  itemCount:
                      _dates.length,
                  itemBuilder:
                      (
                    context,
                    index,
                  ) {
                    final date =
                        _dates[index];

                    final count =
                        _activeAssignments
                            .where(
                              (item) =>
                                  item['date']
                                      ?.toString() ==
                                  date,
                            )
                            .length;

                    return Padding(
                      padding:
                          const EdgeInsets.only(
                        bottom:
                            12,
                      ),
                      child:
                          _dateCard(
                        context,
                        date,
                        count,
                      ),
                    );
                  },
                ),
    );
  }

  Widget _dateCard(
    BuildContext context,
    String date,
    int count,
  ) {
    final parsed =
        DateTime.tryParse(date);

    final day =
        parsed?.day.toString() ??
            '--';

    const months = [
      'JAN',
      'FEB',
      'MAR',
      'APR',
      'MAY',
      'JUN',
      'JUL',
      'AUG',
      'SEP',
      'OCT',
      'NOV',
      'DEC',
    ];

    final month =
        parsed == null
            ? ''
            : months[
                parsed.month - 1];

    return InkWell(
      borderRadius:
          BorderRadius.circular(
        20,
      ),
      onTap: () {
        Navigator.of(
          context,
        ).push(
          MaterialPageRoute(
            builder: (_) =>
                ScheduleDateDetailScreen(
              date:
                  date,
              assignments:
                  _activeAssignments
                      .where(
                        (item) =>
                            item['date']
                                ?.toString() ==
                            date,
                      )
                      .toList(),
            ),
          ),
        );
      },
      child:
          Container(
        padding:
            const EdgeInsets.all(
          17,
        ),
        decoration:
            BoxDecoration(
          color:
              const Color(
            0xCC081221,
          ),
          borderRadius:
              BorderRadius.circular(
            20,
          ),
          border:
              Border.all(
            color:
                JarvisColors.cyan
                    .withValues(
              alpha:
                  0.25,
            ),
          ),
        ),
        child:
            Row(
          children: [
            Container(
              width:
                  62,
              height:
                  62,
              decoration:
                  BoxDecoration(
                borderRadius:
                    BorderRadius.circular(
                  16,
                ),
                color:
                    JarvisColors.cyan
                        .withValues(
                  alpha:
                      0.07,
                ),
                border:
                    Border.all(
                  color:
                      JarvisColors.cyan
                          .withValues(
                    alpha:
                        0.22,
                  ),
                ),
              ),
              child:
                  Column(
                mainAxisAlignment:
                    MainAxisAlignment.center,
                children: [
                  Text(
                    day,
                    style:
                        const TextStyle(
                      color:
                          Colors.white,
                      fontSize:
                          20,
                      fontWeight:
                          FontWeight.w900,
                    ),
                  ),
                  Text(
                    month,
                    style:
                        const TextStyle(
                      color:
                          JarvisColors.cyan,
                      fontSize:
                          7,
                      fontWeight:
                          FontWeight.w900,
                      letterSpacing:
                          1,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(
              width: 13,
            ),

            Expanded(
              child:
                  Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Text(
                    _formatDate(
                      date,
                    ),
                    style:
                        const TextStyle(
                      color:
                          Colors.white,
                      fontSize:
                          13,
                      fontWeight:
                          FontWeight.w900,
                    ),
                  ),
                  const SizedBox(
                    height: 5,
                  ),
                  Text(
                    '$count TOPIC${count == 1 ? '' : 'S'} SCHEDULED',
                    style:
                        const TextStyle(
                      color:
                          Color(
                        0xFF6D839B,
                      ),
                      fontSize:
                          8,
                      fontWeight:
                          FontWeight.w700,
                      letterSpacing:
                          0.9,
                    ),
                  ),
                ],
              ),
            ),

            const Icon(
              Icons
                  .arrow_forward_ios_rounded,
              color:
                  Color(
                0xFF607994,
              ),
              size:
                  14,
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(
    String value,
  ) {
    final parsed =
        DateTime.tryParse(value);

    if (parsed == null) {
      return value;
    }

    const months = [
      'JAN',
      'FEB',
      'MAR',
      'APR',
      'MAY',
      'JUN',
      'JUL',
      'AUG',
      'SEP',
      'OCT',
      'NOV',
      'DEC',
    ];

    return '${parsed.day.toString().padLeft(2, '0')} '
        '${months[parsed.month - 1]} '
        '${parsed.year}';
  }
}

// ================================================================
// DATE DETAIL
// ================================================================

class ScheduleDateDetailScreen
    extends StatelessWidget {
  final String date;

  final List<Map<String, dynamic>>
      assignments;

  const ScheduleDateDetailScreen({
    super.key,
    required this.date,
    required this.assignments,
  });

  String _subjectName(
    Map<String, dynamic> assignment,
  ) {
    final value =
        assignment['subjectName']
            ?.toString()
            .trim();

    return value == null ||
            value.isEmpty
        ? 'SUBJECT'
        : value;
  }

  String _topicName(
    Map<String, dynamic> assignment,
  ) {
    final value =
        assignment['topicName']
            ?.toString()
            .trim();

    return value == null ||
            value.isEmpty
        ? 'TOPIC'
        : value;
  }

  String _unitNumber(
    Map<String, dynamic> assignment,
  ) {
    final value =
        assignment['unitNumber'];

    return value == null
        ? 'UNIT —'
        : 'UNIT ${value.toString()}';
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    final grouped =
        <String,
            List<Map<String, dynamic>>>{};

    for (final assignment
        in assignments) {
      grouped
          .putIfAbsent(
            _subjectName(
              assignment,
            ),
            () =>
                <Map<String, dynamic>>[],
          )
          .add(assignment);
    }

    return Scaffold(
      backgroundColor:
          const Color(
        0xFF030711,
      ),
      appBar:
          AppBar(
        backgroundColor:
            Colors.transparent,
        elevation:
            0,
        title:
            const Text(
          'DATE DETAIL',
          style:
              TextStyle(
            color:
                Colors.white,
            fontSize:
                14,
            fontWeight:
                FontWeight.w900,
            letterSpacing:
                1.5,
          ),
        ),
      ),
      body:
          ListView(
        padding:
            const EdgeInsets.fromLTRB(
          18,
          8,
          18,
          35,
        ),
        children: [
          _buildDateHeader(),

          const SizedBox(
            height: 18,
          ),

          ...grouped.entries.map(
            (entry) =>
                Padding(
              padding:
                  const EdgeInsets.only(
                bottom:
                    14,
              ),
              child:
                  _buildSubjectGroup(
                entry.key,
                entry.value,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateHeader() {
    final parsed =
        DateTime.tryParse(date);

    const months = [
      'JAN',
      'FEB',
      'MAR',
      'APR',
      'MAY',
      'JUN',
      'JUL',
      'AUG',
      'SEP',
      'OCT',
      'NOV',
      'DEC',
    ];

    final formatted =
        parsed == null
            ? date
            : '${parsed.day.toString().padLeft(2, '0')} '
                '${months[parsed.month - 1]} '
                '${parsed.year}';

    return Container(
      padding:
          const EdgeInsets.all(
        20,
      ),
      decoration:
          BoxDecoration(
        color:
            const Color(
          0xCC081221,
        ),
        borderRadius:
            BorderRadius.circular(
          24,
        ),
        border:
            Border.all(
          color:
              JarvisColors.cyan
                  .withValues(
            alpha:
                0.3,
          ),
        ),
      ),
      child:
          Row(
        children: [
          const Icon(
            Icons
                .event_rounded,
            color:
                JarvisColors.cyan,
            size:
                28,
          ),

          const SizedBox(
            width: 12,
          ),

          Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              const Text(
                'DATE',
                style:
                    TextStyle(
                  color:
                      Color(
                    0xFF667D96,
                  ),
                  fontSize:
                      8,
                  fontWeight:
                      FontWeight.w800,
                  letterSpacing:
                      1.2,
                ),
              ),
              const SizedBox(
                height: 5,
              ),
              Text(
                formatted,
                style:
                    const TextStyle(
                  color:
                      Colors.white,
                  fontSize:
                      18,
                  fontWeight:
                      FontWeight.w900,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSubjectGroup(
    String subject,
    List<Map<String, dynamic>>
        assignments,
  ) {
    return Container(
      padding:
          const EdgeInsets.all(
        15,
      ),
      decoration:
          BoxDecoration(
        color:
            const Color(
          0xCC081221,
        ),
        borderRadius:
            BorderRadius.circular(
          20,
        ),
        border:
            Border.all(
          color:
              const Color(
            0xFF263D59,
          ),
        ),
      ),
      child:
          Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Text(
            subject
                .toUpperCase(),
            style:
                const TextStyle(
              color:
                  Colors.white,
              fontSize:
                  12,
              fontWeight:
                  FontWeight.w900,
              letterSpacing:
                  0.9,
            ),
          ),

          const SizedBox(
            height: 11,
          ),

          ...assignments.map(
            (assignment) {
              return Container(
                margin:
                    const EdgeInsets.only(
                  bottom:
                      8,
                ),
                padding:
                    const EdgeInsets.symmetric(
                  horizontal:
                      12,
                  vertical:
                      12,
                ),
                decoration:
                    BoxDecoration(
                  color:
                      const Color(
                    0xFF0A1424,
                  ),
                  borderRadius:
                      BorderRadius.circular(
                    14,
                  ),
                  border:
                      Border.all(
                    color:
                        const Color(
                      0xFF1C3047,
                    ),
                  ),
                ),
                child:
                    Row(
                  children: [
                    Container(
                      width:
                          6,
                      height:
                          6,
                      decoration:
                          const BoxDecoration(
                        shape:
                            BoxShape.circle,
                        color:
                            JarvisColors.cyan,
                      ),
                    ),

                    const SizedBox(
                      width: 10,
                    ),

                    Expanded(
                      child:
                          Text(
                        _topicName(
                          assignment,
                        ),
                        style:
                            const TextStyle(
                          color:
                              Colors.white,
                          fontSize:
                              11,
                          fontWeight:
                              FontWeight.w800,
                        ),
                      ),
                    ),

                    const SizedBox(
                      width: 8,
                    ),

                    Text(
                      _unitNumber(
                        assignment,
                      ),
                      style:
                          const TextStyle(
                        color:
                            Color(
                          0xFF6D839B,
                        ),
                        fontSize:
                            8,
                        fontWeight:
                            FontWeight.w800,
                        letterSpacing:
                            0.5,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

// ================================================================
// BACKGROUND
// ================================================================

class _ScheduleBackgroundPainter
    extends CustomPainter {
  final double progress;

  _ScheduleBackgroundPainter({
    required this.progress,
  });

  @override
  void paint(
    Canvas canvas,
    Size size,
  ) {
    final paint =
        Paint()
          ..style =
              PaintingStyle.stroke
          ..strokeWidth =
              0.5
          ..color =
              const Color(
            0xFF00E5FF,
          ).withValues(
            alpha:
                0.025,
          );

    final center =
        Offset(
      size.width * 0.84,
      size.height * 0.10,
    );

    for (int i = 0;
        i < 6;
        i++) {
      final radius =
          55.0 +
          i * 34.0 +
          progress * 5;

      canvas.drawCircle(
        center,
        radius,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(
    covariant
        _ScheduleBackgroundPainter
            oldDelegate,
  ) {
    return oldDelegate.progress !=
        progress;
  }
}