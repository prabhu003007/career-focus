import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/constants/app_constants.dart';
import '../../services/token_service.dart';
import '../auth/auth_screen.dart';
import '../auth/pin_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fadeAnimation;
  late final Animation<double> _scaleAnimation;

  final TokenService _tokenService = TokenService();

  bool _opened = false;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    );

    _scaleAnimation = Tween<double>(
      begin: 0.75,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOutBack,
      ),
    );

    _controller.forward();

    _startSplash();
  }

  Future<void> _startSplash() async {
    /*
     * Keep the splash visible long enough for
     * the animation to complete.
     */
    await Future<void>.delayed(
      const Duration(milliseconds: 1600),
    );

    if (!mounted) return;

    await _openNextScreen();
  }

  Future<void> _openNextScreen() async {
    if (!mounted || _opened) return;

    _opened = true;

    String? email;

    try {
      /*
       * Secure storage should never be allowed to
       * keep the application permanently stuck
       * on the splash screen.
       */
      email = await _tokenService
          .getEmail()
          .timeout(
            const Duration(seconds: 3),
          );
    } catch (error) {
      /*
       * If secure storage fails, treat this as
       * a fresh session and continue to login.
       *
       * We intentionally do not expose the native
       * storage exception to the user.
       */
      debugPrint(
        'Splash session check failed: $error',
      );

      email = null;
    }

    if (!mounted) return;

    if (email != null && email.trim().isNotEmpty) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => PinScreen(
            email: email!.trim(),
          ),
        ),
      );
    } else {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => const AuthScreen(),
        ),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    borderRadius:
                        BorderRadius.circular(28),
                    gradient: const LinearGradient(
                      colors: [
                        Color(0xFF6C63FF),
                        Color(0xFF8B80FF),
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(
                          0xFF6C63FF,
                        ).withValues(alpha: 0.30),
                        blurRadius: 30,
                        spreadRadius: 4,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.auto_awesome_rounded,
                    size: 52,
                    color: Colors.white,
                  ),
                ),

                const SizedBox(height: 24),

                Text(
                  AppConstants.appName,
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),

                const SizedBox(height: 8),

                Text(
                  AppConstants.appTagline,
                  style: const TextStyle(
                    fontSize: 15,
                    color: Colors.white60,
                  ),
                ),

                const SizedBox(height: 32),

                const SizedBox(
                  width: 28,
                  height: 28,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Color(0xFF8B5CF6),
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