import 'package:flutter/material.dart';

import '../../screens/auth/auth_screen.dart';
import '../../screens/auth/pin_screen.dart';
import '../../screens/dashboard/exam_intelligence_screen.dart';
import '../../screens/dashboard/progress_screen.dart';
import '../../screens/dashboard/schedule_screen.dart';
import '../../screens/home/home_screen.dart';
import '../../screens/profile/profile_screen.dart';
import '../../screens/settings/settings_screen.dart';
import '../../screens/splash/splash_screen.dart';

class AppRoutes {
  AppRoutes._();

  static const String splash = '/';
  static const String auth = '/auth';
  static const String pin = '/pin';
  static const String home = '/home';
  static const String profile = '/profile';
  static const String settings = '/settings';

  static const String copilot = '/copilot';
  static const String schedule = '/schedule';
  static const String progress = '/progress';
  static const String exams = '/exams';

  static Route<dynamic> onGenerateRoute(
    RouteSettings settings,
  ) {
    switch (settings.name) {
      case splash:
        return _page(
          const SplashScreen(),
          settings,
        );

      case auth:
        return _page(
          const AuthScreen(),
          settings,
        );

      case pin:
        return _page(
          const PinScreen(),
          settings,
        );

      case home:
        return _page(
          const HomeScreen(),
          settings,
        );

      case profile:
        return _page(
          const ProfileScreen(),
          settings,
        );

      case AppRoutes.settings:
        return _page(
          const SettingsScreen(),
          settings,
        );

      case schedule:
        return _page(
          const ScheduleScreen(),
          settings,
        );

      case progress:
        return _page(
          const ProgressScreen(),
          settings,
        );

      case exams:
        return _page(
          const ExamIntelligenceScreen(),
          settings,
        );

      default:
        return _page(
          const SplashScreen(),
          settings,
        );
    }
  }

  static MaterialPageRoute<dynamic> _page(
    Widget page,
    RouteSettings settings,
  ) {
    return MaterialPageRoute(
      settings: settings,
      builder: (_) => page,
    );
  }
}