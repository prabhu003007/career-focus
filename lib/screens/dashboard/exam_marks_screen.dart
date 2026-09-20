import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/theme/jarvis_colors.dart';
import '../../services/api_service.dart';
import '../../services/token_service.dart';

class ExamMarksScreen extends StatefulWidget {
  final String examType;
  final String title;
  final Color accent;

  const ExamMarksScreen({
    super.key,
    required this.examType,
    required this.title,
    required this.accent,
  });

  @override
  State<ExamMarksScreen> createState() =>
      _ExamMarksScreenState();
}

class _ExamMarksScreenState
    extends State<ExamMarksScreen>
    with SingleTickerProviderStateMixin {
  final ApiService _api = ApiService();
  final TokenService _tokenService = TokenService();

  late final AnimationController _animationController;

  final Map<String, TextEditingController> _controllers = {};

  List<Map<String, dynamic>> _subjects = [];

  bool _loading = true;
  bool _saving = false;
  bool _saved = false;

  double _average = 0;
  int _enteredCount = 0;
  int _highest = 0;
  int _lowest = 0;

  bool get _isEndSem => widget.examType == 'endSem';

  int get _minimumValue => _isEndSem ? 5 : 0;

  int get _maximumValue => _isEndSem ? 10 : 100;

  String get _unitText => _isEndSem ? '/10 GP' : '/100';

  String get _rangeText {
    return _isEndSem
        ? 'VALID RANGE 5 – 10'
        : 'VALID RANGE 0 – 100';
  }

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(
        milliseconds: 1800,
      ),
    );

    _loadSubjects();
  }

  @override
  void dispose() {
    _animationController.dispose();

    for (final controller in _controllers.values) {
      controller.dispose();
    }

    super.dispose();
  }

  Future<void> _loadSubjects() async {
    try {
      final token = await _tokenService.getToken();

      if (token == null || token.isEmpty) {
        throw Exception('Session expired.');
      }

      final subjects = await _api.getSubjects(token);

      for (final controller in _controllers.values) {
        controller.dispose();
      }

      _controllers.clear();

      final loadedSubjects =
          <Map<String, dynamic>>[];

      for (final subject in subjects) {
        final data = <String, dynamic>{
          'id': subject.id,
          'name': subject.name,
          'code': subject.code,
          'assess1': subject.exams.assess1,
          'assess2': subject.exams.assess2,
          'endSem': subject.exams.endSem,
        };

        loadedSubjects.add(data);

        final existingValue =
            _getExistingValue(data);

        _controllers[subject.id] =
            TextEditingController(
          text: _formatValue(existingValue),
        );
      }

      if (!mounted) return;

      setState(() {
        _subjects = loadedSubjects;
        _loading = false;
      });

      _recalculate();
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _loading = false;
      });

      _showMessage(
        'LOAD FAILED',
        error.toString().replaceFirst(
              'Exception: ',
              '',
            ),
        const Color(0xFFFF5C7A),
      );
    }
  }

  int? _getExistingValue(
    Map<String, dynamic> subject,
  ) {
    final value = subject[widget.examType];

    if (value == null) {
      return null;
    }

    if (value is num) {
      return value.round();
    }

    return int.tryParse(
      value.toString(),
    );
  }

  String _formatValue(int? value) {
    if (value == null) {
      return '';
    }

    return value.toString();
  }

  void _recalculate() {
    final values = <int>[];

    for (final controller in _controllers.values) {
      final value = int.tryParse(
        controller.text.trim(),
      );

      if (value != null &&
          value >= _minimumValue &&
          value <= _maximumValue) {
        values.add(value);
      }
    }

    if (values.isEmpty) {
      if (!mounted) return;

      setState(() {
        _average = 0;
        _enteredCount = 0;
        _highest = 0;
        _lowest = 0;
      });

      return;
    }

    final total = values.fold<int>(
      0,
      (sum, value) => sum + value,
    );

    if (!mounted) return;

    setState(() {
      _average = total / values.length;
      _enteredCount = values.length;
      _highest = values.reduce(math.max);
      _lowest = values.reduce(math.min);
    });
  }

  Future<void> _saveMarks() async {
    if (_saving) return;

    final valuesToSave =
        <String, int?>{};

    for (final subject in _subjects) {
      final subjectId =
          subject['id'].toString();

      final raw =
          _controllers[subjectId]
                  ?.text
                  .trim() ??
              '';

      if (raw.isEmpty) {
        valuesToSave[subjectId] =
            _getExistingValue(subject);
        continue;
      }

      final value = int.tryParse(raw);

      if (value == null) {
        _showMessage(
          'INVALID VALUE',
          '${subject['name']} must contain a valid number.',
          const Color(0xFFFF5C7A),
        );

        return;
      }

      if (value < _minimumValue ||
          value > _maximumValue) {
        _showMessage(
          'VALUE OUT OF RANGE',
          _isEndSem
              ? '${subject['name']} must be between 5 and 10.'
              : '${subject['name']} must be between 0 and 100.',
          const Color(0xFFFF5C7A),
        );

        return;
      }

      valuesToSave[subjectId] = value;
    }

    final token =
        await _tokenService.getToken();

    if (token == null || token.isEmpty) {
      _showMessage(
        'SESSION ERROR',
        'Please sign in again.',
        const Color(0xFFFF5C7A),
      );

      return;
    }

    setState(() {
      _saving = true;
      _saved = false;
    });

    _animationController.forward(
      from: 0,
    );

    try {
      for (final subject in _subjects) {
        final subjectId =
            subject['id'].toString();

        final newValue =
            valuesToSave[subjectId];

        final existingAssess1 =
            _toInt(subject['assess1']);

        final existingAssess2 =
            _toInt(subject['assess2']);

        final existingEndSem =
            _toInt(subject['endSem']);

        if (widget.examType == 'assess1') {
          await _api.updateSubject(
            token,
            subjectId,
            assess1: newValue,
            assess2: existingAssess2,
            endSem: existingEndSem,
          );
        } else if (widget.examType ==
            'assess2') {
          await _api.updateSubject(
            token,
            subjectId,
            assess1: existingAssess1,
            assess2: newValue,
            endSem: existingEndSem,
          );
        } else if (widget.examType ==
            'endSem') {
          await _api.updateSubject(
            token,
            subjectId,
            assess1: existingAssess1,
            assess2: existingAssess2,
            endSem: newValue,
          );
        }
      }

      if (!mounted) return;

      for (final subject in _subjects) {
        final subjectId =
            subject['id'].toString();

        subject[widget.examType] =
            valuesToSave[subjectId];
      }

      setState(() {
        _saving = false;
        _saved = true;
      });

      _recalculate();

      await Future.delayed(
        const Duration(
          milliseconds: 450,
        ),
      );

      if (!mounted) return;

      _showSavedPanel();
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _saving = false;
      });

      _showMessage(
        'SYNC FAILED',
        error.toString().replaceFirst(
              'Exception: ',
              '',
            ),
        const Color(0xFFFF5C7A),
      );
    }
  }

  int? _toInt(dynamic value) {
    if (value == null) {
      return null;
    }

    if (value is int) {
      return value;
    }

    if (value is num) {
      return value.round();
    }

    return int.tryParse(
      value.toString(),
    );
  }

  void _showMessage(
    String title,
    String message,
    Color accent,
  ) {
    showDialog<void>(
      context: context,
      builder: (_) {
        return Dialog(
          backgroundColor:
              const Color(0xFF07111F),
          shape:
              RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(24),
            side: BorderSide(
              color:
                  accent.withValues(
                alpha: 0.45,
              ),
            ),
          ),
          child: Padding(
            padding:
                const EdgeInsets.all(22),
            child: Column(
              mainAxisSize:
                  MainAxisSize.min,
              children: [
                Container(
                  width: 58,
                  height: 58,
                  decoration:
                      BoxDecoration(
                    shape:
                        BoxShape.circle,
                    color:
                        accent.withValues(
                      alpha: 0.10,
                    ),
                    border: Border.all(
                      color:
                          accent.withValues(
                        alpha: 0.45,
                      ),
                    ),
                  ),
                  child: Icon(
                    Icons
                        .warning_amber_rounded,
                    color: accent,
                    size: 28,
                  ),
                ),
                const SizedBox(
                  height: 16,
                ),
                Text(
                  title,
                  style:
                      const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight:
                        FontWeight.w900,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(
                  height: 8,
                ),
                Text(
                  message,
                  textAlign:
                      TextAlign.center,
                  style:
                      const TextStyle(
                    color:
                        Color(0xFF91A3B8),
                    fontSize: 11,
                    height: 1.5,
                  ),
                ),
                const SizedBox(
                  height: 18,
                ),
                SizedBox(
                  width:
                      double.infinity,
                  height: 46,
                  child:
                      ElevatedButton(
                    onPressed: () {
                      Navigator.pop(
                        context,
                      );
                    },
                    style:
                        ElevatedButton
                            .styleFrom(
                      backgroundColor:
                          accent.withValues(
                        alpha: 0.13,
                      ),
                      foregroundColor:
                          accent,
                      elevation: 0,
                      shape:
                          RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius
                                .circular(
                          14,
                        ),
                      ),
                    ),
                    child:
                        const Text(
                      'OK',
                      style: TextStyle(
                        fontWeight:
                            FontWeight.w800,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showSavedPanel() {
    showModalBottomSheet(
      context: context,
      backgroundColor:
          Colors.transparent,
      isScrollControlled: true,
      builder: (_) {
        return _SavedAnalysisPanel(
          examTitle: widget.title,
          accent: widget.accent,
          average: _average,
          enteredCount:
              _enteredCount,
          totalSubjects:
              _subjects.length,
          highest: _highest,
          lowest: _lowest,
          isEndSem: _isEndSem,
        );
      },
    );
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    return Scaffold(
      backgroundColor:
          const Color(0xFF020711),
      body: Stack(
        children: [
          Positioned.fill(
            child: AnimatedBuilder(
              animation:
                  _animationController,
              builder: (_, _) {
                return CustomPaint(
                  painter:
                      _MarksBackgroundPainter(
                    progress:
                        _animationController
                            .value,
                    accent:
                        widget.accent,
                  ),
                );
              },
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                _buildHeader(),
                if (!_loading)
                  _buildAnalysisStrip(),
                Expanded(
                  child: _loading
                      ? _buildLoading()
                      : _buildSubjectList(),
                ),
                if (!_loading)
                  _buildSaveArea(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding:
          const EdgeInsets.fromLTRB(
        18,
        16,
        18,
        12,
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () =>
                Navigator.pop(context),
            child: Container(
              width: 42,
              height: 42,
              decoration:
                  BoxDecoration(
                borderRadius:
                    BorderRadius.circular(
                  13,
                ),
                color:
                    widget.accent.withValues(
                  alpha: 0.08,
                ),
                border: Border.all(
                  color:
                      widget.accent.withValues(
                    alpha: 0.30,
                  ),
                ),
              ),
              child: Icon(
                Icons
                    .arrow_back_rounded,
                color:
                    widget.accent,
                size: 20,
              ),
            ),
          ),
          const SizedBox(
            width: 12,
          ),
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment
                      .start,
              children: [
                Text(
                  widget.title
                      .toUpperCase(),
                  style:
                      const TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight:
                        FontWeight.w900,
                    letterSpacing: 1.3,
                  ),
                ),
                const SizedBox(
                  height: 3,
                ),
                Text(
                  _isEndSem
                      ? 'GRADE POINT CONTROL'
                      : 'ACADEMIC MARKS CONTROL',
                  style:
                      const TextStyle(
                    color:
                        Color(0xFF6D819C),
                    fontSize: 8,
                    fontWeight:
                        FontWeight.w700,
                    letterSpacing: 1.3,
                  ),
                ),
              ],
            ),
          ),
          AnimatedBuilder(
            animation:
                _animationController,
            builder: (_, _) {
              return Transform.rotate(
                angle:
                    _animationController
                            .value *
                        math.pi *
                        2,
                child: Icon(
                  Icons
                      .settings_input_antenna_rounded,
                  color:
                      widget.accent
                          .withValues(
                    alpha: 0.75,
                  ),
                  size: 22,
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAnalysisStrip() {
    return Padding(
      padding:
          const EdgeInsets.fromLTRB(
        18,
        0,
        18,
        10,
      ),
      child: Row(
        children: [
          Expanded(
            child: _miniMetric(
              'ENTERED',
              '$_enteredCount/${_subjects.length}',
              widget.accent,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _miniMetric(
              'AVERAGE',
              _enteredCount == 0
                  ? '--'
                  : _isEndSem
                      ? _average
                          .toStringAsFixed(
                          1,
                        )
                      : '${_average.toStringAsFixed(1)}%',
              const Color(
                0xFFB77CFF,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _miniMetric(
              'PEAK',
              _enteredCount == 0
                  ? '--'
                  : _highest
                      .toString(),
              JarvisColors.green,
            ),
          ),
        ],
      ),
    );
  }

  Widget _miniMetric(
    String label,
    String value,
    Color accent,
  ) {
    return Container(
      padding:
          const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 10,
      ),
      decoration:
          BoxDecoration(
        color:
            const Color(0xFF07111F),
        borderRadius:
            BorderRadius.circular(
          15,
        ),
        border: Border.all(
          color:
              accent.withValues(
            alpha: 0.22,
          ),
        ),
      ),
      child: Column(
        children: [
          Text(
            label,
            style:
                const TextStyle(
              color:
                  Color(0xFF667B94),
              fontSize: 7,
              fontWeight:
                  FontWeight.w800,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(
            height: 3,
          ),
          Text(
            value,
            style: TextStyle(
              color: accent,
              fontSize: 13,
              fontWeight:
                  FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoading() {
    return Center(
      child: Column(
        mainAxisAlignment:
            MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 72,
            height: 72,
            child:
                CircularProgressIndicator(
              strokeWidth: 2,
              color:
                  widget.accent,
            ),
          ),
          const SizedBox(
            height: 18,
          ),
          Text(
            'LOADING ${widget.title.toUpperCase()}',
            style: TextStyle(
              color:
                  widget.accent,
              fontSize: 10,
              fontWeight:
                  FontWeight.w800,
              letterSpacing: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubjectList() {
    if (_subjects.isEmpty) {
      return const Center(
        child: Text(
          'NO SUBJECTS AVAILABLE',
          style: TextStyle(
            color:
                Color(0xFF72869E),
            fontSize: 11,
            fontWeight:
                FontWeight.w800,
            letterSpacing: 1,
          ),
        ),
      );
    }

    return ListView.builder(
      padding:
          const EdgeInsets.fromLTRB(
        18,
        4,
        18,
        18,
      ),
      itemCount:
          _subjects.length,
      itemBuilder: (_, index) {
        return Padding(
          padding:
              const EdgeInsets.only(
            bottom: 10,
          ),
          child:
              _buildSubjectCard(
            _subjects[index],
            index,
          ),
        );
      },
    );
  }

  Widget _buildSubjectCard(
    Map<String, dynamic> subject,
    int index,
  ) {
    final subjectId =
        subject['id'].toString();

    final controller =
        _controllers[subjectId]!;

    return AnimatedBuilder(
      animation:
          _animationController,
      builder: (_, child) {
        final pulse =
            0.16 +
            math.sin(
                  _animationController
                          .value *
                      math.pi *
                      2 +
                  index * 0.5,
                ) *
                0.04;

        return Container(
          padding:
              const EdgeInsets.all(
            15,
          ),
          decoration:
              BoxDecoration(
            color:
                const Color(0xFF07111F),
            borderRadius:
                BorderRadius.circular(
              21,
            ),
            border: Border.all(
              color:
                  widget.accent
                      .withValues(
                alpha: pulse,
              ),
            ),
            boxShadow: [
              BoxShadow(
                color:
                    widget.accent
                        .withValues(
                  alpha: 0.035,
                ),
                blurRadius: 20,
              ),
            ],
          ),
          child: child,
        );
      },
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration:
                BoxDecoration(
              shape:
                  BoxShape.circle,
              color:
                  widget.accent
                      .withValues(
                alpha: 0.07,
              ),
              border: Border.all(
                color:
                    widget.accent
                        .withValues(
                  alpha: 0.28,
                ),
              ),
            ),
            child: Center(
              child: Text(
                '${index + 1}'
                    .padLeft(
                  2,
                  '0',
                ),
                style: TextStyle(
                  color:
                      widget.accent,
                  fontSize: 12,
                  fontWeight:
                      FontWeight.w900,
                ),
              ),
            ),
          ),
          const SizedBox(
            width: 13,
          ),
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment
                      .start,
              children: [
                Text(
                  subject['name']
                          ?.toString() ??
                      'Subject',
                  maxLines: 2,
                  overflow:
                      TextOverflow
                          .ellipsis,
                  style:
                      const TextStyle(
                    color:
                        Colors.white,
                    fontSize: 13,
                    fontWeight:
                        FontWeight.w800,
                  ),
                ),
                const SizedBox(
                  height: 5,
                ),
                Text(
                  subject['code']
                              ?.toString()
                              .isEmpty ??
                          true
                      ? 'ACADEMIC SUBJECT'
                      : subject['code']
                          .toString()
                          .toUpperCase(),
                  style:
                      const TextStyle(
                    color:
                        Color(0xFF6E839B),
                    fontSize: 8,
                    fontWeight:
                        FontWeight.w700,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(
                  height: 4,
                ),
                Text(
                  _rangeText,
                  style: TextStyle(
                    color: widget
                        .accent
                        .withValues(
                      alpha: 0.60,
                    ),
                    fontSize: 7,
                    fontWeight:
                        FontWeight.w800,
                    letterSpacing:
                        0.7,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(
            width: 10,
          ),
          SizedBox(
            width: 88,
            child: TextField(
              controller:
                  controller,
              keyboardType:
                  TextInputType.number,
              textAlign:
                  TextAlign.center,
              onChanged: (_) {
                _recalculate();

                if (_saved) {
                  setState(() {
                    _saved = false;
                  });
                }
              },
              style: TextStyle(
                color:
                    widget.accent,
                fontSize: 17,
                fontWeight:
                    FontWeight.w900,
              ),
              decoration:
                  InputDecoration(
                hintText:
                    _isEndSem
                        ? '5'
                        : '--',
                hintStyle:
                    const TextStyle(
                  color:
                      Color(0xFF40536A),
                  fontWeight:
                      FontWeight.w800,
                ),
                suffixText:
                    _unitText,
                suffixStyle:
                    const TextStyle(
                  color:
                      Color(0xFF60758D),
                  fontSize: 8,
                  fontWeight:
                      FontWeight.w700,
                ),
                filled: true,
                fillColor:
                    widget.accent
                        .withValues(
                  alpha: 0.045,
                ),
                contentPadding:
                    const EdgeInsets
                        .symmetric(
                  horizontal: 7,
                  vertical: 13,
                ),
                border:
                    OutlineInputBorder(
                  borderRadius:
                      BorderRadius.circular(
                    14,
                  ),
                  borderSide:
                      BorderSide(
                    color: widget
                        .accent
                        .withValues(
                      alpha: 0.20,
                    ),
                  ),
                ),
                enabledBorder:
                    OutlineInputBorder(
                  borderRadius:
                      BorderRadius.circular(
                    14,
                  ),
                  borderSide:
                      BorderSide(
                    color: widget
                        .accent
                        .withValues(
                      alpha: 0.20,
                    ),
                  ),
                ),
                focusedBorder:
                    OutlineInputBorder(
                  borderRadius:
                      BorderRadius.circular(
                    14,
                  ),
                  borderSide:
                      BorderSide(
                    color: widget
                        .accent
                        .withValues(
                      alpha: 0.70,
                    ),
                    width: 1.3,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSaveArea() {
    final buttonColor =
        _saved
            ? JarvisColors.green
            : widget.accent;

    return Container(
      padding:
          const EdgeInsets.fromLTRB(
        18,
        12,
        18,
        18,
      ),
      decoration:
          BoxDecoration(
        color:
            const Color(0xFF020711)
                .withValues(
          alpha: 0.96,
        ),
        border: Border(
          top: BorderSide(
            color:
                widget.accent
                    .withValues(
              alpha: 0.10,
            ),
          ),
        ),
      ),
      child: GestureDetector(
        onTap: _saving
            ? null
            : _saveMarks,
        child:
            AnimatedContainer(
          duration:
              const Duration(
            milliseconds: 250,
          ),
          height: 56,
          decoration:
              BoxDecoration(
            borderRadius:
                BorderRadius.circular(
              18,
            ),
            gradient:
                LinearGradient(
              colors: _saved
                  ? [
                      JarvisColors
                          .green
                          .withValues(
                        alpha: 0.20,
                      ),
                      JarvisColors
                          .cyan
                          .withValues(
                        alpha: 0.12,
                      ),
                    ]
                  : [
                      widget.accent
                          .withValues(
                        alpha: 0.18,
                      ),
                      const Color(
                        0xFF7B4DFF,
                      ).withValues(
                        alpha: 0.14,
                      ),
                    ],
            ),
            border: Border.all(
              color:
                  buttonColor
                      .withValues(
                alpha: 0.45,
              ),
            ),
            boxShadow: [
              BoxShadow(
                color:
                    buttonColor
                        .withValues(
                  alpha: 0.10,
                ),
                blurRadius: 20,
              ),
            ],
          ),
          child: Center(
            child: _saving
                ? Row(
                    mainAxisAlignment:
                        MainAxisAlignment
                            .center,
                    children: [
                      SizedBox(
                        width: 18,
                        height: 18,
                        child:
                            CircularProgressIndicator(
                          strokeWidth: 2,
                          color:
                              widget.accent,
                        ),
                      ),
                      const SizedBox(
                        width: 10,
                      ),
                      Text(
                        'SYNCHRONIZING MARKS',
                        style:
                            TextStyle(
                          color:
                              widget.accent,
                          fontSize: 10,
                          fontWeight:
                              FontWeight.w900,
                          letterSpacing:
                              1.2,
                        ),
                      ),
                    ],
                  )
                : Row(
                    mainAxisAlignment:
                        MainAxisAlignment
                            .center,
                    children: [
                      Icon(
                        _saved
                            ? Icons
                                .check_circle_outline_rounded
                            : Icons
                                .cloud_upload_outlined,
                        color:
                            buttonColor,
                        size: 20,
                      ),
                      const SizedBox(
                        width: 9,
                      ),
                      Text(
                        _saved
                            ? 'MARKS SYNCHRONIZED'
                            : 'SAVE MARKS',
                        style:
                            TextStyle(
                          color:
                              buttonColor,
                          fontSize: 11,
                          fontWeight:
                              FontWeight.w900,
                          letterSpacing:
                              1.3,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

class _SavedAnalysisPanel
    extends StatelessWidget {
  final String examTitle;
  final Color accent;
  final double average;
  final int enteredCount;
  final int totalSubjects;
  final int highest;
  final int lowest;
  final bool isEndSem;

  const _SavedAnalysisPanel({
    required this.examTitle,
    required this.accent,
    required this.average,
    required this.enteredCount,
    required this.totalSubjects,
    required this.highest,
    required this.lowest,
    required this.isEndSem,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    final coverage =
        totalSubjects == 0
            ? 0.0
            : enteredCount /
                totalSubjects;

    return Container(
      padding:
          const EdgeInsets.fromLTRB(
        20,
        14,
        20,
        28,
      ),
      decoration:
          BoxDecoration(
        color:
            const Color(0xFF06101D),
        borderRadius:
            const BorderRadius.vertical(
          top: Radius.circular(30),
        ),
        border: Border(
          top: BorderSide(
            color:
                accent.withValues(
              alpha: 0.40,
            ),
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize:
              MainAxisSize.min,
          children: [
            Container(
              width: 42,
              height: 4,
              decoration:
                  BoxDecoration(
                color:
                    accent.withValues(
                  alpha: 0.45,
                ),
                borderRadius:
                    BorderRadius.circular(
                  5,
                ),
              ),
            ),
            const SizedBox(
              height: 20,
            ),
            Container(
              width: 72,
              height: 72,
              decoration:
                  BoxDecoration(
                shape:
                    BoxShape.circle,
                color:
                    JarvisColors
                        .green
                        .withValues(
                  alpha: 0.08,
                ),
                border: Border.all(
                  color:
                      JarvisColors
                          .green
                          .withValues(
                    alpha: 0.50,
                  ),
                ),
              ),
              child: const Icon(
                Icons.check_rounded,
                color:
                    JarvisColors.green,
                size: 38,
              ),
            ),
            const SizedBox(
              height: 14,
            ),
            const Text(
              'MARKS SYNCHRONIZED',
              style:
                  TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight:
                    FontWeight.w900,
                letterSpacing: 1.4,
              ),
            ),
            const SizedBox(
              height: 5,
            ),
            Text(
              isEndSem
                  ? 'Grade point data is now available for academic planning.'
                  : '$examTitle data is now available for academic planning.',
              textAlign:
                  TextAlign.center,
              style:
                  const TextStyle(
                color:
                    Color(0xFF8194AA),
                fontSize: 10,
                height: 1.4,
              ),
            ),
            const SizedBox(
              height: 20,
            ),
            Row(
              children: [
                Expanded(
                  child:
                      _analysisCard(
                    'AVERAGE',
                    isEndSem
                        ? '${average.toStringAsFixed(1)} / 10'
                        : '${average.toStringAsFixed(1)} / 100',
                    accent,
                  ),
                ),
                const SizedBox(
                  width: 8,
                ),
                Expanded(
                  child:
                      _analysisCard(
                    'HIGHEST',
                    highest == 0
                        ? '--'
                        : '$highest',
                    JarvisColors
                        .green,
                  ),
                ),
                const SizedBox(
                  width: 8,
                ),
                Expanded(
                  child:
                      _analysisCard(
                    'LOWEST',
                    lowest == 0
                        ? '--'
                        : '$lowest',
                    const Color(
                      0xFFFFB86C,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(
              height: 14,
            ),
            Container(
              padding:
                  const EdgeInsets.all(
                14,
              ),
              decoration:
                  BoxDecoration(
                color:
                    accent.withValues(
                  alpha: 0.045,
                ),
                borderRadius:
                    BorderRadius.circular(
                  17,
                ),
                border: Border.all(
                  color:
                      accent.withValues(
                    alpha: 0.16,
                  ),
                ),
              ),
              child: Row(
                children: [
                  SizedBox(
                    width: 46,
                    height: 46,
                    child: Stack(
                      alignment:
                          Alignment.center,
                      children: [
                        CircularProgressIndicator(
                          value:
                              coverage,
                          strokeWidth: 3,
                          backgroundColor:
                              accent
                                  .withValues(
                            alpha: 0.08,
                          ),
                          color: accent,
                        ),
                        Text(
                          '${(coverage * 100).round()}%',
                          style:
                              TextStyle(
                            color:
                                accent,
                            fontSize: 8,
                            fontWeight:
                                FontWeight
                                    .w900,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(
                    width: 12,
                  ),
                  Expanded(
                    child:
                        Column(
                      crossAxisAlignment:
                          CrossAxisAlignment
                              .start,
                      children: [
                        const Text(
                          'DATA COVERAGE',
                          style:
                              TextStyle(
                            color:
                                Colors.white,
                            fontSize: 10,
                            fontWeight:
                                FontWeight
                                    .w800,
                            letterSpacing:
                                1,
                          ),
                        ),
                        const SizedBox(
                          height: 4,
                        ),
                        Text(
                          '$enteredCount of $totalSubjects subjects recorded',
                          style:
                              const TextStyle(
                            color:
                                Color(
                              0xFF7D91A8,
                            ),
                            fontSize: 9,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(
              height: 18,
            ),
            SizedBox(
              width:
                  double.infinity,
              height: 50,
              child:
                  ElevatedButton(
                onPressed: () {
                  Navigator.pop(
                    context,
                  );
                },
                style:
                    ElevatedButton
                        .styleFrom(
                  backgroundColor:
                      accent.withValues(
                    alpha: 0.12,
                  ),
                  foregroundColor:
                      accent,
                  elevation: 0,
                  shape:
                      RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius
                            .circular(
                      15,
                    ),
                    side: BorderSide(
                      color:
                          accent
                              .withValues(
                        alpha: 0.28,
                      ),
                    ),
                  ),
                ),
                child:
                    const Text(
                  'CONTINUE',
                  style:
                      TextStyle(
                    fontSize: 10,
                    fontWeight:
                        FontWeight.w900,
                    letterSpacing: 1.4,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _analysisCard(
    String label,
    String value,
    Color color,
  ) {
    return Container(
      padding:
          const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 13,
      ),
      decoration:
          BoxDecoration(
        color:
            color.withValues(
          alpha: 0.045,
        ),
        borderRadius:
            BorderRadius.circular(
          15,
        ),
        border: Border.all(
          color:
              color.withValues(
            alpha: 0.16,
          ),
        ),
      ),
      child: Column(
        children: [
          Text(
            label,
            style:
                const TextStyle(
              color:
                  Color(0xFF657991),
              fontSize: 7,
              fontWeight:
                  FontWeight.w800,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(
            height: 5,
          ),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 14,
              fontWeight:
                  FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _MarksBackgroundPainter
    extends CustomPainter {
  final double progress;
  final Color accent;

  _MarksBackgroundPainter({
    required this.progress,
    required this.accent,
  });

  @override
  void paint(
    Canvas canvas,
    Size size,
  ) {
    final ringPaint =
        Paint()
          ..style =
              PaintingStyle.stroke
          ..strokeWidth = 0.5
          ..color =
              accent.withValues(
            alpha: 0.035,
          );

    final center = Offset(
      size.width * 0.82,
      size.height * 0.16,
    );

    final maxRadius =
        size.width * 0.65;

    for (int i = 0; i < 7; i++) {
      final radius =
          maxRadius *
                  ((i + 1) / 7) +
              math.sin(
                    progress *
                            math.pi *
                            2 +
                        i,
                  ) *
                  5;

      canvas.drawCircle(
        center,
        radius,
        ringPaint,
      );
    }

    final gridPaint =
        Paint()
          ..color =
              accent.withValues(
            alpha: 0.018,
          )
          ..strokeWidth = 0.5;

    const spacing = 38.0;

    for (
      double x = 0;
      x < size.width;
      x += spacing
    ) {
      canvas.drawLine(
        Offset(x, 0),
        Offset(x, size.height),
        gridPaint,
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
        gridPaint,
      );
    }
  }

  @override
  bool shouldRepaint(
    covariant
        _MarksBackgroundPainter
            oldDelegate,
  ) {
    return oldDelegate.progress !=
            progress ||
        oldDelegate.accent !=
            accent;
  }
}