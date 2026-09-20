import 'package:flutter/material.dart';

import '../../core/theme/jarvis_colors.dart';
import '../../services/api_service.dart';
import '../../services/token_service.dart';
import '../../widgets/ai_core_orb.dart';
import '../../widgets/ai_status_indicator.dart';
import '../../widgets/glass_panel.dart';

class ExamIntelligenceScreen extends StatefulWidget {
  const ExamIntelligenceScreen({
    super.key,
  });

  @override
  State<ExamIntelligenceScreen> createState() =>
      _ExamIntelligenceScreenState();
}

class _ExamIntelligenceScreenState
    extends State<ExamIntelligenceScreen> {
  final ApiService _api = ApiService();
  final TokenService _tokenService = TokenService();

  bool _loading = true;
  bool _saving = false;

  List<Map<String, dynamic>> _subjects = [];

  @override
  void initState() {
    super.initState();
    _loadSubjects();
  }

  Future<void> _loadSubjects() async {
    try {
      final token = await _tokenService.getToken();

      if (token == null || token.isEmpty) {
        throw Exception('Session expired.');
      }

      final subjects =
          await _api.getSubjects(token);

      if (!mounted) return;

      setState(() {
        _subjects = subjects.map((subject) {
          return {
            'id': subject.id,
            'name': subject.name,
            'code': subject.code,
            'assess1': subject.exams.assess1,
            'assess2': subject.exams.assess2,
            'endSem': subject.exams.endSem,
          };
        }).toList();

        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _loading = false;
      });

      _message(
        error.toString().replaceFirst(
              'Exception: ',
              '',
            ),
        error: true,
      );
    }
  }

  Future<void> _editMarks(
    Map<String, dynamic> subject,
  ) async {
    final assess1 =
        TextEditingController(
      text: _displayValue(
        subject['assess1'],
      ),
    );

    final assess2 =
        TextEditingController(
      text: _displayValue(
        subject['assess2'],
      ),
    );

    final endSem =
        TextEditingController(
      text: _displayValue(
        subject['endSem'],
      ),
    );

    final result =
        await showDialog<Map<String, double?>>(
      context: context,
      builder: (dialogContext) {
        return _MarksDialog(
          subjectName:
              subject['name']?.toString() ??
                  'Subject',
          assess1: assess1,
          assess2: assess2,
          endSem: endSem,
        );
      },
    );

    assess1.dispose();
    assess2.dispose();
    endSem.dispose();

    if (result == null) return;

    await _saveMarks(
      subject,
      result,
    );
  }

  Future<void> _saveMarks(
    Map<String, dynamic> subject,
    Map<String, double?> marks,
  ) async {
    if (_saving) return;

    final token = await _tokenService.getToken();

    if (token == null || token.isEmpty) {
      return;
    }

    setState(() {
      _saving = true;
    });

    try {
      final updated =
    await _api.updateSubject(
  token,
  subject['id'].toString(),
  assess1: marks['assess1']?.round(),
  assess2: marks['assess2']?.round(),
  endSem: marks['endSem']?.round(),
);

      if (!mounted) return;

      setState(() {
        subject['assess1'] =
            updated.exams.assess1;
        subject['assess2'] =
            updated.exams.assess2;
        subject['endSem'] =
            updated.exams.endSem;
        _saving = false;
      });

      _message(
        'Exam intelligence updated.',
      );
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _saving = false;
      });

      _message(
        error.toString().replaceFirst(
              'Exception: ',
              '',
            ),
        error: true,
      );
    }
  }

  double _average(
    Map<String, dynamic> subject,
  ) {
    final values = [
      subject['assess1'],
      subject['assess2'],
      subject['endSem'],
    ].whereType<num>().map(
          (value) => value.toDouble(),
        ).toList();

    if (values.isEmpty) return 0;

    return values.reduce(
          (a, b) => a + b,
        ) /
        values.length;
  }

  int _available(
    Map<String, dynamic> subject,
  ) {
    return [
      subject['assess1'],
      subject['assess2'],
      subject['endSem'],
    ].whereType<num>().length;
  }

  double _examAverage(String key) {
    final values = _subjects
        .map((subject) => subject[key])
        .whereType<num>()
        .map((value) => value.toDouble())
        .toList();

    if (values.isEmpty) return 0;

    return values.reduce(
          (a, b) => a + b,
        ) /
        values.length;
  }

  String _displayValue(dynamic value) {
    if (value == null) return '';

    if (value is num) {
      return value % 1 == 0
          ? value.toInt().toString()
          : value.toString();
    }

    return value.toString();
  }

  void _message(
    String message, {
    bool error = false,
  }) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
        .hideCurrentSnackBar();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior:
            SnackBarBehavior.floating,
        backgroundColor: error
            ? const Color(0xFF7F1D1D)
            : const Color(0xFF10284A),
        shape:
            RoundedRectangleBorder(
          borderRadius:
              BorderRadius.circular(15),
        ),
        content: Text(
          message,
          style: const TextStyle(
            color: Colors.white,
            fontWeight:
                FontWeight.w600,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          const Color(0xFF030711),
      body: SafeArea(
        child: _loading
            ? const Center(
                child:
                    CircularProgressIndicator(
                  color: Color(0xFF00E5FF),
                ),
              )
            : RefreshIndicator(
                color: JarvisColors.cyan,
                backgroundColor:
                    const Color(0xFF0B1324),
                onRefresh: _loadSubjects,
                child: SingleChildScrollView(
                  physics:
                      const AlwaysScrollableScrollPhysics(),
                  padding:
                      const EdgeInsets.fromLTRB(
                    18,
                    14,
                    18,
                    35,
                  ),
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      _header(),
                      const SizedBox(height: 20),
                      _coreCard(),
                      const SizedBox(height: 20),
                      _sectionTitle(),
                      const SizedBox(height: 12),
                      ..._subjects.map(
                        _subjectCard,
                      ),
                      const SizedBox(height: 20),
                      _comparisonCard(),
                      const SizedBox(height: 20),
                      _aiCard(),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  Widget _header() {
    return Row(
      children: [
        GestureDetector(
          onTap: () =>
              Navigator.of(context).pop(),
          child: Container(
            width: 42,
            height: 42,
            decoration:
                BoxDecoration(
              borderRadius:
                  BorderRadius.circular(13),
              color: JarvisColors.cyan
                  .withValues(alpha: 0.07),
              border: Border.all(
                color: JarvisColors.cyan
                    .withValues(alpha: 0.25),
              ),
            ),
            child: const Icon(
              Icons.arrow_back_ios_new_rounded,
              color: Color(0xFF00E5FF),
              size: 17,
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
                'EXAM INTELLIGENCE',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight:
                      FontWeight.w900,
                  letterSpacing: 1.4,
                ),
              ),
              SizedBox(height: 3),
              Text(
                'ACADEMIC PERFORMANCE ENGINE',
                style: TextStyle(
                  color: Color(0xFF647A93),
                  fontSize: 8,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
        ),
        const AiStatusIndicator(
          label: 'AI INPUT',
        ),
      ],
    );
  }

  Widget _coreCard() {
    final overall = _subjects.isEmpty
        ? 0
        : _subjects
                .map(_average)
                .reduce(
                  (a, b) => a + b,
                ) /
            _subjects.length;

    return GlassPanel(
      radius: 25,
      padding: const EdgeInsets.all(18),
      borderColor:
          const Color(0xFF8B5CF6),
      child: Row(
        children: [
          const AiCoreOrb(size: 92),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                const Text(
                  'ACADEMIC PERFORMANCE CORE',
                  style: TextStyle(
                    color: Color(0xFFB77CFF),
                    fontSize: 9,
                    fontWeight:
                        FontWeight.w800,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 7),
                Text(
                  '${overall.toStringAsFixed(1)}%',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 27,
                    fontWeight:
                        FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                const Text(
                  'AVAILABLE MARKS AVERAGE',
                  style: TextStyle(
                    color: Color(0xFF6E839B),
                    fontSize: 8,
                    letterSpacing: 0.9,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle() {
    return Row(
      children: [
        Container(
          width: 3,
          height: 28,
          decoration: BoxDecoration(
            color: JarvisColors.cyan,
            borderRadius:
                BorderRadius.circular(5),
          ),
        ),
        const SizedBox(width: 9),
        const Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Text(
              'SUBJECT PERFORMANCE',
              style: TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight:
                    FontWeight.w900,
                letterSpacing: 1.2,
              ),
            ),
            SizedBox(height: 3),
            Text(
              'ENTER OR UPDATE EXAM RESULTS',
              style: TextStyle(
                color: Color(0xFF60758F),
                fontSize: 7,
                letterSpacing: 0.8,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _subjectCard(
    Map<String, dynamic> subject,
  ) {
    final average =
        _average(subject);
    final available =
        _available(subject);

    final color = available == 0
        ? JarvisColors.cyan
        : average >= 75
            ? JarvisColors.green
            : average >= 50
                ? const Color(0xFFFFC857)
                : const Color(0xFFFF5F7A);

    return Padding(
      padding:
          const EdgeInsets.only(bottom: 10),
      child: GlassPanel(
        radius: 19,
        borderColor: color,
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 43,
                  height: 43,
                  decoration: BoxDecoration(
                    borderRadius:
                        BorderRadius.circular(12),
                    color: color.withValues(
                      alpha: 0.08,
                    ),
                    border: Border.all(
                      color: color.withValues(
                        alpha: 0.25,
                      ),
                    ),
                  ),
                  child: Icon(
                    Icons.school_rounded,
                    color: color,
                    size: 21,
                  ),
                ),
                const SizedBox(width: 11),
                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Text(
                        subject['name']
                                ?.toString()
                                .toUpperCase() ??
                            'SUBJECT',
                        maxLines: 1,
                        overflow:
                            TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight:
                              FontWeight.w900,
                          letterSpacing: 0.7,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        available == 0
                            ? 'NO RESULTS AVAILABLE'
                            : '$available / 3 RESULTS AVAILABLE',
                        style: TextStyle(
                          color: color,
                          fontSize: 7,
                          fontWeight:
                              FontWeight.w700,
                          letterSpacing: 0.7,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  available == 0
                      ? '--'
                      : '${average.toStringAsFixed(0)}%',
                  style: TextStyle(
                    color: color,
                    fontSize: 16,
                    fontWeight:
                        FontWeight.w900,
                  ),
                ),
                IconButton(
                  onPressed: _saving
                      ? null
                      : () => _editMarks(
                            subject,
                          ),
                  icon: const Icon(
                    Icons.edit_rounded,
                    size: 17,
                  ),
                  color:
                      JarvisColors.cyan,
                ),
              ],
            ),
            const SizedBox(height: 13),
            Row(
              children: [
                _examMini(
                  'A1',
                  subject['assess1'],
                ),
                _examMini(
                  'A2',
                  subject['assess2'],
                ),
                _examMini(
                  'END',
                  subject['endSem'],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _examMini(
    String label,
    dynamic value,
  ) {
    final available = value != null;

    return Expanded(
      child: Container(
        margin:
            const EdgeInsets.only(right: 6),
        padding:
            const EdgeInsets.symmetric(
          vertical: 8,
        ),
        decoration: BoxDecoration(
          color:
              const Color(0xFF081423),
          borderRadius:
              BorderRadius.circular(10),
          border: Border.all(
            color: available
                ? JarvisColors.cyan
                    .withValues(alpha: 0.18)
                : const Color(0xFF1B2D43),
          ),
        ),
        child: Column(
          children: [
            Text(
              label,
              style: const TextStyle(
                color: Color(0xFF667C94),
                fontSize: 7,
                fontWeight:
                    FontWeight.w800,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              available
                  ? _displayValue(value)
                  : '--',
              style: TextStyle(
                color: available
                    ? Colors.white
                    : const Color(0xFF52677F),
                fontSize: 11,
                fontWeight:
                    FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _comparisonCard() {
    final values = [
      _examAverage('assess1'),
      _examAverage('assess2'),
      _examAverage('endSem'),
    ];

    const labels = [
      'ASSESS 1',
      'ASSESS 2',
      'END SEM',
    ];

    return GlassPanel(
      radius: 21,
      padding: const EdgeInsets.all(16),
      borderColor:
          const Color(0xFF263C57),
      child: Column(
        children: [
          const Row(
            children: [
              Icon(
                Icons.compare_arrows_rounded,
                color: Color(0xFF00E5FF),
                size: 18,
              ),
              SizedBox(width: 8),
              Text(
                'EXAM COMPARISON',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight:
                      FontWeight.w900,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          ...List.generate(
            3,
            (index) {
              final value = values[index];

              return Padding(
                padding:
                    const EdgeInsets.only(
                  bottom: 13,
                ),
                child: Row(
                  children: [
                    SizedBox(
                      width: 68,
                      child: Text(
                        labels[index],
                        style: const TextStyle(
                          color:
                              Color(0xFF71859C),
                          fontSize: 8,
                          fontWeight:
                              FontWeight.w700,
                        ),
                      ),
                    ),
                    Expanded(
                      child: ClipRRect(
                        borderRadius:
                            BorderRadius.circular(
                          10,
                        ),
                        child:
                            LinearProgressIndicator(
                          value: value / 100,
                          minHeight: 8,
                          backgroundColor:
                              const Color(
                            0xFF17283D,
                          ),
                          valueColor:
                              const AlwaysStoppedAnimation<
                                  Color>(
                            Color(0xFF8B5CF6),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    SizedBox(
                      width: 40,
                      child: Text(
                        value == 0
                            ? '--'
                            : value
                                .toStringAsFixed(0),
                        textAlign:
                            TextAlign.right,
                        style:
                            const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight:
                              FontWeight.w900,
                        ),
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

  Widget _aiCard() {
    return GlassPanel(
      radius: 21,
      padding: const EdgeInsets.all(16),
      borderColor:
          const Color(0xFF8B5CF6),
      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          const AiCoreOrb(size: 48),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  'AI SCHEDULING INPUT',
                  style: TextStyle(
                    color: Color(0xFFB77CFF),
                    fontSize: 9,
                    fontWeight:
                        FontWeight.w900,
                    letterSpacing: 1.2,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  'Exam performance is stored with the subject and can influence adaptive topic prioritization. Missing marks are treated as unavailable results, not zero.',
                  style: TextStyle(
                    color: Color(0xFF9AAABD),
                    fontSize: 10,
                    height: 1.5,
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

class _MarksDialog extends StatefulWidget {
  final String subjectName;
  final TextEditingController assess1;
  final TextEditingController assess2;
  final TextEditingController endSem;

  const _MarksDialog({
    required this.subjectName,
    required this.assess1,
    required this.assess2,
    required this.endSem,
  });

  @override
  State<_MarksDialog> createState() =>
      _MarksDialogState();
}

class _MarksDialogState
    extends State<_MarksDialog> {
  String? error;

  double? _parse(
    String text,
  ) {
    if (text.trim().isEmpty) {
      return null;
    }

    final value =
        double.tryParse(text.trim());

    if (value == null ||
        value < 0 ||
        value > 100) {
      return null;
    }

    return value;
  }

  void _save() {
    final a1 = _parse(
      widget.assess1.text,
    );
    final a2 = _parse(
      widget.assess2.text,
    );
    final end = _parse(
      widget.endSem.text,
    );

    final invalidA1 =
        widget.assess1.text.trim().isNotEmpty &&
            a1 == null;

    final invalidA2 =
        widget.assess2.text.trim().isNotEmpty &&
            a2 == null;

    final invalidEnd =
        widget.endSem.text.trim().isNotEmpty &&
            end == null;

    if (invalidA1 ||
        invalidA2 ||
        invalidEnd) {
      setState(() {
        error =
            'Each entered mark must be between 0 and 100.';
      });
      return;
    }

    Navigator.of(context).pop({
      'assess1': a1,
      'assess2': a2,
      'endSem': end,
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor:
          const Color(0xFF091322),
      shape: RoundedRectangleBorder(
        borderRadius:
            BorderRadius.circular(24),
        side: BorderSide(
          color: JarvisColors.cyan
              .withValues(alpha: 0.25),
        ),
      ),
      title: const Row(
        children: [
          Icon(
            Icons.analytics_rounded,
            color: Color(0xFF00E5FF),
          ),
          SizedBox(width: 10),
          Text(
            'EXAM MARKS',
            style: TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w900,
              letterSpacing: 1,
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              widget.subjectName,
              style: const TextStyle(
                color: Color(0xFF00E5FF),
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 18),
            _field(
              widget.assess1,
              'ASSESS 1',
              Icons.looks_one_rounded,
            ),
            const SizedBox(height: 12),
            _field(
              widget.assess2,
              'ASSESS 2',
              Icons.looks_two_rounded,
            ),
            const SizedBox(height: 12),
            _field(
              widget.endSem,
              'END SEM',
              Icons.school_rounded,
            ),
            const SizedBox(height: 10),
            const Text(
              'Leave a field empty if the result is not available.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xFF6C8199),
                fontSize: 9,
                height: 1.4,
              ),
            ),
            if (error != null) ...[
              const SizedBox(height: 10),
              Text(
                error!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Color(0xFFFF667A),
                  fontSize: 10,
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () =>
              Navigator.of(context).pop(),
          child: const Text('CANCEL'),
        ),
        FilledButton(
          onPressed: _save,
          style: FilledButton.styleFrom(
            backgroundColor:
                const Color(0xFF155E75),
          ),
          child: const Text('SAVE'),
        ),
      ],
    );
  }

  Widget _field(
    TextEditingController controller,
    String label,
    IconData icon,
  ) {
    return TextField(
      controller: controller,
      keyboardType:
          const TextInputType.numberWithOptions(
        decimal: true,
      ),
      style: const TextStyle(
        color: Colors.white,
        fontSize: 13,
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(
          color: Color(0xFF72869E),
          fontSize: 10,
        ),
        prefixIcon: Icon(
          icon,
          color: Color(0xFF00E5FF),
          size: 19,
        ),
        suffixText: '/ 100',
        suffixStyle: const TextStyle(
          color: Color(0xFF647991),
          fontSize: 9,
        ),
        filled: true,
        fillColor:
            const Color(0xFF101D30),
        border: OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        focusedBorder:
            OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(14),
          borderSide:
              const BorderSide(
            color: Color(0xFF00E5FF),
          ),
        ),
      ),
    );
  }
}