import 'package:flutter/material.dart';

import '../../core/theme/jarvis_colors.dart';
import '../../services/token_service.dart';
import '../../widgets/ai_core_orb.dart';
import '../../widgets/ai_status_indicator.dart';
import '../../widgets/glass_panel.dart';
import '../settings/settings_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({
    super.key,
  });

  @override
  State<ProfileScreen> createState() =>
      _ProfileScreenState();
}

class _ProfileScreenState
    extends State<ProfileScreen> {
  final TokenService _tokenService =
      TokenService();

  String _email = 'Loading...';

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      final email =
          await _tokenService.getEmail();

      if (!mounted) return;

      setState(() {
        _email = email?.trim().isNotEmpty == true
            ? email!.trim()
            : 'Account email unavailable';
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _email = 'Account email unavailable';
      });
    }
  }

  Future<void> _logout() async {
    final confirmed =
        await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor:
              const Color(0xFF0A1322),
          shape: RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(22),
          ),
          title: const Text(
            'SIGN OUT',
            style: TextStyle(
              color: Colors.white,
              fontWeight:
                  FontWeight.w900,
              letterSpacing: 1,
            ),
          ),
          content: const Text(
            'Your local session will be cleared. You can sign in again at any time.',
            style: TextStyle(
              color: Color(0xFF8EA0B5),
              height: 1.5,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () =>
                  Navigator.pop(
                dialogContext,
                false,
              ),
              child:
                  const Text('CANCEL'),
            ),
            FilledButton(
              onPressed: () =>
                  Navigator.pop(
                dialogContext,
                true,
              ),
              style:
                  FilledButton.styleFrom(
                backgroundColor:
                    const Color(0xFF7F1D1D),
              ),
              child:
                  const Text('SIGN OUT'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    await _tokenService.clearSession();

    if (!mounted) return;

    Navigator.of(context)
        .pushNamedAndRemoveUntil(
      '/',
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          const Color(0xFF030711),
      body: SafeArea(
        child: SingleChildScrollView(
          padding:
              const EdgeInsets.fromLTRB(
            18,
            16,
            18,
            35,
          ),
          child: Column(
            children: [
              _header(),
              const SizedBox(height: 22),
              _identityCard(),
              const SizedBox(height: 15),
              _accountCard(),
              const SizedBox(height: 15),
              _settingsCard(),
              const SizedBox(height: 15),
              _systemCard(),
              const SizedBox(height: 20),
              _logoutButton(),
            ],
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
            decoration: BoxDecoration(
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
                'USER PROFILE',
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
                'CAREER FOCUS IDENTITY CORE',
                style: TextStyle(
                  color: Color(0xFF60758F),
                  fontSize: 8,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
        ),
        const AiStatusIndicator(
          label: 'ONLINE',
        ),
      ],
    );
  }

  Widget _identityCard() {
    return GlassPanel(
      radius: 25,
      borderColor:
          const Color(0xFF8B5CF6),
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          const AiCoreOrb(size: 88),
          const SizedBox(width: 17),
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                const Text(
                  'STUDENT PROFILE',
                  style: TextStyle(
                    color: Color(0xFFB77CFF),
                    fontSize: 9,
                    fontWeight:
                        FontWeight.w900,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 7),
                Text(
                  _email,
                  maxLines: 2,
                  overflow:
                      TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight:
                        FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 5),
                const Text(
                  'AUTHENTICATED ACCOUNT',
                  style: TextStyle(
                    color: Color(0xFF6B819A),
                    fontSize: 8,
                    letterSpacing: 0.8,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _accountCard() {
    return GlassPanel(
      radius: 20,
      padding: const EdgeInsets.all(8),
      child: Column(
        children: [
          _row(
            icon:
                Icons.email_outlined,
            title: 'Email account',
            subtitle: _email,
          ),
          _divider(),
          _row(
            icon:
                Icons.lock_outline_rounded,
            title: 'Authentication',
            subtitle:
                'PIN protected session',
          ),
          _divider(),
          _row(
            icon:
                Icons.verified_user_outlined,
            title: 'Authorization',
            subtitle:
                'Private user data scope',
          ),
        ],
      ),
    );
  }

  Widget _settingsCard() {
    return GlassPanel(
      radius: 20,
      padding: const EdgeInsets.all(8),
      child: _clickRow(
        icon: Icons.settings_outlined,
        title: 'Application settings',
        subtitle:
            'Notifications and study preferences',
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) =>
                  const SettingsScreen(),
            ),
          );
        },
      ),
    );
  }

  Widget _systemCard() {
    return GlassPanel(
      radius: 20,
      padding: const EdgeInsets.all(16),
      borderColor:
          const Color(0xFF263C57),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          const Text(
            'CAREER FOCUS SYSTEM',
            style: TextStyle(
              color: Color(0xFF00E5FF),
              fontSize: 9,
              fontWeight:
                  FontWeight.w900,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 12),
          _systemLine(
            'Study planning',
            'ACTIVE',
          ),
          _systemLine(
            'Adaptive scheduling',
            'ACTIVE',
          ),
          _systemLine(
            'Academic intelligence',
            'ACTIVE',
          ),
          _systemLine(
            'Cloud synchronization',
            'ACTIVE',
          ),
        ],
      ),
    );
  }

  Widget _systemLine(
    String title,
    String status,
  ) {
    return Padding(
      padding:
          const EdgeInsets.symmetric(
        vertical: 5,
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                color:
                    Color(0xFF8799AE),
                fontSize: 10,
              ),
            ),
          ),
          Text(
            status,
            style: const TextStyle(
              color: Color(0xFF39E58C),
              fontSize: 8,
              fontWeight:
                  FontWeight.w900,
              letterSpacing: 0.7,
            ),
          ),
        ],
      ),
    );
  }

  Widget _logoutButton() {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: OutlinedButton.icon(
        onPressed: _logout,
        icon: const Icon(
          Icons.logout_rounded,
          size: 18,
        ),
        label: const Text(
          'SIGN OUT',
          style: TextStyle(
            fontWeight:
                FontWeight.w900,
            letterSpacing: 1,
          ),
        ),
        style: OutlinedButton.styleFrom(
          foregroundColor:
              const Color(0xFFFF667A),
          side: BorderSide(
            color: const Color(0xFFFF667A)
                .withValues(alpha: 0.35),
          ),
          shape:
              RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }

  Widget _row({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          borderRadius:
              BorderRadius.circular(12),
          color: JarvisColors.cyan
              .withValues(alpha: 0.06),
        ),
        child: Icon(
          icon,
          color: JarvisColors.cyan,
          size: 19,
        ),
      ),
      title: Text(
        title,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight:
              FontWeight.w800,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(
          color: Color(0xFF667B93),
          fontSize: 9,
        ),
      ),
    );
  }

  Widget _clickRow({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      onTap: onTap,
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          borderRadius:
              BorderRadius.circular(12),
          color: const Color(0xFF8B5CF6)
              .withValues(alpha: 0.08),
        ),
        child: Icon(
          icon,
          color: const Color(0xFFB77CFF),
          size: 19,
        ),
      ),
      title: Text(
        title,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight:
              FontWeight.w800,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(
          color: Color(0xFF667B93),
          fontSize: 9,
        ),
      ),
      trailing: const Icon(
        Icons.chevron_right_rounded,
        color: Color(0xFF52677F),
      ),
    );
  }

  Widget _divider() {
    return Divider(
      height: 1,
      color: Colors.white
          .withValues(alpha: 0.04),
    );
  }
}