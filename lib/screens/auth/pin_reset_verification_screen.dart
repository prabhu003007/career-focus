import 'package:flutter/material.dart';

import '../../services/api_service.dart';
import 'reset_pin_screen.dart';

class PinResetVerificationScreen extends StatefulWidget {
  final String email;

  const PinResetVerificationScreen({
    super.key,
    required this.email,
  });

  @override
  State<PinResetVerificationScreen> createState() =>
      _PinResetVerificationScreenState();
}

class _PinResetVerificationScreenState
    extends State<PinResetVerificationScreen> {
  final TextEditingController _codeController =
      TextEditingController();

  final ApiService _apiService = ApiService();

  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _verifyCode() async {
    final code = _codeController.text.trim();

    setState(() {
      _error = null;
    });

    if (code.length != 6) {
      setState(() {
        _error = 'Enter the 6-digit verification code';
      });
      return;
    }

    setState(() {
      _loading = true;
    });

    try {
      final result = await _apiService.verifyPinReset(
        widget.email,
        code,
      );

      if (!mounted) return;

      final resetToken = result['resetToken'];

      if (resetToken == null ||
          resetToken.toString().isEmpty) {
        setState(() {
          _error = 'Invalid reset response';
        });
        return;
      }

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => ResetPinScreen(
            resetToken: resetToken.toString(),
            email: widget.email,
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _error = error
            .toString()
            .replaceFirst('Exception: ', '');
      });
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Verify Reset'),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(28),
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: 440,
              ),
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.stretch,
                children: [
                  const Icon(
                    Icons.mark_email_read_outlined,
                    size: 58,
                  ),

                  const SizedBox(height: 28),

                  const Text(
                    'Verify your email',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 10),

                  Text(
                    'Enter the 6-digit code sent to\n${widget.email}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white60,
                    ),
                  ),

                  const SizedBox(height: 36),

                  TextField(
                    controller: _codeController,
                    keyboardType: TextInputType.number,
                    maxLength: 6,
                    decoration: InputDecoration(
                      labelText: 'Verification code',
                      prefixIcon: const Icon(
                        Icons.password_rounded,
                      ),
                      errorText: _error,
                      counterText: '',
                      border: OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(16),
                      ),
                    ),
                  ),

                  const SizedBox(height: 18),

                  SizedBox(
                    height: 54,
                    child: FilledButton(
                      onPressed:
                          _loading ? null : _verifyCode,
                      child: _loading
                          ? const SizedBox(
                              height: 22,
                              width: 22,
                              child:
                                  CircularProgressIndicator(
                                strokeWidth: 2,
                              ),
                            )
                          : const Text(
                              'Verify',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
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
}