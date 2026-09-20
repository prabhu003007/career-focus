import 'package:flutter/material.dart';

import '../../services/api_service.dart';
import '../auth/pin_screen.dart';

class ResetPinScreen extends StatefulWidget {
  final String email;
  final String resetToken;

  const ResetPinScreen({
    super.key,
    required this.email,
    required this.resetToken,
  });

  @override
  State<ResetPinScreen> createState() => _ResetPinScreenState();
}

class _ResetPinScreenState extends State<ResetPinScreen> {
  final _pinController = TextEditingController();
  final _confirmPinController = TextEditingController();

  final ApiService _apiService = ApiService();

  bool _loading = false;
  bool _obscurePin = true;
  bool _obscureConfirmPin = true;

  @override
  void dispose() {
    _pinController.dispose();
    _confirmPinController.dispose();
    super.dispose();
  }

  Future<void> _resetPin() async {
    final pin = _pinController.text.trim();
    final confirmPin = _confirmPinController.text.trim();

    if (pin.length != 4 || !RegExp(r'^\d{4}$').hasMatch(pin)) {
      _showError('PIN must contain exactly 4 digits.');
      return;
    }

    if (pin != confirmPin) {
      _showError('PINs do not match.');
      return;
    }

    setState(() {
      _loading = true;
    });

    try {
      await _apiService.resetPin(
        widget.email,
        widget.resetToken,
        pin,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('PIN reset successfully.'),
        ),
      );

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (_) => PinScreen(
            email: widget.email,
          ),
        ),
        (route) => false,
      );
    } catch (error) {
      if (!mounted) return;

      _showError(
        error.toString().replaceFirst('Exception: ', ''),
      );
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reset PIN'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 30),

              Icon(
                Icons.lock_reset_rounded,
                size: 56,
                color: theme.colorScheme.primary,
              ),

              const SizedBox(height: 24),

              const Text(
                'Create a new PIN',
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.w800,
                ),
              ),

              const SizedBox(height: 10),

              Text(
                'Enter a new 4-digit PIN for your Career Focus account.',
                style: TextStyle(
                  fontSize: 15,
                  height: 1.5,
                  color: theme.colorScheme.onSurface
                      .withValues(alpha: 0.65),
                ),
              ),

              const SizedBox(height: 35),

              TextField(
                controller: _pinController,
                keyboardType: TextInputType.number,
                maxLength: 4,
                obscureText: _obscurePin,
                decoration: InputDecoration(
                  labelText: 'New PIN',
                  prefixIcon:
                      const Icon(Icons.lock_outline_rounded),
                  suffixIcon: IconButton(
                    onPressed: () {
                      setState(() {
                        _obscurePin = !_obscurePin;
                      });
                    },
                    icon: Icon(
                      _obscurePin
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                    ),
                  ),
                  border: const OutlineInputBorder(),
                ),
              ),

              const SizedBox(height: 10),

              TextField(
                controller: _confirmPinController,
                keyboardType: TextInputType.number,
                maxLength: 4,
                obscureText: _obscureConfirmPin,
                decoration: InputDecoration(
                  labelText: 'Confirm New PIN',
                  prefixIcon:
                      const Icon(Icons.lock_outline_rounded),
                  suffixIcon: IconButton(
                    onPressed: () {
                      setState(() {
                        _obscureConfirmPin =
                            !_obscureConfirmPin;
                      });
                    },
                    icon: Icon(
                      _obscureConfirmPin
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                    ),
                  ),
                  border: const OutlineInputBorder(),
                ),
              ),

              const SizedBox(height: 25),

              SizedBox(
                width: double.infinity,
                height: 54,
                child: FilledButton(
                  onPressed: _loading ? null : _resetPin,
                  child: _loading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          'Reset PIN',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
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