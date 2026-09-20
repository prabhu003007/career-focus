import 'package:flutter/material.dart';

import '../../services/api_service.dart';
import '../../services/token_service.dart';
import '../home/home_screen.dart';
import 'forgot_pin_screen.dart';

class PinScreen extends StatefulWidget {
  final String? email;

  const PinScreen({
    super.key,
    this.email,
  });

  @override
  State<PinScreen> createState() => _PinScreenState();
}

class _PinScreenState extends State<PinScreen> {
  final TextEditingController _emailController =
      TextEditingController();

  final TextEditingController _pinController =
      TextEditingController();

  final ApiService _apiService = ApiService();
  final TokenService _tokenService = TokenService();

  bool _loading = false;
  String? _pinError;

  bool get _returningUser => widget.email != null;

  @override
  void initState() {
    super.initState();

    if (widget.email != null) {
      _emailController.text = widget.email!;
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _pinController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    final email = _emailController.text.trim().toLowerCase();
    final pin = _pinController.text.trim();

    setState(() {
      _pinError = null;
    });

    if (email.isEmpty || !email.contains('@')) {
      setState(() {
        _pinError = 'Enter a valid email address';
      });
      return;
    }

    if (pin.length != 4) {
      setState(() {
        _pinError = 'Enter your 4-digit PIN';
      });
      return;
    }

    setState(() {
      _loading = true;
    });

    try {
      final result = await _apiService.login(
        email,
        pin,
      );

      if (!mounted) return;

      if (result['success'] == true &&
          result['token'] != null) {
        await _tokenService.saveSession(
          token: result['token'].toString(),
          email: email,
        );

        if (!mounted) return;

        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (_) => const HomeScreen(),
          ),
          (route) => false,
        );
      }
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _pinError = error
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

  Future<void> _useAnotherAccount() async {
    await _tokenService.clearSession();

    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => const PinScreen(),
      ),
    );
  }

  void _openForgotPin() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const ForgotPinScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
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
                    Icons.lock_rounded,
                    size: 58,
                  ),

                  const SizedBox(height: 28),

                  Text(
                    _returningUser
                        ? 'Welcome back'
                        : 'Sign in',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.headlineMedium
                        ?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 10),

                  Text(
                    _returningUser
                        ? 'Enter your PIN to continue'
                        : 'Sign in to continue your studies',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyLarge
                        ?.copyWith(
                      color: Colors.white60,
                    ),
                  ),

                  const SizedBox(height: 42),

                  if (_returningUser) ...[
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        borderRadius:
                            BorderRadius.circular(16),
                        color: theme.colorScheme.surface
                            .withValues(alpha: 0.6),
                        border: Border.all(
                          color: theme.colorScheme.outline
                              .withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.account_circle_outlined,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              widget.email!,
                              overflow:
                                  TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 18),
                  ] else ...[
                    TextField(
                      controller: _emailController,
                      keyboardType:
                          TextInputType.emailAddress,
                      autocorrect: false,
                      decoration: InputDecoration(
                        labelText: 'Email address',
                        hintText: 'you@example.com',
                        prefixIcon: const Icon(
                          Icons.email_outlined,
                        ),
                        border: OutlineInputBorder(
                          borderRadius:
                              BorderRadius.circular(16),
                        ),
                      ),
                    ),

                    const SizedBox(height: 18),
                  ],

                  TextField(
                    controller: _pinController,
                    keyboardType: TextInputType.number,
                    obscureText: true,
                    maxLength: 4,
                    onChanged: (_) {
                      if (_pinError != null) {
                        setState(() {
                          _pinError = null;
                        });
                      }
                    },
                    decoration: InputDecoration(
                      labelText: '4-digit PIN',
                      prefixIcon: const Icon(
                        Icons.pin_outlined,
                      ),
                      errorText: _pinError,
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
                          _loading ? null : _login,
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
                              'Continue',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  TextButton(
                    onPressed:
                        _loading ? null : _openForgotPin,
                    child: const Text(
                      'Forgot PIN?',
                    ),
                  ),

                  if (_returningUser)
                    TextButton(
                      onPressed: _loading
                          ? null
                          : _useAnotherAccount,
                      child: const Text(
                        'Use another account',
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