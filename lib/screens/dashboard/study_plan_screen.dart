import 'package:flutter/material.dart';

import '../../models/subject.dart';
import '../../models/topic.dart';
import '../../models/unit.dart';
import '../../services/api_service.dart';
import '../../services/token_service.dart';

class StudyPlanScreen extends StatefulWidget {
  const StudyPlanScreen({
    super.key,
  });

  @override
  State<StudyPlanScreen> createState() =>
      _StudyPlanScreenState();
}

class _StudyPlanScreenState
    extends State<StudyPlanScreen>
    with TickerProviderStateMixin {
  final ApiService _api =
      ApiService();

  bool _loading = true;
  bool _saving = false;

  List<Subject> _subjects = [];

  final Map<String, SubjectPlanDraft>
      _drafts = {};

  late AnimationController
      _pageController;

  @override
  void initState() {
    super.initState();

    _pageController =
        AnimationController(
      vsync: this,
      duration:
          const Duration(
        milliseconds: 700,
      ),
    );

    _loadSubjects();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<String?> _getToken() async {
  final tokenService = TokenService();
  return tokenService.getToken();
}

  Future<void> _loadSubjects() async {
    try {
      final token =
          await _getToken();

      if (token == null ||
          token.isEmpty) {
        throw Exception(
          'Session expired.',
        );
      }

      final subjects =
          await _api.getSubjects(
        token,
      );

      if (!mounted) return;

      setState(() {
        _subjects =
            subjects;

        for (
          final subject
              in subjects
        ) {
          _drafts.putIfAbsent(
            subject.id,
            () =>
                SubjectPlanDraft(
              subject:
                  subject,
            ),
          );
        }

        _loading = false;
      });

      _pageController
          .forward();
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _loading = false;
      });

      _showMessage(
        e
            .toString()
            .replaceFirst(
              'Exception: ',
              '',
            ),
      );
    }
  }

  /*
   * =========================================================
   * DATE PICKER
   * =========================================================
   */

  Future<DateTime?>
      _pickDate({
    required DateTime
        initialDate,
    required DateTime
        firstDate,
  }) async {
    return showDatePicker(
      context: context,
      initialDate:
          initialDate,
      firstDate:
          firstDate,
      lastDate:
          DateTime(
        2100,
      ),
      builder:
          (
        context,
        child,
      ) {
        return Theme(
          data:
              Theme.of(
                context,
              ).copyWith(
            colorScheme:
                const ColorScheme.dark(
              primary:
                  Color(
                0xFF7C4DFF,
              ),
              surface:
                  Color(
                0xFF11131D,
              ),
            ),
          ),
          child:
              child!,
        );
      },
    );
  }

  String _formatDate(
    DateTime date,
  ) {
    final months = [
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

    return '${date.day.toString().padLeft(2, '0')} '
        '${months[date.month - 1]} '
        '${date.year}';
  }

  String _apiDate(
    DateTime date,
  ) {
    return '${date.year.toString().padLeft(4, '0')}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';
  }

  /*
   * =========================================================
   * SUBJECT CONFIGURATION
   * =========================================================
   */

 
  /*
   * =========================================================
   * UNIT TABLE
   * =========================================================
   */

  Future<void> _openUnitSelection(
  SubjectPlanDraft draft,
) async {
  final token = await _getToken();

  if (token == null || token.isEmpty) {
    _showMessage('Session expired.');
    return;
  }

  List<Unit> units = [];

  try {
    units = await _api.getUnitsBySubject(
      token,
      draft.subject.id,
    );
  } catch (e) {
    if (!mounted) return;

    _showMessage(
      e.toString().replaceFirst(
        'Exception: ',
        '',
      ),
    );

    return;
  }

  if (!mounted) return;

  if (units.isEmpty) {
    _showMessage(
      'No units are available for ${draft.subject.name}.',
    );
    return;
  }

  await showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _UnitSelectionSheet(
      subject: draft.subject,
      units: units,
      selectedUnits: draft.units,

      onSelectUnit: (
        unit,
      ) async {
        /*
         * IMPORTANT:
         * Do NOT close the Unit sheet here.
         *
         * The Topic sheet opens above the Unit sheet.
         * When Topic DONE is pressed, the Topic sheet closes
         * and the Unit sheet becomes visible again.
         */
        await _openTopicSelection(
          draft,
          unit,
        );
      },

      onDone: () {
        /*
         * Only Unit DONE closes the Unit table
         * and returns to the Subject table.
         */
        Navigator.pop(context);
      },
    ),
  );
}

  /*
   * =========================================================
   * TOPIC TABLE
   * =========================================================
   */

Future<void> _openTopicSelection(
  SubjectPlanDraft draft,
  Unit unit,
) async {
  final token = await _getToken();

  if (token == null || token.isEmpty) {
    _showMessage('Session expired.');
    return;
  }

  List<Topic> topics = [];

  try {
    topics = await _api.getTopicsByUnit(
      token,
      unit.id,
    );
  } catch (e) {
    if (!mounted) return;

    _showMessage(
      e.toString().replaceFirst(
        'Exception: ',
        '',
      ),
    );

    return;
  }

  topics = topics
      .where(
        (topic) => !topic.completed,
      )
      .toList();

  if (!mounted) return;

  /*
   * IMPORTANT:
   * Always create and store the Set inside the draft.
   * This ensures selected topics remain available
   * after returning from the Topic table.
   */
  final selected = draft.units.putIfAbsent(
    unit.id,
    () => <String>{},
  );

  await showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _TopicSelectionSheet(
      subject: draft.subject,
      unit: unit,
      topics: topics,
      selected: selected,
      onDone: () {
        Navigator.pop(context);
      },
    ),
  );

  if (!mounted) return;

  setState(() {});
}
  /*
   * =========================================================
   * CANCEL
   * =========================================================
   */

  Future<void> _cancelPlanner() async {
  if (!_hasSelectedTopics()) {
    Navigator.pop(context);
    return;
  }

  final discard = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (_) => const _ConfirmDialog(),
  );

  if (!mounted) return;

  if (discard == true) {
    Navigator.pop(context);
  }
}

  /*
   * =========================================================
   * SELECTION CHECK
   * =========================================================
   */

  bool _hasSelectedTopics() {
    for (
      final draft
          in _drafts.values
    ) {
      for (
        final topics
            in draft.units.values
      ) {
        if (topics.isNotEmpty) {
          return true;
        }
      }
    }

    return false;
  }

  /*
   * =========================================================
   * GENERATE
   * =========================================================
   */

  Future<void> _generate() async {
    if (!_hasSelectedTopics()) {
      _showMessage(
        'No topics selected.',
      );
      return;
    }

    for (
      final draft
          in _drafts.values
    ) {
      final hasTopics =
          draft.units.values.any(
        (items) =>
            items.isNotEmpty,
      );

      if (!hasTopics) {
        continue;
      }

      if (
          draft.startDate ==
              null ||
          draft.deadline ==
              null) {
        _showMessage(
          'Set Start Date and Deadline for ${draft.subject.name}.',
        );
        return;
      }
    }

    final token =
        await _getToken();

    if (token == null ||
        token.isEmpty) {
      _showMessage(
        'Session expired.',
      );
      return;
    }

    final payload =
        <Map<String, dynamic>>[];

    for (
      final draft
          in _drafts.values
    ) {
      final selectedUnits =
          <Map<String, dynamic>>[];

      draft.units.forEach(
        (
          unitId,
          topicIds,
        ) {
          if (topicIds.isEmpty) {
            return;
          }

          selectedUnits.add({
            'unitId':
                unitId,
            'topicIds':
                topicIds.toList(),
          });
        },
      );

      if (
        selectedUnits.isEmpty
      ) {
        continue;
      }

      payload.add({
        'subjectId':
            draft.subject.id,
        'startDate':
            _apiDate(
          draft.startDate!,
        ),
        'deadline':
            _apiDate(
          draft.deadline!,
        ),
        'units':
            selectedUnits,
      });
    }

    if (payload.isEmpty) {
      _showMessage(
        'No topics selected.',
      );
      return;
    }

    setState(() {
      _saving = true;
    });

    try {
      final result =
          await _api.generateStudyPlan(
        token,
        subjects:
            payload,
      );

      if (!mounted) return;

      setState(() {
        _saving = false;
      });

      final unresolved =
          result[
              'unresolvedTopics'];

      if (
        unresolved is List &&
        unresolved.isNotEmpty
      ) {
        _showMessage(
          'Some topics could not be scheduled within their available dates.',
        );
      }

      Navigator.pop(
        context,
        true,
      );
    } on SchedulePressureException catch (
      pressure
    ) {
      if (!mounted) return;

      setState(() {
        _saving = false;
      });

      await _showPressureDialog(
        token,
        payload,
        pressure,
      );
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _saving = false;
      });

      _showMessage(
        e
            .toString()
            .replaceFirst(
              'Exception: ',
              '',
            ),
      );
    }
  }

  /*
   * =========================================================
   * DEADLINE PRESSURE
   * =========================================================
   */

  Future<void>
      _showPressureDialog(
    String token,
    List<
            Map<String, dynamic>>
        payload,
    SchedulePressureException
        pressure,
  ) async {
    final result =
        await showDialog<bool>(
      context: context,
      barrierDismissible:
          false,
      builder:
          (_) =>
              _PressureDialog(
        pressure:
            pressure.pressure,
      ),
    );

    if (!mounted) return;

    /*
     * false = LEAVE IT
     * true  = SCHEDULE IT
     */
    if (result !=
        true) {
      return;
    }

    setState(() {
      _saving = true;
    });

    try {
      await _api.generateStudyPlan(
        token,
        subjects:
            payload,
        allowOverCapacity:
            true,
      );

      if (!mounted) return;

      setState(() {
        _saving = false;
      });

      Navigator.pop(
        context,
        true,
      );
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _saving = false;
      });

      _showMessage(
        e
            .toString()
            .replaceFirst(
              'Exception: ',
              '',
            ),
      );
    }
  }

  /*
   * =========================================================
   * MESSAGE
   * =========================================================
   */

  void _showMessage(
    String message,
  ) {
    if (!mounted) return;

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(
      SnackBar(
        content:
            Text(message),
        behavior:
            SnackBarBehavior
                .floating,
      ),
    );
  }

  /*
   * =========================================================
   * BUILD
   * =========================================================
   */

  @override
  Widget build(
    BuildContext context,
  ) {
    return Scaffold(
      backgroundColor:
          const Color(
        0xFF05060A,
      ),
      appBar: AppBar(
        backgroundColor:
            Colors.transparent,
        elevation: 0,
        title:
            const Text(
          'GENERATE STUDY PLAN',
          style: TextStyle(
            fontSize: 15,
            fontWeight:
                FontWeight.w700,
            letterSpacing:
                2.2,
          ),
        ),
        leading:
            IconButton(
          icon:
              const Icon(
            Icons.close_rounded,
          ),
          onPressed:
              _saving
                  ? null
                  : _cancelPlanner,
        ),
      ),
      body:
          _loading
              ? const Center(
                  child:
                      CircularProgressIndicator(),
                )
              : Stack(
                  children: [
                    _buildBackground(),

                    SafeArea(
                      child:
                          FadeTransition(
                        opacity:
                            _pageController
                                .drive(
                          CurveTween(
                            curve:
                                Curves.easeOut,
                          ),
                        ),
                        child:
                            Column(
                          children: [
                            Expanded(
                              child:
                                  ListView(
                                padding:
                                    const EdgeInsets.fromLTRB(
                                  18,
                                  18,
                                  18,
                                  120,
                                ),
                                children:
                                    [
                                  _buildHeader(),

                                  const SizedBox(
                                    height: 20,
                                  ),

                                  ..._subjects
                                      .map(
                                        _buildSubjectCard,
                                      ),
                                ],
                              ),
                            ),

                            _buildBottomBar(),
                          ],
                        ),
                      ),
                    ),

                    if (_saving)
                      _buildSavingOverlay(),
                  ],
                ),
    );
  }

  Widget _buildBackground() {
    return IgnorePointer(
      child:
          Stack(
        children: [
          Positioned(
            top: -100,
            right: -80,
            child:
                Container(
              width: 240,
              height: 240,
              decoration:
                  BoxDecoration(
                shape:
                    BoxShape.circle,
                color:
                    const Color(
                  0xFF6C4DFF,
                ).withValues(alpha:
                  0.10,
                ),
              ),
            ),
          ),
          Positioned(
            bottom: -120,
            left: -100,
            child:
                Container(
              width: 280,
              height: 280,
              decoration:
                  BoxDecoration(
                shape:
                    BoxShape.circle,
                color:
                    const Color(
                  0xFF00D9FF,
                ).withValues(alpha:
                  0.06,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
Widget _buildHeader() {
  return Container(
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(22),
      border: Border.all(
        color: Colors.white.withValues(
          alpha: 0.10,
        ),
      ),
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Colors.white.withValues(
            alpha: 0.075,
          ),
          Colors.white.withValues(
            alpha: 0.025,
          ),
        ],
      ),
    ),
    child: const Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        Text(
          'SUBJECTS',
          style: TextStyle(
            color: Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.w800,
            letterSpacing: 2,
          ),
        ),
        SizedBox(
          height: 7,
        ),
        Text(
          'Configure the subjects you want included in your study plan.',
          style: TextStyle(
            color: Colors.white54,
            fontSize: 12,
            height: 1.45,
          ),
        ),
      ],
    ),
  );
}
 Widget _buildSubjectCard(
  Subject subject,
) {
  final draft = _drafts[subject.id]!;

  final selectedCount =
      draft.units.values.fold<int>(
    0,
    (
      total,
      topics,
    ) =>
        total + topics.length,
  );

  return Container(
    margin: const EdgeInsets.only(
      bottom: 14,
    ),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(
        24,
      ),
      border: Border.all(
        color: selectedCount > 0
            ? const Color(
                0xFF7C4DFF,
              ).withValues(
                alpha: 0.45,
              )
            : Colors.white.withValues(
                alpha: 0.09,
              ),
      ),
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Colors.white.withValues(
            alpha: 0.065,
          ),
          Colors.white.withValues(
            alpha: 0.018,
          ),
        ],
      ),
    ),
    child: Padding(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          // SUBJECT HEADER
          Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(
                    0xFF7C4DFF,
                  ).withValues(
                    alpha: 0.15,
                  ),
                ),
                child: const Icon(
                  Icons.school_rounded,
                  color: Color(
                    0xFFB9A7FF,
                  ),
                ),
              ),
              const SizedBox(
                width: 14,
              ),
              Expanded(
                child: Text(
                  subject.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight:
                        FontWeight.w700,
                  ),
                ),
              ),
              if (selectedCount > 0)
                Container(
                  padding:
                      const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration:
                      BoxDecoration(
                    borderRadius:
                        BorderRadius.circular(
                      30,
                    ),
                    color: const Color(
                      0xFF7C4DFF,
                    ).withValues(
                      alpha: 0.16,
                    ),
                  ),
                  child: Text(
                    '$selectedCount',
                    style:
                        const TextStyle(
                      color: Color(
                        0xFFC5B7FF,
                      ),
                      fontSize: 11,
                      fontWeight:
                          FontWeight.w800,
                    ),
                  ),
                ),
            ],
          ),

          const SizedBox(
            height: 18,
          ),

          // DATE CONTROLS
          Row(
            children: [
              // START DATE
              Expanded(
                child: GestureDetector(
                  onTap: _saving
                      ? null
                      : () async {
                          final now =
                              DateTime.now();

                          final today =
                              DateTime(
                            now.year,
                            now.month,
                            now.day,
                          );

                          final pickedStart =
                              await _pickDate(
                            initialDate:
                                draft.startDate ??
                                    today,
                            firstDate:
                                today,
                          );

                          if (pickedStart ==
                                  null ||
                              !mounted) {
                            return;
                          }

                          setState(() {
                            draft.startDate =
                                pickedStart;

                            // If existing deadline
                            // is before new start,
                            // clear it.
                            if (draft.deadline !=
                                    null &&
                                draft.deadline!
                                    .isBefore(
                                  pickedStart,
                                )) {
                              draft.deadline =
                                  null;
                            }
                          });
                        },
                  child: _dateChip(
                    label: 'START',
                    value:
                        draft.startDate ==
                                null
                            ? 'SELECT'
                            : _formatDate(
                                draft.startDate!,
                              ),
                  ),
                ),
              ),

              const SizedBox(
                width: 10,
              ),

              // DEADLINE DATE
              Expanded(
                child: GestureDetector(
                  onTap: _saving
                      ? null
                      : () async {
                          if (draft.startDate ==
                              null) {
                            _showMessage(
                              'Select Start Date first.',
                            );
                            return;
                          }

                          final pickedDeadline =
                              await _pickDate(
                            initialDate:
                                draft.deadline ??
                                    draft.startDate!,
                            firstDate:
                                draft.startDate!,
                          );

                          if (pickedDeadline ==
                                  null ||
                              !mounted) {
                            return;
                          }

                          setState(() {
                            draft.deadline =
                                pickedDeadline;
                          });

                          // Both dates are now
                          // explicitly selected.
                          await _openUnitSelection(
                            draft,
                          );
                        },
                  child: _dateChip(
                    label: 'DEADLINE',
                    value:
                        draft.deadline ==
                                null
                            ? 'SELECT'
                            : _formatDate(
                                draft.deadline!,
                              ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(
            height: 12,
          ),

          Text(
            selectedCount > 0
                ? 'Tap dates to edit • Configure units and topics'
                : 'Select dates to configure',
            style: const TextStyle(
              color: Colors.white38,
              fontSize: 11,
            ),
          ),
        ],
      ),
    ),
  );
}

  Widget _dateChip({
    required String label,
    required String value,
  }) {
    return Container(
      padding:
          const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 11,
      ),
      decoration:
          BoxDecoration(
        borderRadius:
            BorderRadius.circular(
          14,
        ),
        color:
            Colors.black
                .withValues(alpha:
          0.20,
        ),
        border:
            Border.all(
          color:
              Colors.white.withValues(alpha:
            0.07,
          ),
        ),
      ),
      child:
          Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style:
                const TextStyle(
              color:
                  Colors.white38,
              fontSize:
                  9,
              fontWeight:
                  FontWeight.w800,
              letterSpacing:
                  1.5,
            ),
          ),
          const SizedBox(
            height: 4,
          ),
          Text(
            value,
            style:
                const TextStyle(
              color:
                  Colors.white,
              fontSize:
                  11,
              fontWeight:
                  FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding:
          const EdgeInsets.fromLTRB(
        18,
        10,
        18,
        18,
      ),
      decoration:
          BoxDecoration(
        color:
            const Color(
          0xFF05060A,
        ).withValues(alpha:
          0.94,
        ),
        border:
            Border(
          top:
              BorderSide(
            color:
                Colors.white.withValues(alpha:
              0.07,
            ),
          ),
        ),
      ),
      child:
          Row(
        children: [
          Expanded(
  flex: 1,
  child: OutlinedButton(
    onPressed: _saving
        ? null
        : _cancelPlanner,
    style: OutlinedButton.styleFrom(
      minimumSize: const Size(
        0,
        52,
      ),
      padding:
          const EdgeInsets.symmetric(
        horizontal: 8,
      ),
      shape:
          RoundedRectangleBorder(
        borderRadius:
            BorderRadius.circular(
          16,
        ),
      ),
      side: BorderSide(
        color: Colors.white.withValues(
          alpha: 0.14,
        ),
      ),
    ),
    child: const FittedBox(
      fit: BoxFit.scaleDown,
      child: Text(
        'CANCEL',
        maxLines: 1,
        softWrap: false,
        style: TextStyle(
          color: Colors.white70,
          fontSize: 12,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.2,
        ),
      ),
    ),
  ),
),
          const SizedBox(
            width: 12,
          ),
          Expanded(
  flex: 2,
  child: ElevatedButton(
    onPressed: _saving
        ? null
        : _generate,
    style: ElevatedButton.styleFrom(
      minimumSize: const Size(
        0,
        52,
      ),
      backgroundColor:
          const Color(0xFF7C4DFF),
      foregroundColor: Colors.white,
      elevation: 0,
      shape:
          RoundedRectangleBorder(
        borderRadius:
            BorderRadius.circular(
          16,
        ),
      ),
    ),
    child: const Text(
      'GENERATE',
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w900,
        letterSpacing: 1.8,
      ),
    ),
  ),
),
        ],
      ),
    );
  }

  Widget _buildSavingOverlay() {
    return Positioned.fill(
      child:
          Container(
        color:
            Colors.black.withValues(alpha:
          0.70,
        ),
        child:
            const Center(
          child:
              Column(
            mainAxisSize:
                MainAxisSize.min,
            children: [
              SizedBox(
                width: 42,
                height: 42,
                child:
                    CircularProgressIndicator(
                  strokeWidth:
                      2,
                ),
              ),
              SizedBox(
                height: 18,
              ),
              Text(
                'BUILDING STUDY PLAN',
                style:
                    TextStyle(
                  color:
                      Colors.white,
                  fontSize:
                      11,
                  fontWeight:
                      FontWeight.w800,
                  letterSpacing:
                      2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/*
 * =========================================================
 * DRAFT MODEL
 * =========================================================
 */

class SubjectPlanDraft {
  final Subject subject;

  DateTime? startDate;

  DateTime? deadline;

  /*
   * unitId -> selected topic IDs
   */
  final Map<String, Set<String>>
      units = {};

  SubjectPlanDraft({
    required this.subject,
  });
}

/*
 * =========================================================
 * UNIT SHEET
 * =========================================================
 */

class _UnitSelectionSheet
    extends StatelessWidget {
  final Subject subject;

  final List<Unit> units;

  final Map<String, Set<String>>
      selectedUnits;

  final Future<void> Function(
    Unit unit,
  ) onSelectUnit;

  final VoidCallback onDone;

  const _UnitSelectionSheet({
    required this.subject,
    required this.units,
    required this.selectedUnits,
    required this.onSelectUnit,
    required this.onDone,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    return Container(
      height:
          MediaQuery.of(
            context,
          ).size.height *
          0.72,
      decoration:
          const BoxDecoration(
        color:
            Color(
          0xFF0A0B11,
        ),
        borderRadius:
            BorderRadius.vertical(
          top:
              Radius.circular(
            28,
          ),
        ),
      ),
      child:
          Column(
        children: [
          _handle(),
          Padding(
            padding:
                const EdgeInsets.fromLTRB(
              20,
              10,
              20,
              12,
            ),
            child:
                Row(
              children: [
                Expanded(
                  child:
                      Text(
                    subject.name,
                    style:
                        const TextStyle(
                      color:
                          Colors.white,
                      fontSize:
                          18,
                      fontWeight:
                          FontWeight.w800,
                    ),
                  ),
                ),
                TextButton(
                  onPressed:
                      onDone,
                  child:
                      const Text(
                    'DONE',
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child:
                ListView.builder(
              padding:
                  const EdgeInsets.fromLTRB(
                16,
                4,
                16,
                20,
              ),
              itemCount:
                  units.length,
              itemBuilder:
                  (
                context,
                index,
              ) {
                final unit =
                    units[index];

                final selected =
                    selectedUnits
                        .containsKey(
                  unit.id,
                );

                return Container(
                  margin:
                      const EdgeInsets.only(
                    bottom:
                        10,
                  ),
                  decoration:
                      BoxDecoration(
                    borderRadius:
                        BorderRadius.circular(
                      18,
                    ),
                    border:
                        Border.all(
                      color:
                          selected
                              ? const Color(
                                  0xFF7C4DFF,
                                )
                              : Colors.white
                                  .withValues(alpha:
                                  0.08,
                                ),
                    ),
                    color:
                        selected
                            ? const Color(
                                0xFF7C4DFF,
                              ).withValues(alpha:
                                0.10,
                              )
                            : Colors.white
                                .withValues(alpha:
                                0.035,
                              ),
                  ),
                  child:
                      ListTile(
                    onTap:
                        () =>
                            onSelectUnit(
                      unit,
                    ),
                    leading:
                        Container(
                      width:
                          42,
                      height:
                          42,
                      alignment:
                          Alignment.center,
                      decoration:
                          BoxDecoration(
                        borderRadius:
                            BorderRadius.circular(
                          13,
                        ),
                        color:
                            const Color(
                          0xFF7C4DFF,
                        ).withValues(alpha:
                          0.13,
                        ),
                      ),
                      child:
                          Text(
                        unit.unitNumber
                            .toString()
                            .padLeft(
                              2,
                              '0',
                            ),
                        style:
                            const TextStyle(
                          color:
                              Color(
                            0xFFC8BAFF,
                          ),
                          fontWeight:
                              FontWeight.w900,
                        ),
                      ),
                    ),
                    title:
                        Text(
                      unit.name,
                      style:
                          const TextStyle(
                        color:
                            Colors.white,
                        fontWeight:
                            FontWeight.w700,
                      ),
                    ),
                    trailing:
                        Icon(
                      selected
                          ? Icons
                              .check_circle_rounded
                          : Icons
                              .arrow_forward_ios_rounded,
                      size:
                          18,
                      color:
                          selected
                              ? const Color(
                                  0xFF9C83FF,
                                )
                              : Colors.white30,
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _handle() {
    return Container(
      margin:
          const EdgeInsets.only(
        top: 10,
      ),
      width: 42,
      height: 4,
      decoration:
          BoxDecoration(
        borderRadius:
            BorderRadius.circular(
          10,
        ),
        color:
            Colors.white24,
      ),
    );
  }
}

/*
 * =========================================================
 * TOPIC SHEET
 * =========================================================
 */

class _TopicSelectionSheet
    extends StatefulWidget {
  final Subject subject;

  final Unit unit;

  final List<Topic> topics;

  final Set<String> selected;

  final VoidCallback onDone;

  const _TopicSelectionSheet({
    required this.subject,
    required this.unit,
    required this.topics,
    required this.selected,
    required this.onDone,
  });

  @override
  State<_TopicSelectionSheet>
      createState() =>
          _TopicSelectionSheetState();
}

class _TopicSelectionSheetState
    extends State<
        _TopicSelectionSheet> {
  late Set<String>
      _selected;

  @override
  void initState() {
    super.initState();

    _selected =
        Set<String>.from(
      widget.selected,
    );
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    return Container(
      height:
          MediaQuery.of(
            context,
          ).size.height *
          0.82,
      decoration:
          const BoxDecoration(
        color:
            Color(
          0xFF0A0B11,
        ),
        borderRadius:
            BorderRadius.vertical(
          top:
              Radius.circular(
            28,
          ),
        ),
      ),
      child:
          Column(
        children: [
          _handle(),

          Padding(
            padding:
                const EdgeInsets.fromLTRB(
              20,
              10,
              20,
              12,
            ),
            child:
                Row(
              children: [
                Expanded(
                  child:
                      Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.unit.name,
                        style:
                            const TextStyle(
                          color:
                              Colors.white,
                          fontSize:
                              18,
                          fontWeight:
                              FontWeight.w800,
                        ),
                      ),
                      const SizedBox(
                        height:
                            4,
                      ),
                      Text(
                        '${_selected.length} selected',
                        style:
                            const TextStyle(
                          color:
                              Colors.white38,
                          fontSize:
                              11,
                        ),
                      ),
                    ],
                  ),
                ),
                TextButton(
                  onPressed:
                      widget.onDone,
                  child:
                      const Text(
                    'DONE',
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child:
                widget.topics.isEmpty
                    ? const Center(
                        child:
                            Text(
                          'No unfinished topics',
                          style:
                              TextStyle(
                            color:
                                Colors.white38,
                          ),
                        ),
                      )
                    : ListView.builder(
                        padding:
                            const EdgeInsets.fromLTRB(
                          16,
                          4,
                          16,
                          20,
                        ),
                        itemCount:
                            widget.topics.length,
                        itemBuilder:
                            (
                          context,
                          index,
                        ) {
                          final topic =
                              widget.topics[
                                  index];

                          final selected =
                              _selected.contains(
                            topic.id,
                          );

                          return AnimatedContainer(
                            duration:
                                const Duration(
                              milliseconds:
                                  220,
                            ),
                            margin:
                                const EdgeInsets.only(
                              bottom:
                                  9,
                            ),
                            decoration:
                                BoxDecoration(
                              borderRadius:
                                  BorderRadius.circular(
                                18,
                              ),
                              border:
                                  Border.all(
                                color:
                                    selected
                                        ? const Color(
                                            0xFF7C4DFF,
                                          )
                                        : Colors.white
                                            .withValues(alpha:
                                            0.07,
                                          ),
                              ),
                              color:
                                  selected
                                      ? const Color(
                                          0xFF7C4DFF,
                                        ).withValues(alpha:
                                          0.12,
                                        )
                                      : Colors.white
                                          .withValues(alpha:
                                          0.035,
                                        ),
                            ),
                            child:
                                Material(
                              color:
                                  Colors.transparent,
                              child:
                                  InkWell(
                                borderRadius:
                                    BorderRadius.circular(
                                  18,
                                ),
                                onTap:
                                    () {
                                  setState(
                                    () {
                                      if (selected) {
                                        _selected.remove(
                                          topic.id,
                                        );
                                      } else {
                                        _selected.add(
                                          topic.id,
                                        );
                                      }

                                      widget.selected
                                        ..clear()
                                        ..addAll(
                                          _selected,
                                        );
                                    },
                                  );
                                },
                                child:
                                    Padding(
                                  padding:
                                      const EdgeInsets.symmetric(
                                    horizontal:
                                        16,
                                    vertical:
                                        15,
                                  ),
                                  child:
                                      Row(
                                    children: [
                                      Expanded(
                                        child:
                                            Text(
                                          topic.name,
                                          style:
                                              const TextStyle(
                                            color:
                                                Colors.white,
                                            fontSize:
                                                13,
                                            fontWeight:
                                                FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                      AnimatedContainer(
                                        duration:
                                            const Duration(
                                          milliseconds:
                                              220,
                                        ),
                                        width:
                                            24,
                                        height:
                                            24,
                                        decoration:
                                            BoxDecoration(
                                          shape:
                                              BoxShape.circle,
                                          color:
                                              selected
                                                  ? const Color(
                                                      0xFF7C4DFF,
                                                    )
                                                  : Colors.transparent,
                                          border:
                                              Border.all(
                                            color:
                                                selected
                                                    ? const Color(
                                                        0xFF9C83FF,
                                                      )
                                                    : Colors.white30,
                                          ),
                                        ),
                                        child:
                                            selected
                                                ? const Icon(
                                                    Icons.check_rounded,
                                                    size:
                                                        16,
                                                    color:
                                                        Colors.white,
                                                  )
                                                : null,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _handle() {
    return Container(
      margin:
          const EdgeInsets.only(
        top: 10,
      ),
      width: 42,
      height: 4,
      decoration:
          BoxDecoration(
        borderRadius:
            BorderRadius.circular(
          10,
        ),
        color:
            Colors.white24,
      ),
    );
  }
}

/*
 * =========================================================
 * CONFIRM DIALOG
 * =========================================================
 */

class _ConfirmDialog extends StatelessWidget {
  const _ConfirmDialog();

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(
        horizontal: 28,
      ),
      child: Container(
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: const Color(0xFF11131D),
          borderRadius: BorderRadius.circular(26),
          border: Border.all(
            color: const Color(
              0xFF7C4DFF,
            ).withValues(
              alpha: 0.35,
            ),
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(
                0xFF7C4DFF,
              ).withValues(
                alpha: 0.18,
              ),
              blurRadius: 30,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            // HEADER
            Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(
                      0xFFFFB74D,
                    ).withValues(
                      alpha: 0.12,
                    ),
                    border: Border.all(
                      color: const Color(
                        0xFFFFB74D,
                      ).withValues(
                        alpha: 0.35,
                      ),
                    ),
                  ),
                  child: const Icon(
                    Icons.warning_amber_rounded,
                    color: Color(
                      0xFFFFB74D,
                    ),
                    size: 24,
                  ),
                ),
                const SizedBox(
                  width: 14,
                ),
                const Expanded(
                  child: Text(
                    'DISCARD SELECTED TOPICS?',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.1,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(
              height: 18,
            ),

            // MESSAGE CARD
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(17),
                color: Colors.white.withValues(
                  alpha: 0.035,
                ),
                border: Border.all(
                  color: Colors.white.withValues(
                    alpha: 0.08,
                  ),
                ),
              ),
              child: const Text(
                'Are you sure to discard selected topics?',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                  height: 1.5,
                ),
              ),
            ),

            const SizedBox(
              height: 20,
            ),

            // BUTTONS
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.pop(
                        context,
                        false,
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(
                        0,
                        48,
                      ),
                      side: BorderSide(
                        color: Colors.white.withValues(
                          alpha: 0.14,
                        ),
                      ),
                      shape:
                          RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(
                          14,
                        ),
                      ),
                    ),
                    child: const Text(
                      'NO',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.4,
                      ),
                    ),
                  ),
                ),
                const SizedBox(
                  width: 10,
                ),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(
                        context,
                        true,
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(
                        0,
                        48,
                      ),
                      backgroundColor:
                          const Color(
                        0xFF7C4DFF,
                      ),
                      foregroundColor:
                          Colors.white,
                      elevation: 0,
                      shape:
                          RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(
                          14,
                        ),
                      ),
                    ),
                    child: const Text(
                      'YES',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.4,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/*
 * =========================================================
 * DEADLINE PRESSURE DIALOG
 * =========================================================
 */

class _PressureDialog
    extends StatelessWidget {
  final List<dynamic>
      pressure;

  const _PressureDialog({
    required this.pressure,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    return AlertDialog(
      backgroundColor:
          const Color(
        0xFF10121A,
      ),
      shape:
          RoundedRectangleBorder(
        borderRadius:
            BorderRadius.circular(
          24,
        ),
      ),
      title:
          const Text(
        'Deadline pressure',
        style:
            TextStyle(
          color:
              Colors.white,
          fontWeight:
              FontWeight.w800,
        ),
      ),
      content:
          SingleChildScrollView(
        child:
            Column(
          mainAxisSize:
              MainAxisSize.min,
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            const Text(
              'The deadline is approaching and the remaining topics require additional scheduling capacity.',
              style:
                  TextStyle(
                color:
                    Colors.white60,
                height:
                    1.4,
              ),
            ),
            const SizedBox(
              height: 14,
            ),
            ...pressure.map(
              (item) {
                if (item
                    is! Map) {
                  return const SizedBox.shrink();
                }

                final subject =
                    item[
                            'subjectName']
                        ?.toString() ??
                    '';

                final excess =
                    item[
                            'excess']
                        ?.toString() ??
                    '';

                return Padding(
                  padding:
                      const EdgeInsets.only(
                    bottom:
                        8,
                  ),
                  child:
                      Text(
                    '$subject  •  +$excess topics',
                    style:
                        const TextStyle(
                      color:
                          Colors.white,
                      fontSize:
                          12,
                      fontWeight:
                          FontWeight.w600,
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed:
              () =>
                  Navigator.pop(
            context,
            false,
          ),
          child:
              const Text(
            'LEAVE IT',
          ),
        ),
        ElevatedButton(
          onPressed:
              () =>
                  Navigator.pop(
            context,
            true,
          ),
          child:
              const Text(
            'SCHEDULE IT',
          ),
        ),
      ],
    );
  }
}