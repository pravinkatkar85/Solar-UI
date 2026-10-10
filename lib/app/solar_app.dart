import 'package:flutter/material.dart';
import 'package:solar_ui/app/theme_controller.dart';
import 'package:solar_ui/core/demo/demo_user.dart';
import 'package:solar_ui/core/theme/app_theme.dart';
import 'package:solar_ui/features/dashboard/presentation/dashboard_shell.dart';
import 'package:solar_ui/features/startup/presentation/splash_screen.dart';

/// Root application configuration.
///
/// Routing can be introduced here once the initial product flow is approved.
class SolarApp extends StatelessWidget {
  const SolarApp({
    required this.themeController,
    this.startupDuration = const Duration(milliseconds: 1900),
    super.key,
  });

  final ThemeController themeController;
  final Duration startupDuration;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: themeController,
      builder: (context, _) {
        return MaterialApp(
          title: 'Solar',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: themeController.themeMode,
          themeAnimationDuration: const Duration(milliseconds: 240),
          home: SplashScreen(
            startupDuration: startupDuration,
            destinationBuilder: (context) => DashboardShell(
              user: DemoUsers.current,
              themeController: themeController,
            ),
          ),
        );
      },
    );
  }
}
