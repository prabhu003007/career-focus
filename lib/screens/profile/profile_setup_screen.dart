import 'package:flutter/material.dart';

import '../../core/theme/jarvis_colors.dart';
import '../../services/profile_service.dart';
import '../../services/token_service.dart';
import '../../widgets/ai_core_orb.dart';
import '../../widgets/glass_panel.dart';
import '../home/home_screen.dart';

class ProfileSetupScreen
    extends StatefulWidget {
  const ProfileSetupScreen({
    super.key,
  });

  @override
  State<ProfileSetupScreen>
      createState() =>
          _ProfileSetupScreenState();
}

class _ProfileSetupScreenState
    extends State<ProfileSetupScreen> {
  final _formKey =
      GlobalKey<FormState>();

  final _name =
      TextEditingController();

  final _college =
      TextEditingController();

  final _degree =
      TextEditingController();

  final _course =
      TextEditingController();

  final _profileService =
      ProfileService();

  final _tokenService =
      TokenService();

  int _year = 1;
  bool _saving = false;

  @override
  void dispose() {
    _name.dispose();
    _college.dispose();
    _degree.dispose();
    _course.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!
        .validate()) {
      return;
    }

    final token =
        await _tokenService
            .getToken();

    if (token == null ||
        token.isEmpty) {
      _showError(
        'Session expired. Please sign in again.',
      );
      return;
    }

    setState(() {
      _saving = true;
    });

    try {
      await _profileService
          .updateProfile(
        token,
        name: _name.text.trim(),
        collegeName:
            _college.text.trim(),
        degree:
            _degree.text.trim(),
        course:
            _course.text.trim(),
        academicYear: _year,
      );

      if (!mounted) return;

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (_) =>
              const HomeScreen(),
        ),
        (_) => false,
      );
    } catch (error) {
      if (!mounted) return;

      _showError(
        error
            .toString()
            .replaceFirst(
              'Exception: ',
              '',
            ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _saving = false;
        });
      }
    }
  }

  void _showError(
    String message,
  ) {
    ScaffoldMessenger.of(context)
        .showSnackBar(
      SnackBar(
        backgroundColor:
            const Color(0xFF7F1D1D),
        content: Text(message),
      ),
    );
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor:
            const Color(0xFF030711),
        body: SafeArea(
          child:
              SingleChildScrollView(
            padding:
                const EdgeInsets.fromLTRB(
              18,
              18,
              18,
              30,
            ),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  const AiCoreOrb(
                    size: 90,
                  ),

                  const SizedBox(
                    height: 15,
                  ),

                  const Text(
                    'INITIALIZE YOUR PROFILE',
                    textAlign:
                        TextAlign.center,
                    style: TextStyle(
                      color:
                          JarvisColors.cyan,
                      fontSize: 11,
                      fontWeight:
                          FontWeight.w900,
                      letterSpacing: 2,
                    ),
                  ),

                  const SizedBox(
                    height: 7,
                  ),

                  const Text(
                    'Tell Career Focus about your academic identity.',
                    textAlign:
                        TextAlign.center,
                    style: TextStyle(
                      color:
                          Color(0xFF7F93AA),
                      fontSize: 10,
                      height: 1.5,
                    ),
                  ),

                  const SizedBox(
                    height: 22,
                  ),

                  GlassPanel(
                    radius: 25,
                    borderColor:
                        JarvisColors.cyan,
                    padding:
                        const EdgeInsets.all(
                      18,
                    ),
                    child: Column(
                      children: [
                        _field(
                          controller: _name,
                          label: 'Name',
                          icon: Icons
                              .person_outline_rounded,
                        ),

                        _field(
                          controller: _college,
                          label:
                              'College Name',
                          icon: Icons
                              .account_balance_outlined,
                        ),

                        _field(
                          controller: _degree,
                          label: 'Degree',
                          icon: Icons
                              .school_outlined,
                        ),

                        _field(
                          controller: _course,
                          label: 'Course',
                          icon: Icons
                              .menu_book_outlined,
                        ),

                        const SizedBox(
                          height: 5,
                        ),

                        DropdownButtonFormField<
                            int>(
                          initialValue:
                              _year,
                          decoration:
                              _decoration(
                            'Academic Year',
                            Icons
                                .calendar_month_outlined,
                          ),
                          dropdownColor:
                              const Color(
                            0xFF0A1728,
                          ),
                          style:
                              const TextStyle(
                            color:
                                Colors.white,
                            fontSize: 12,
                          ),
                          items:
                              const [
                            DropdownMenuItem(
                              value: 1,
                              child: Text(
                                '1st Year',
                              ),
                            ),
                            DropdownMenuItem(
                              value: 2,
                              child: Text(
                                '2nd Year',
                              ),
                            ),
                            DropdownMenuItem(
                              value: 3,
                              child: Text(
                                '3rd Year',
                              ),
                            ),
                            DropdownMenuItem(
                              value: 4,
                              child: Text(
                                '4th Year',
                              ),
                            ),
                          ],
                          onChanged:
                              (value) {
                            if (value ==
                                null) {
                              return;
                            }

                            setState(() {
                              _year =
                                  value;
                            });
                          },
                        ),

                        const SizedBox(
                          height: 22,
                        ),

                        SizedBox(
                          width:
                              double.infinity,
                          height: 54,
                          child:
                              ElevatedButton(
                            onPressed:
                                _saving
                                    ? null
                                    : _save,
                            style:
                                ElevatedButton
                                    .styleFrom(
                              backgroundColor:
                                  JarvisColors
                                      .cyan,
                              foregroundColor:
                                  const Color(
                                0xFF001018,
                              ),
                              shape:
                                  RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.circular(
                                  16,
                                ),
                              ),
                            ),
                            child: _saving
                                ? const SizedBox(
                                    width:
                                        22,
                                    height:
                                        22,
                                    child:
                                        CircularProgressIndicator(
                                      strokeWidth:
                                          2,
                                    ),
                                  )
                                : const Text(
                                    'ENTER CAREER FOCUS',
                                    style:
                                        TextStyle(
                                      fontWeight:
                                          FontWeight.w900,
                                      letterSpacing:
                                          1,
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
        ),
      ),
    );
  }

  Widget _field({
    required TextEditingController
        controller,
    required String label,
    required IconData icon,
  }) {
    return Padding(
      padding:
          const EdgeInsets.only(
        bottom: 13,
      ),
      child: TextFormField(
        controller: controller,
        style:
            const TextStyle(
          color: Colors.white,
          fontSize: 12,
        ),
        validator: (value) {
          if (value == null ||
              value.trim().isEmpty) {
            return '$label is required';
          }

          return null;
        },
        decoration:
            _decoration(
          label,
          icon,
        ),
      ),
    );
  }

  InputDecoration _decoration(
    String label,
    IconData icon,
  ) {
    return InputDecoration(
      labelText: label,
      labelStyle:
          const TextStyle(
        color: Color(0xFF7890A8),
        fontSize: 11,
      ),
      prefixIcon: Icon(
        icon,
        color: JarvisColors.cyan,
        size: 18,
      ),
      filled: true,
      fillColor:
          const Color(0xFF07111F),
      enabledBorder:
          OutlineInputBorder(
        borderRadius:
            BorderRadius.circular(15),
        borderSide: BorderSide(
          color: JarvisColors.cyan
              .withValues(
            alpha: 0.15,
          ),
        ),
      ),
      focusedBorder:
          OutlineInputBorder(
        borderRadius:
            BorderRadius.circular(15),
        borderSide:
            const BorderSide(
          color:
              JarvisColors.cyan,
        ),
      ),
      errorBorder:
          OutlineInputBorder(
        borderRadius:
            BorderRadius.circular(15),
        borderSide:
            const BorderSide(
          color:
              JarvisColors.red,
        ),
      ),
      focusedErrorBorder:
          OutlineInputBorder(
        borderRadius:
            BorderRadius.circular(15),
        borderSide:
            const BorderSide(
          color:
              JarvisColors.red,
        ),
      ),
    );
  }
}