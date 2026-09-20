import 'package:flutter/material.dart';

import '../../services/api_service.dart';
import 'create_pin_screen.dart';

class VerificationScreen
    extends StatefulWidget {
  final String email;

  const VerificationScreen({
    super.key,
    required this.email,
  });

  @override
  State<VerificationScreen>
      createState() =>
          _VerificationScreenState();
}

class _VerificationScreenState
    extends State<VerificationScreen> {
  final TextEditingController
      _codeController =
      TextEditingController();

  final ApiService _apiService =
      ApiService();

  bool _loading = false;
  bool _resending = false;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _verifyCode() async {
    if (_loading) return;

    final code =
        _codeController.text.trim();

    if (!RegExp(
      r'^\d{6}$',
    ).hasMatch(code)) {
      _showError(
        'Enter the 6-digit verification code.',
      );
      return;
    }

    setState(() {
      _loading = true;
    });

    try {
      final result =
          await _apiService.verifyEmail(
        widget.email,
        code,
      );

      final verificationToken =
          result['verificationToken']
              ?.toString();

      if (verificationToken ==
              null ||
          verificationToken.isEmpty) {
        throw Exception(
          'Verification succeeded but registration authorization was not received. Please request a new code.',
        );
      }

      if (!mounted) return;

      /*
       * The verification code is now consumed.
       * Move forward only once.
       */
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) =>
              CreatePinScreen(
            email: widget.email,
            verificationToken:
                verificationToken,
          ),
        ),
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
          _loading = false;
        });
      }
    }
  }

  Future<void> _resendCode() async {
    if (_resending) return;

    setState(() {
      _resending = true;
    });

    try {
      await _apiService
          .sendVerification(
        widget.email,
      );

      _codeController.clear();

      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            'A new verification code has been generated.',
          ),
        ),
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
          _resending = false;
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
        content: Text(message),
      ),
    );
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    final theme =
        Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title:
            const Text('Verify Email'),
      ),
      body: SafeArea(
        child:
            SingleChildScrollView(
          padding:
              const EdgeInsets.all(
            24,
          ),
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment
                    .start,
            children: [
              const SizedBox(
                height: 30,
              ),

              Container(
                width: 64,
                height: 64,
                decoration:
                    BoxDecoration(
                  borderRadius:
                      BorderRadius.circular(
                    20,
                  ),
                  color: theme
                      .colorScheme
                      .primary
                      .withValues(
                    alpha: 0.12,
                  ),
                ),
                child: Icon(
                  Icons
                      .mark_email_read_outlined,
                  size: 32,
                  color: theme
                      .colorScheme
                      .primary,
                ),
              ),

              const SizedBox(
                height: 24,
              ),

              const Text(
                'Verify your email',
                style: TextStyle(
                  fontSize: 30,
                  fontWeight:
                      FontWeight.w800,
                ),
              ),

              const SizedBox(
                height: 10,
              ),

              Text(
                'Enter the 6-digit verification code for:',
                style: TextStyle(
                  fontSize: 15,
                  color: theme
                      .colorScheme
                      .onSurface
                      .withValues(
                    alpha: 0.65,
                  ),
                ),
              ),

              const SizedBox(
                height: 8,
              ),

              Text(
                widget.email,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight:
                      FontWeight.w700,
                  color: theme
                      .colorScheme
                      .primary,
                ),
              ),

              const SizedBox(
                height: 32,
              ),

              TextField(
                controller:
                    _codeController,
                keyboardType:
                    TextInputType.number,
                maxLength: 6,
                textAlign:
                    TextAlign.center,
                style:
                    const TextStyle(
                  fontSize: 25,
                  fontWeight:
                      FontWeight.w800,
                  letterSpacing: 8,
                ),
                decoration:
                    const InputDecoration(
                  labelText:
                      'Verification Code',
                  counterText: '',
                  border:
                      OutlineInputBorder(),
                ),
              ),

              const SizedBox(
                height: 22,
              ),

              SizedBox(
                width:
                    double.infinity,
                height: 54,
                child:
                    FilledButton(
                  onPressed:
                      _loading
                          ? null
                          : _verifyCode,
                  child: _loading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child:
                              CircularProgressIndicator(
                            strokeWidth:
                                2,
                          ),
                        )
                      : const Text(
                          'VERIFY EMAIL',
                          style:
                              TextStyle(
                            fontWeight:
                                FontWeight
                                    .w700,
                          ),
                        ),
                ),
              ),

              const SizedBox(
                height: 18,
              ),

              Center(
                child:
                    TextButton(
                  onPressed:
                      _resending
                          ? null
                          : _resendCode,
                  child: _resending
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child:
                              CircularProgressIndicator(
                            strokeWidth:
                                2,
                          ),
                        )
                      : const Text(
                          'Resend verification code',
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}