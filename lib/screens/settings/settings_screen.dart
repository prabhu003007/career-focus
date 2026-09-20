import 'package:flutter/material.dart';

import '../../core/theme/jarvis_colors.dart';
import '../../widgets/glass_panel.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({
    super.key,
  });

  @override
  State<SettingsScreen> createState() =>
      _SettingsScreenState();
}

class _SettingsScreenState
    extends State<SettingsScreen> {
  bool _notifications = true;
  bool _dailyReminder = true;
  bool _adaptiveScheduling = true;
  bool _aiInsights = true;

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
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              _header(),
              const SizedBox(height: 22),
              _notificationSection(),
              const SizedBox(height: 15),
              _intelligenceSection(),
              const SizedBox(height: 15),
              _studySection(),
              const SizedBox(height: 15),
              _aboutSection(),
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
                'SETTINGS',
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
                'CAREER FOCUS CONTROL SYSTEM',
                style: TextStyle(
                  color: Color(0xFF60758F),
                  fontSize: 8,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _notificationSection() {
    return _section(
      title: 'NOTIFICATIONS',
      icon:
          Icons.notifications_active_outlined,
      children: [
        _switchTile(
          title: 'Notifications',
          subtitle:
              'Allow study reminders',
          value: _notifications,
          onChanged: (value) {
            setState(() {
              _notifications = value;

              if (!value) {
                _dailyReminder = false;
              }
            });
          },
        ),
        _switchTile(
          title: 'Daily study reminder',
          subtitle:
              'Date-based study notification',
          value:
              _notifications &&
                  _dailyReminder,
          onChanged: _notifications
              ? (value) {
                  setState(() {
                    _dailyReminder = value;
                  });
                }
              : null,
        ),
      ],
    );
  }

  Widget _intelligenceSection() {
    return _section(
      title: 'AI INTELLIGENCE',
      icon:
          Icons.auto_awesome_rounded,
      children: [
        _switchTile(
          title: 'Adaptive scheduling',
          subtitle:
              'Use academic performance and progress for planning',
          value: _adaptiveScheduling,
          onChanged: (value) {
            setState(() {
              _adaptiveScheduling =
                  value;
            });
          },
        ),
        _switchTile(
          title: 'AI insights',
          subtitle:
              'Show academic planning explanations',
          value: _aiInsights,
          onChanged: (value) {
            setState(() {
              _aiInsights = value;
            });
          },
        ),
      ],
    );
  }

  Widget _studySection() {
    return _section(
      title: 'STUDY SYSTEM',
      icon:
          Icons.menu_book_outlined,
      children: [
        _infoTile(
          title: 'Planning model',
          value:
              'Date-based adaptive planning',
        ),
        _infoTile(
          title: 'Performance input',
          value:
              'Topics + available exam marks',
        ),
        _infoTile(
          title: 'Exam types',
          value:
              'Assess 1 • Assess 2 • End Sem',
        ),
        _infoTile(
          title: 'Gamification',
          value:
              'Disabled — progress visuals only',
        ),
      ],
    );
  }

  Widget _aboutSection() {
    return _section(
      title: 'APPLICATION',
      icon: Icons.info_outline_rounded,
      children: [
        _infoTile(
          title: 'Application',
          value: 'Career Focus',
        ),
        _infoTile(
          title: 'Purpose',
          value:
              'Study planning and academic improvement',
        ),
        _infoTile(
          title: 'Version',
          value: '1.0.0',
        ),
      ],
    );
  }

  Widget _section({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return GlassPanel(
      radius: 21,
      padding: const EdgeInsets.fromLTRB(
        8,
        10,
        8,
        10,
      ),
      borderColor:
          const Color(0xFF263C57),
      child: Column(
        children: [
          Padding(
            padding:
                const EdgeInsets.symmetric(
              horizontal: 10,
              vertical: 8,
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  color:
                      const Color(0xFF00E5FF),
                  size: 18,
                ),
                const SizedBox(width: 9),
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight:
                        FontWeight.w900,
                    letterSpacing: 1.1,
                  ),
                ),
              ],
            ),
          ),
          ...children,
        ],
      ),
    );
  }

  Widget _switchTile({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool>?
        onChanged,
  }) {
    return ListTile(
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
          fontSize: 8,
          height: 1.4,
        ),
      ),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeThumbColor:
            const Color(0xFF00E5FF),
        activeTrackColor:
            const Color(0xFF075985),
      ),
    );
  }

  Widget _infoTile({
    required String title,
    required String value,
  }) {
    return ListTile(
      title: Text(
        title,
        style: const TextStyle(
          color: Color(0xFF8296AC),
          fontSize: 10,
        ),
      ),
      trailing: ConstrainedBox(
        constraints:
            const BoxConstraints(
          maxWidth: 190,
        ),
        child: Text(
          value,
          textAlign: TextAlign.right,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 9,
            fontWeight:
                FontWeight.w700,
          ),
        ),
      ),
    );
  }
}