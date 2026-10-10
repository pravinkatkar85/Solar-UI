import 'package:flutter/material.dart';
import 'package:solar_ui/app/solar_app.dart';
import 'package:solar_ui/app/theme_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final themeController = ThemeController(SharedPreferencesThemeStore());
  await themeController.load();

  runApp(SolarApp(themeController: themeController));
}
