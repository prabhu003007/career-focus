import 'package:flutter/material.dart';

import 'core/routes/app_routes.dart';
import 'core/theme/app_theme.dart';
import 'services/notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await NotificationService.instance.initialize();

  runApp(
    const CareerFocusApp(),
  );
}

class CareerFocusApp extends StatelessWidget {
  const CareerFocusApp({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Career Focus',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,

      initialRoute: AppRoutes.splash,

      onGenerateRoute: AppRoutes.onGenerateRoute,
    );
  }
}