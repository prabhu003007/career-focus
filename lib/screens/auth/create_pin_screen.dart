import 'package:flutter/material.dart';

import '../../services/api_service.dart';
import '../../services/token_service.dart';

import '../profile/profile_setup_screen.dart';

class CreatePinScreen
    extends StatefulWidget {
  final String email;
  final String verificationToken;

  const CreatePinScreen({
    super.key,
    required this.email,
    required this.verificationToken,
  });

  @override
  State<CreatePinScreen>
      createState() =>
          _CreatePinScreenState();
}

class _CreatePinScreenState
    extends State<CreatePinScreen> {
  final _pinController =
      TextEditingController();

  final _confirmController =
      TextEditingController();

  final _api =
      ApiService();

  final _tokenService =
      TokenService();

  bool _loading = false;
  bool _hidePin = true;
  bool _hideConfirm = true;

  @override
  void dispose() {
    _pinController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _createPin() async {
    final pin =
        _pinController.text.trim();

    final confirm =
        _confirmController.text.trim();

    if (!RegExp(
      r'^\d{4}$',
    ).hasMatch(pin)) {
      _showError(
        'PIN must contain exactly 4 digits.',
      );
      return;
    }

    if (pin != confirm) {
      _showError(
        'PINs do not match.',
      );
      return;
    }

    setState(() {
      _loading = true;
    });

    try {
      /*
       * Create the PIN.
       */
      await _api.createPin(
        widget.email,
        widget.verificationToken,
        pin,
      );

      /*
       * Existing backend authentication
       * is preserved.
       *
       * Login immediately after PIN
       * creation to obtain the normal JWT.
       */
      final loginResult =
          await _api.login(
        widget.email,
        pin,
      );

      final token =
          loginResult['token']
              ?.toString();

      if (token == null ||
          token.isEmpty) {
        throw Exception(
          'Unable to create authenticated session.',
        );
      }

      await _tokenService
          .saveSession(
        token: token,
        email: widget.email,
      );

      if (!mounted) return;

      /*
       * First-time account → profile setup.
       */
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (_) =>
              const ProfileSetupScreen(),
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
          _loading = false;
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
    return Scaffold(
      appBar: AppBar(
        title:
            const Text('Create PIN'),
      ),
      body: SafeArea(
        child:
            SingleChildScrollView(
          padding:
              const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              const SizedBox(
                height: 30,
              ),

              const Icon(
                Icons.lock_outline_rounded,
                size: 58,
              ),

              const SizedBox(
                height: 24,
              ),

              const Text(
                'Create your PIN',
                style: TextStyle(
                  fontSize: 30,
                  fontWeight:
                      FontWeight.w800,
                ),
              ),

              const SizedBox(
                height: 10,
              ),

              const Text(
                'Create a 4-digit PIN to securely access your Career Focus account.',
                style: TextStyle(
                  fontSize: 15,
                  height: 1.5,
                  color:
                      Colors.white60,
                ),
              ),

              const SizedBox(
                height: 30,
              ),

              Text(
                widget.email,
                style:
                    const TextStyle(
                  fontSize: 14,
                  fontWeight:
                      FontWeight.w700,
                ),
              ),

              const SizedBox(
                height: 25,
              ),

              TextField(
                controller:
                    _pinController,
                keyboardType:
                    TextInputType.number,
                maxLength: 4,
                obscureText:
                    _hidePin,
                decoration:
                    InputDecoration(
                  labelText:
                      '4-digit PIN',
                  prefixIcon:
                      const Icon(
                    Icons
                        .lock_outline_rounded,
                  ),
                  suffixIcon:
                      IconButton(
                    onPressed: () {
                      setState(() {
                        _hidePin =
                            !_hidePin;
                      });
                    },
                    icon: Icon(
                      _hidePin
                          ? Icons
                              .visibility_outlined
                          : Icons
                              .visibility_off_outlined,
                    ),
                  ),
                  border:
                      const OutlineInputBorder(),
                ),
              ),

              const SizedBox(
                height: 8,
              ),

              TextField(
                controller:
                    _confirmController,
                keyboardType:
                    TextInputType.number,
                maxLength: 4,
                obscureText:
                    _hideConfirm,
                decoration:
                    InputDecoration(
                  labelText:
                      'Confirm PIN',
                  prefixIcon:
                      const Icon(
                    Icons
                        .lock_outline_rounded,
                  ),
                  suffixIcon:
                      IconButton(
                    onPressed: () {
                      setState(() {
                        _hideConfirm =
                            !_hideConfirm;
                      });
                    },
                    icon: Icon(
                      _hideConfirm
                          ? Icons
                              .visibility_outlined
                          : Icons
                              .visibility_off_outlined,
                    ),
                  ),
                  border:
                      const OutlineInputBorder(),
                ),
              ),

              const SizedBox(
                height: 20,
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
                          : _createPin,
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
                          'CREATE PIN',
                          style:
                              TextStyle(
                            fontWeight:
                                FontWeight.w800,
                          ),
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