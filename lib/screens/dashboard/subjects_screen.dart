import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/jarvis_colors.dart';
import '../../models/subject.dart';
import '../../services/api_service.dart';
import '../../services/token_service.dart';
import 'subject_details_screen.dart';

class SubjectsScreen extends StatefulWidget {
  const SubjectsScreen({super.key});

  @override
  State<SubjectsScreen> createState() => _SubjectsScreenState();
}

class _SubjectsScreenState extends State<SubjectsScreen>
    with TickerProviderStateMixin {
  final ApiService _api = ApiService();
  final TokenService _tokenService = TokenService();

  late final AnimationController _coreController;
  late final AnimationController _rotationController;
  late final AnimationController _pulseController;
  late final AnimationController _scanController;

  List<Subject> _subjects = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();

    _coreController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 14),
    )..repeat();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1700),
    )..repeat(reverse: true);

    _scanController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    )..repeat();

    _loadSubjects();
  }

  @override
  void dispose() {
    _coreController.dispose();
    _rotationController.dispose();
    _pulseController.dispose();
    _scanController.dispose();
    super.dispose();
  }

  // ============================================================
  // LOAD SUBJECTS
  // ============================================================

  Future<void> _loadSubjects() async {
    try {
      final token = await _tokenService.getToken();

      if (token == null || token.isEmpty) {
        throw Exception('Authentication required.');
      }

      final result = await _api.getSubjects(token);

      if (!mounted) return;

      setState(() {
        _subjects = result;
        _loading = false;
        _error = null;
      });

      _coreController.forward(from: 0);
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
  // OPEN SUBJECT
  // ============================================================

  Future<void> _openSubject(Subject subject) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SubjectDetailsScreen(
          subject: subject,
        ),
      ),
    );

    if (!mounted) return;

    await _loadSubjects();
  }

  // ============================================================
  // ADD SUBJECT
  // ============================================================

  Future<void> _addSubject() async {
    final nameController = TextEditingController();
    final codeController = TextEditingController();
    final descriptionController = TextEditingController();

    bool saving = false;
    String? errorText;

    await showDialog<void>(
      context: context,
      barrierDismissible: !saving,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            Future<void> createSubject() async {
              final name = nameController.text.trim();

              if (name.isEmpty) {
                setDialogState(() {
                  errorText = 'SUBJECT NAME REQUIRED';
                });
                return;
              }

              setDialogState(() {
                saving = true;
                errorText = null;
              });

              try {
                final token = await _tokenService.getToken();

                if (token == null || token.isEmpty) {
                  throw Exception(
                    'Authentication required.',
                  );
                }

                final subject = await _api.createSubject(
                  token,
                  name: name,
                  code: codeController.text.trim(),
                  description:
                      descriptionController.text.trim(),
                );

                if (!dialogContext.mounted) return;

                Navigator.pop(dialogContext);

                if (!mounted) return;

                setState(() {
                  _subjects.add(subject);
                });

                _coreController.forward(from: 0);

                _showMessage(
                  'SUBJECT INITIALIZED',
                );
              } catch (e) {
                if (!dialogContext.mounted) return;

                setDialogState(() {
                  saving = false;
                  errorText = e
                      .toString()
                      .replaceFirst(
                        'Exception: ',
                        '',
                      );
                });
              }
            }

            return Dialog(
              backgroundColor: Colors.transparent,
              insetPadding:
                  const EdgeInsets.symmetric(
                horizontal: 22,
              ),
              child: _HudDialog(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 46,
                          height: 46,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color:
                                JarvisColors.cyan
                                    .withValues(
                              alpha: .06,
                            ),
                            border: Border.all(
                              color:
                                  JarvisColors.cyan
                                      .withValues(
                                alpha: .45,
                              ),
                            ),
                          ),
                          child: const Icon(
                            Icons.add,
                            color:
                                JarvisColors.cyan,
                            size: 25,
                          ),
                        ),
                        const SizedBox(width: 13),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment
                                    .start,
                            children: [
                              Text(
                                'ADD SUBJECT',
                                style: TextStyle(
                                  color:
                                      Colors.white,
                                  fontSize: 17,
                                  fontWeight:
                                      FontWeight.w900,
                                  letterSpacing:
                                      1.6,
                                ),
                              ),
                              SizedBox(height: 5),
                              Text(
                                'ACADEMIC NODE INITIALIZATION',
                                style: TextStyle(
                                  color:
                                      JarvisColors
                                          .cyan,
                                  fontSize: 9,
                                  fontWeight:
                                      FontWeight.w700,
                                  letterSpacing:
                                      1.3,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 23),

                    _HudInput(
                      controller: nameController,
                      label: 'SUBJECT NAME',
                      icon:
                          Icons.menu_book_rounded,
                      enabled: !saving,
                    ),

                    const SizedBox(height: 12),

                    _HudInput(
                      controller: codeController,
                      label: 'SUBJECT CODE',
                      icon: Icons.tag,
                      enabled: !saving,
                    ),

                    const SizedBox(height: 12),

                    _HudInput(
                      controller:
                          descriptionController,
                      label: 'DESCRIPTION',
                      icon:
                          Icons.description_outlined,
                      enabled: !saving,
                      maxLines: 3,
                    ),

                    if (errorText != null) ...[
                      const SizedBox(height: 11),
                      Text(
                        errorText!,
                        style: const TextStyle(
                          color:
                              JarvisColors.red,
                          fontSize: 10,
                          fontWeight:
                              FontWeight.w800,
                        ),
                      ),
                    ],

                    const SizedBox(height: 21),

                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: saving
                                ? null
                                : () {
                                    Navigator.pop(
                                      dialogContext,
                                    );
                                  },
                            style:
                                OutlinedButton.styleFrom(
                              minimumSize:
                                  const Size(
                                0,
                                52,
                              ),
                              side: BorderSide(
                                color:
                                    JarvisColors
                                        .cyan
                                        .withValues(
                                  alpha: .25,
                                ),
                              ),
                            ),
                            child: const Text(
                              'CANCEL',
                              style: TextStyle(
                                fontSize: 10,
                                letterSpacing:
                                    1.2,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 11),
                        Expanded(
                          flex: 2,
                          child: ElevatedButton(
                            onPressed: saving
                                ? null
                                : createSubject,
                            style:
                                ElevatedButton.styleFrom(
                              minimumSize:
                                  const Size(
                                0,
                                52,
                              ),
                              backgroundColor:
                                  JarvisColors
                                      .cyan,
                              foregroundColor:
                                  const Color(
                                0xFF001018,
                              ),
                            ),
                            child: saving
                                ? const SizedBox(
                                    width: 19,
                                    height: 19,
                                    child:
                                        CircularProgressIndicator(
                                      strokeWidth:
                                          2,
                                    ),
                                  )
                                : const Text(
                                    'INITIALIZE',
                                    style:
                                        TextStyle(
                                      fontSize:
                                          10,
                                      fontWeight:
                                          FontWeight
                                              .w900,
                                      letterSpacing:
                                          1.3,
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
          },
        );
      },
    );

    nameController.dispose();
    codeController.dispose();
    descriptionController.dispose();
  }

  // ============================================================
  // DELETE SUBJECT
  // ============================================================

  Future<void> _deleteSubject(
    Subject subject,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: _HudDialog(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                const Text(
                  'REMOVE SUBJECT?',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight:
                        FontWeight.w900,
                    letterSpacing: 1.4,
                  ),
                ),
                const SizedBox(height: 15),
                Text(
                  'Remove "${subject.name}" and its academic data?',
                  style: const TextStyle(
                    color: Color(0xFF879AAA),
                    fontSize: 12,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 21),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          Navigator.pop(
                            dialogContext,
                            false,
                          );
                        },
                        child: const Text(
                          'CANCEL',
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(
                            dialogContext,
                            true,
                          );
                        },
                        style:
                            ElevatedButton.styleFrom(
                          backgroundColor:
                              JarvisColors.red,
                        ),
                        child: const Text(
                          'REMOVE',
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );

    if (confirmed != true) return;

    try {
      final token =
          await _tokenService.getToken();

      if (token == null || token.isEmpty) {
        throw Exception(
          'Authentication required.',
        );
      }

      await _api.deleteSubject(
        token,
        subject.id,
      );

      if (!mounted) return;

      setState(() {
        _subjects.removeWhere(
          (item) => item.id == subject.id,
        );
      });

      _showMessage('SUBJECT REMOVED');
    } catch (e) {
      if (!mounted) return;

      _showMessage(
        e.toString().replaceFirst(
              'Exception: ',
              '',
            ),
        error: true,
      );
    }
  }

  // ============================================================
  // MESSAGE
  // ============================================================

  void _showMessage(
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
            ? const Color(0xFF5B1722)
            : const Color(0xFF06253A),
        shape: RoundedRectangleBorder(
          borderRadius:
              BorderRadius.circular(12),
        ),
        content: Text(
          message,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: .7,
          ),
        ),
      ),
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<
        SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Color(0xFF01060D),
        statusBarIconBrightness:
            Brightness.light,
        systemNavigationBarColor:
            Colors.black,
        systemNavigationBarIconBrightness:
            Brightness.light,
      ),
      child: Scaffold(
        backgroundColor:
            const Color(0xFF01060D),
        body: LayoutBuilder(
          builder: (
            context,
            constraints,
          ) {
            final width =
                constraints.maxWidth;

            return Stack(
              children: [
                // BACKGROUND
                Positioned.fill(
                  child: IgnorePointer(
                    child:
                        AnimatedBuilder(
                      animation:
                          Listenable.merge([
                        _rotationController,
                        _scanController,
                      ]),
                      builder: (
                        context,
                        child,
                      ) {
                        return CustomPaint(
                          painter:
                              _PageBackgroundPainter(
                            rotation:
                                _rotationController
                                    .value,
                            scan:
                                _scanController
                                    .value,
                          ),
                        );
                      },
                    ),
                  ),
                ),

                SafeArea(
                  bottom: false,
                  child:
                      RefreshIndicator(
                    color:
                        JarvisColors.cyan,
                    backgroundColor:
                        const Color(
                      0xFF03111D,
                    ),
                    onRefresh:
                        _loadSubjects,
                    child:
                        CustomScrollView(
                      physics:
                          const BouncingScrollPhysics(
                        parent:
                            AlwaysScrollableScrollPhysics(),
                      ),
                      slivers: [
                        SliverToBoxAdapter(
                          child:
                              _buildHeader(
                            width,
                          ),
                        ),

                        SliverToBoxAdapter(
                          child:
                              _buildHero(
                            width,
                          ),
                        ),

                        if (_loading)
                          const SliverFillRemaining(
                            hasScrollBody:
                                false,
                            child: Center(
                              child:
                                  CircularProgressIndicator(
                                color:
                                    JarvisColors
                                        .cyan,
                              ),
                            ),
                          )
                        else if (_error != null)
                          SliverFillRemaining(
                            hasScrollBody:
                                false,
                            child:
                                _buildError(),
                          )
                        else
                          SliverPadding(
                            padding:
                                EdgeInsets.symmetric(
                              horizontal:
                                  width *
                                      .022,
                            ),
                            sliver:
                                SliverList(
                              delegate:
                                  SliverChildBuilderDelegate(
                                (
                                  context,
                                  index,
                                ) {
                                  return _buildSubjectCard(
                                    width,
                                    _subjects[
                                        index],
                                    index,
                                  );
                                },
                                childCount:
                                    _subjects
                                        .length,
                              ),
                            ),
                          ),

                        SliverToBoxAdapter(
                          child:
                              _buildBottomSection(
                            width,
                          ),
                        ),

                        const SliverToBoxAdapter(
                          child: SizedBox(
                            height: 35,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  // ============================================================
  // HEADER
  // ============================================================

Widget _buildHeader(
  double width,
) {
  return Padding(
    padding: EdgeInsets.fromLTRB(
      width * .04,
      width * .025,
      width * .035,
      0,
    ),
    child: SizedBox(
      height: width * .235,
      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          // ======================================================
          // HEADER CONTENT
          // ======================================================

          Expanded(
            child: Padding(
              padding: EdgeInsets.only(
                top: width * .012,
              ),
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Text(
                    'C A R E E R   F O C U S',
                    maxLines: 1,
                    style: TextStyle(
                      color: JarvisColors.cyan,
                      fontSize: width * .029,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.8,
                    ),
                  ),

                  SizedBox(
                    height: width * .018,
                  ),

                  Text(
                    'SUBJECT',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: width * .072,
                      fontWeight: FontWeight.w400,
                      height: .95,
                    ),
                  ),

                  SizedBox(
                    height: width * .018,
                  ),

                  Text(
                    'A C A D E M I C   K N O W L E D G E   C O N T R O L',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: JarvisColors.cyan,
                      fontSize: width * .020,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.3,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    ),
  );
}
  // ============================================================
  // HERO
  // ============================================================

  Widget _buildHero(
    double width,
  ) {
    return SizedBox(
      height: width * .42,
      child: Stack(
        children: [
          Positioned.fill(
            child: AnimatedBuilder(
              animation:
                  Listenable.merge([
                _rotationController,
                _pulseController,
              ]),
              builder: (
                context,
                child,
              ) {
                return CustomPaint(
                  painter:
                      _GlobePainter(
                    rotation:
                        _rotationController
                            .value,
                    pulse:
                        _pulseController
                            .value,
                  ),
                );
              },
            ),
          ),

          // CENTRAL SUBJECT COUNT
          Center(
            child: Container(
              width: width * .48,
              height: width * .14,
              decoration:
                  BoxDecoration(
                color:
                    const Color(
                  0xFF061521,
                ).withValues(
                  alpha: .90,
                ),
                border: Border.all(
                  color:
                      JarvisColors
                          .cyan
                          .withValues(
                    alpha: .55,
                  ),
                  width: 1.2,
                ),
                boxShadow: [
                  BoxShadow(
                    color:
                        JarvisColors
                            .cyan
                            .withValues(
                      alpha: .08,
                    ),
                    blurRadius: 20,
                  ),
                ],
              ),
              child: Column(
                mainAxisAlignment:
                    MainAxisAlignment
                        .center,
                children: [
                  Text(
                    '${_subjects.length} SUBJECTS',
                    style: TextStyle(
                      color:
                          Colors.white,
                      fontSize:
                          width * .035,
                      fontWeight:
                          FontWeight.w800,
                      letterSpacing:
                          .6,
                    ),
                  ),
                  SizedBox(
                    height:
                        width * .009,
                  ),
                  Container(
                    width:
                        width * .18,
                    height: 2,
                    decoration:
                        BoxDecoration(
                      color:
                          JarvisColors
                              .cyan,
                      boxShadow: [
                        BoxShadow(
                          color:
                              JarvisColors
                                  .cyan
                                  .withValues(
                            alpha: .7,
                          ),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // SUBJECT CARD
  // ============================================================

  Widget _buildSubjectCard(
    double width,
    Subject subject,
    int index,
  ) {
    final accent = index.isOdd
        ? JarvisColors.purple
        : JarvisColors.cyan;

    return AnimatedBuilder(
      animation: _coreController,
      builder: (
        context,
        child,
      ) {
        final begin =
            (index * .12)
                .clamp(0.0, .55);

        final end =
            (begin + .40)
                .clamp(.4, 1.0);

        final progress =
            Curves.easeOutCubic
                .transform(
          Interval(
            begin,
            end,
          ).transform(
            _coreController
                .value,
          ),
        );

        return Opacity(
          opacity: progress,
          child: Transform.translate(
            offset: Offset(
              0,
              22 * (1 - progress),
            ),
            child: Padding(
              padding:
                  EdgeInsets.only(
                bottom:
                    width * .018,
              ),
              child: GestureDetector(
                onTap: () =>
                    _openSubject(
                  subject,
                ),
                onLongPress: () =>
                    _deleteSubject(
                  subject,
                ),
                child: SizedBox(
                  height:
                      width * .215,
                  child:
                      AnimatedBuilder(
                    animation:
                        Listenable.merge([
                      _rotationController,
                      _scanController,
                    ]),
                    builder: (
                      context,
                      child,
                    ) {
                      return CustomPaint(
                        painter:
                            _SubjectCardPainter(
                          accent:
                              accent,
                          rotation:
                              _rotationController
                                  .value,
                          scan:
                              _scanController
                                  .value,
                        ),
                        child:
                            _buildCardContent(
                          width,
                          subject,
                          index,
                          accent,
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // ============================================================
  // CARD CONTENT
  // ============================================================

  Widget _buildCardContent(
  double width,
  Subject subject,
  int index,
  Color accent,
) {
  return Stack(
    children: [
      // ==========================================================
      // NUMBER RING
      // ==========================================================

      Positioned(
        left: width * .025,
        top: width * .045,
        child: SizedBox(
          width: width * .135,
          height: width * .135,
          child: CustomPaint(
            painter: _NumberCorePainter(
              number: index + 1,
              accent: accent,
              rotation: _rotationController.value,
            ),
          ),
        ),
      ),

      // ==========================================================
      // CENTER SUBJECT INFORMATION
      // ==========================================================

      Positioned(
        left: width * .205,
        right: width * .135,
        top: 0,
        bottom: 0,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // --------------------------------------------------
              // SUBJECT NAME
              // --------------------------------------------------

              Text(
                subject.name.toUpperCase(),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: width * .039,
                  fontWeight: FontWeight.w900,
                  height: 1.08,
                  letterSpacing: .5,
                ),
              ),

              // --------------------------------------------------
              // SUBJECT CODE
              // --------------------------------------------------

              if (subject.code.isNotEmpty) ...[
                SizedBox(
                  height: width * .014,
                ),
                Text(
                  subject.code.toUpperCase(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: accent,
                    fontSize: width * .027,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.4,
                    height: 1.0,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),

      // ==========================================================
      // MAIN NAVIGATION ARROW
      // ==========================================================

      Positioned(
        right: width * .055,
        top: 0,
        bottom: 0,
        child: Center(
          child: Icon(
            Icons.chevron_right_rounded,
            color: accent,
            size: width * .075,
          ),
        ),
      ),
    ],
  );
}
  
// ============================================================
// BOTTOM ADD SUBJECT
// ============================================================

Widget _buildBottomSection(
  double width,
) {
  return SizedBox(
    height: width * .30,
    child: Center(
      child: GestureDetector(
        onTap: _addSubject,
        child: Container(
          width: width * .78,
          height: 62,
          decoration: BoxDecoration(
            color: const Color(0xFF0B1626).withValues(
              alpha: 0.78,
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: JarvisColors.cyan.withValues(
                alpha: 0.28,
              ),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisAlignment:
                MainAxisAlignment.center,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color:
                      JarvisColors.cyan.withValues(
                    alpha: 0.08,
                  ),
                  border: Border.all(
                    color:
                        JarvisColors.cyan.withValues(
                      alpha: 0.25,
                    ),
                  ),
                ),
                child: const Icon(
                  Icons.add_rounded,
                  color: JarvisColors.cyan,
                  size: 21,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'ADD SUBJECT',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),
        ),
      ),
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
            const EdgeInsets.all(30),
        child: Column(
          mainAxisSize:
              MainAxisSize.min,
          children: [
            const Icon(
              Icons.cloud_off_rounded,
              color:
                  JarvisColors.red,
              size: 48,
            ),
            const SizedBox(
              height: 16,
            ),
            Text(
              _error ??
                  'Unable to load subjects.',
              textAlign:
                  TextAlign.center,
              style:
                  const TextStyle(
                color:
                    Colors.white70,
                fontSize: 12,
              ),
            ),
            const SizedBox(
              height: 20,
            ),
            ElevatedButton(
              onPressed:
                  _loadSubjects,
              child:
                  const Text(
                'RECONNECT',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ==================================================================
// PAGE BACKGROUND
// ==================================================================

class _PageBackgroundPainter
    extends CustomPainter {
  final double rotation;
  final double scan;

  _PageBackgroundPainter({
    required this.rotation,
    required this.scan,
  });

  @override
  void paint(
    Canvas canvas,
    Size size,
  ) {
    final grid = Paint()
      ..style =
          PaintingStyle.stroke
      ..strokeWidth = .35
      ..color =
          JarvisColors.cyan
              .withValues(
        alpha: .028,
      );

    const spacing = 32.0;

    for (
      double x = 0;
      x <= size.width;
      x += spacing
    ) {
      canvas.drawLine(
        Offset(x, 0),
        Offset(x, size.height),
        grid,
      );
    }

    for (
      double y = 0;
      y <= size.height;
      y += spacing
    ) {
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        grid,
      );
    }

    final glow = Paint()
      ..shader =
          RadialGradient(
        colors: [
          JarvisColors.cyan
              .withValues(
            alpha: .045,
          ),
          Colors.transparent,
        ],
      ).createShader(
        Rect.fromCircle(
          center: Offset(
            size.width * .5,
            size.height * .18,
          ),
          radius:
              size.width * .65,
        ),
      );

    canvas.drawCircle(
      Offset(
        size.width * .5,
        size.height * .18,
      ),
      size.width * .65,
      glow,
    );

    final scanY =
        size.height *
            (.05 + scan * .90);

    final scanPaint = Paint()
      ..shader =
          LinearGradient(
        colors: [
          Colors.transparent,
          JarvisColors.cyan
              .withValues(
            alpha: .035,
          ),
          Colors.transparent,
        ],
      ).createShader(
        Rect.fromLTWH(
          0,
          scanY,
          size.width,
          2,
        ),
      );

    canvas.drawRect(
      Rect.fromLTWH(
        0,
        scanY,
        size.width,
        2,
      ),
      scanPaint,
    );
  }

  @override
  bool shouldRepaint(
    covariant _PageBackgroundPainter
        oldDelegate,
  ) {
    return true;
  }
}

// ==================================================================
// HOLOGRAPHIC GLOBE
// ==================================================================

class _GlobePainter
    extends CustomPainter {
  final double rotation;
  final double pulse;

  _GlobePainter({
    required this.rotation,
    required this.pulse,
  });

  @override
  void paint(
    Canvas canvas,
    Size size,
  ) {
    final center = Offset(
      size.width * .5,
      size.height * .49,
    );

    final radius =
        size.width * .145;

    final glow = Paint()
      ..shader =
          RadialGradient(
        colors: [
          JarvisColors.cyan
              .withValues(
            alpha: .14,
          ),
          JarvisColors.cyan
              .withValues(
            alpha: .035,
          ),
          Colors.transparent,
        ],
      ).createShader(
        Rect.fromCircle(
          center: center,
          radius:
              radius * 1.65,
        ),
      );

    canvas.drawCircle(
      center,
      radius * 1.65,
      glow,
    );

    // Globe outer ring
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..style =
            PaintingStyle.stroke
        ..strokeWidth = 1
        ..color =
            JarvisColors.cyan
                .withValues(
          alpha: .65,
        ),
    );

    // Latitude lines
    for (
      int i = -3;
      i <= 3;
      i++
    ) {
      final y =
          center.dy +
              i * radius * .23;

      canvas.drawOval(
        Rect.fromCenter(
          center:
              Offset(
            center.dx,
            y,
          ),
          width:
              radius * 1.95,
          height:
              radius * .30,
        ),
        Paint()
          ..style =
              PaintingStyle.stroke
          ..strokeWidth = .45
          ..color =
              JarvisColors.cyan
                  .withValues(
            alpha: .25,
          ),
      );
    }

    // Longitude lines
    for (
      int i = -3;
      i <= 3;
      i++
    ) {
      canvas.drawOval(
        Rect.fromCenter(
          center: center,
          width:
              radius *
                  (.25 +
                      i.abs() *
                          .22),
          height:
              radius * 1.95,
        ),
        Paint()
          ..style =
              PaintingStyle.stroke
          ..strokeWidth = .45
          ..color =
              JarvisColors.cyan
                  .withValues(
            alpha: .25,
          ),
      );
    }

    // Orbit rings
    for (
      int i = 0;
      i < 3;
      i++
    ) {
      final ring = Paint()
        ..style =
            PaintingStyle.stroke
        ..strokeWidth = 1
        ..color =
            (i.isOdd
                    ? JarvisColors
                        .purple
                    : JarvisColors
                        .cyan)
                .withValues(
          alpha: .55,
        );

      final rect =
          Rect.fromCenter(
        center: center,
        width:
            radius * 2.75,
        height:
            radius *
                (.75 +
                    i * .18),
      );

      canvas.drawArc(
        rect,
        rotation *
                math.pi *
                2 +
            i * 1.3,
        math.pi * 1.2,
        false,
        ring,
      );
    }

    // Orbit nodes
    for (
      int i = 0;
      i < 7;
      i++
    ) {
      final angle =
          rotation *
                  math.pi *
                  2 +
              i *
                  math.pi *
                  2 /
                  7;

      final point = Offset(
        center.dx +
            math.cos(angle) *
                radius *
                1.48,
        center.dy +
            math.sin(angle) *
                radius *
                .52,
      );

      canvas.drawCircle(
        point,
        2.4 +
            pulse * 1.2,
        Paint()
          ..color =
              JarvisColors.cyan,
      );
    }

    // Central core
    final core = Paint()
      ..shader =
          const RadialGradient(
        colors: [
          Colors.white,
          JarvisColors.cyan,
          Colors.transparent,
        ],
      ).createShader(
        Rect.fromCircle(
          center: center,
          radius: 25,
        ),
      );

    canvas.drawCircle(
      center,
      18 + pulse * 3,
      core,
    );
  }

  @override
  bool shouldRepaint(
    covariant _GlobePainter
        oldDelegate,
  ) {
    return true;
  }
}

// ==================================================================
// SUBJECT CARD
// ==================================================================

class _SubjectCardPainter extends CustomPainter {
  final Color accent;
  final double rotation;
  final double scan;

  _SubjectCardPainter({
    required this.accent,
    required this.rotation,
    required this.scan,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        1,
        1,
        size.width - 2,
        size.height - 2,
      ),
      const Radius.circular(18),
    );

    // ------------------------------------------------------------
    // CLEAN DARK CARD
    // ------------------------------------------------------------

    canvas.drawRRect(
      rect,
      Paint()
        ..color = const Color(0xFF03111C),
    );

    // ------------------------------------------------------------
    // SIMPLE NEON BORDER
    // ------------------------------------------------------------

    canvas.drawRRect(
      rect,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..color = accent.withValues(
          alpha: .78,
        ),
    );

    // ------------------------------------------------------------
    // SOFT INNER BORDER
    // ------------------------------------------------------------

    final inner = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        7,
        7,
        size.width - 14,
        size.height - 14,
      ),
      const Radius.circular(13),
    );

    canvas.drawRRect(
      inner,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = .45
        ..color = accent.withValues(
          alpha: .15,
        ),
    );

    // ------------------------------------------------------------
    // VERY SUBTLE TOP GLOW
    // ------------------------------------------------------------

    final glowPaint = Paint()
      ..shader = LinearGradient(
        colors: [
          Colors.transparent,
          accent.withValues(alpha: .20),
          Colors.transparent,
        ],
      ).createShader(
        Rect.fromLTWH(
          20,
          0,
          size.width - 40,
          2,
        ),
      );

    canvas.drawRect(
      Rect.fromLTWH(
        20,
        1,
        size.width - 40,
        1.5,
      ),
      glowPaint,
    );

    // ------------------------------------------------------------
    // SIMPLE CENTER DIVIDER
    // ------------------------------------------------------------

    canvas.drawLine(
      Offset(
        size.width * .67,
        15,
      ),
      Offset(
        size.width * .67,
        size.height - 15,
      ),
      Paint()
        ..color = accent.withValues(
          alpha: .08,
        )
        ..strokeWidth = .6,
    );

    // ------------------------------------------------------------
    // VERY SUBTLE SCAN LINE
    // ------------------------------------------------------------

    final scanX =
        15 + scan * (size.width - 30);

    canvas.drawRect(
      Rect.fromLTWH(
        scanX,
        8,
        1,
        size.height - 16,
      ),
      Paint()
        ..color = accent.withValues(
          alpha: .08,
        ),
    );
  }

  @override
  bool shouldRepaint(
    covariant _SubjectCardPainter oldDelegate,
  ) {
    return oldDelegate.accent != accent ||
        oldDelegate.rotation != rotation ||
        oldDelegate.scan != scan;
  }
}

// ==================================================================
// NUMBER CORE
// ==================================================================

class _NumberCorePainter
    extends CustomPainter {
  final int number;
  final Color accent;
  final double rotation;

  _NumberCorePainter({
    required this.number,
    required this.accent,
    required this.rotation,
  });

  @override
  void paint(
    Canvas canvas,
    Size size,
  ) {
    final center = Offset(
      size.width / 2,
      size.height / 2,
    );

    canvas.drawCircle(
      center,
      size.width * .37,
      Paint()
        ..style =
            PaintingStyle.stroke
        ..strokeWidth = 1.2
        ..color =
            accent.withValues(
          alpha: .8,
        ),
    );

    canvas.drawCircle(
      center,
      size.width * .29,
      Paint()
        ..style =
            PaintingStyle.stroke
        ..strokeWidth = .7
        ..color =
            JarvisColors.cyan
                .withValues(
          alpha: .45,
        ),
    );

    final rect =
        Rect.fromCircle(
      center: center,
      radius:
          size.width * .43,
    );

    canvas.drawArc(
      rect,
      rotation *
          math.pi *
          2,
      math.pi * .9,
      false,
      Paint()
        ..style =
            PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = accent,
    );

    final text =
        TextPainter(
      text: TextSpan(
        text: number
            .toString()
            .padLeft(2, '0'),
        style:
            const TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight:
              FontWeight.w500,
        ),
      ),
      textDirection:
          TextDirection.ltr,
    );

    text.layout();

    text.paint(
      canvas,
      Offset(
        center.dx -
            text.width / 2,
        center.dy -
            text.height / 2,
      ),
    );
  }

  @override
  bool shouldRepaint(
    covariant _NumberCorePainter
        oldDelegate,
  ) {
    return true;
  }
}

// ==================================================================
// SUBJECT ICON
// ==================================================================




// ==================================================================
// HUD DIALOG
// ==================================================================

class _HudDialog
    extends StatelessWidget {
  final Widget child;

  const _HudDialog({
    required this.child,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    return Container(
      padding:
          const EdgeInsets.all(
        20,
      ),
      decoration:
          BoxDecoration(
        color:
            const Color(
          0xFF04111D,
        ),
        borderRadius:
            BorderRadius.circular(
          20,
        ),
        border: Border.all(
          color:
              JarvisColors.cyan
                  .withValues(
            alpha: .35,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color:
                JarvisColors.cyan
                    .withValues(
              alpha: .10,
            ),
            blurRadius: 35,
          ),
        ],
      ),
      child: child,
    );
  }
}

// ==================================================================
// HUD INPUT
// ==================================================================

class _HudInput
    extends StatelessWidget {
  final TextEditingController
      controller;
  final String label;
  final IconData icon;
  final bool enabled;
  final int maxLines;

  const _HudInput({
    required this.controller,
    required this.label,
    required this.icon,
    required this.enabled,
    this.maxLines = 1,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    return TextField(
      controller: controller,
      enabled: enabled,
      maxLines: maxLines,
      style:
          const TextStyle(
        color: Colors.white,
        fontSize: 12,
      ),
      decoration:
          InputDecoration(
        labelText: label,
        labelStyle:
            const TextStyle(
          color:
              Color(0xFF71879A),
          fontSize: 9,
          letterSpacing: 1.2,
        ),
        prefixIcon: Icon(
          icon,
          color:
              JarvisColors.cyan,
          size: 19,
        ),
        filled: true,
        fillColor:
            const Color(
          0xFF020A13,
        ),
        enabledBorder:
            OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(
            12,
          ),
          borderSide:
              BorderSide(
            color: Colors.white
                .withValues(
              alpha: .07,
            ),
          ),
        ),
        focusedBorder:
            OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(
            12,
          ),
          borderSide:
              const BorderSide(
            color:
                JarvisColors.cyan,
          ),
        ),
      ),
    );
  }
}