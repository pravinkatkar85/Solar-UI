import 'package:flutter/material.dart';

/// Central color palette for the Solar visual language.
///
/// Deployment branding can replace these defaults later without spreading
/// color literals throughout feature code.
abstract final class AppColors {
  static const solarOrange = Color(0xFFF2994A);
  static const solarOrangeDark = Color(0xFFC96B20);
  static const solarOrangeSoft = Color(0xFFFFF1E4);
  static const solarOrangeDarkTheme = Color(0xFFFFA85C);

  static const deepNavy = Color(0xFF1E293B);
  static const navySoft = Color(0xFFE8EEF4);

  /// Sampled from the official wordmark background. Keep logo plates on this
  /// exact color so the JPEG edges blend.
  static const brandBlue = Color(0xFF273B92);

  static const energyLime = Color(0xFF6E9B38);
  static const energyLimeSoft = Color(0xFFEAF4DC);
  static const energyLimeDark = Color(0xFFC6E38A);

  static const canvas = Color(0xFFF6F3EE);
  static const surface = Color(0xFFFFFCF8);
  static const surfaceMuted = Color(0xFFF0EBE4);
  static const border = Color(0xFFE6DFD6);

  static const textPrimary = Color(0xFF1C1917);
  static const textSecondary = Color(0xFF6B635C);
  static const textOnDark = Color(0xFFFFFFFF);

  static const darkCanvas = Color(0xFF12151C);
  static const darkSurface = Color(0xFF1C2230);
  static const darkSurfaceMuted = Color(0xFF262E3D);
  static const darkBorder = Color(0xFF3A4456);
  static const darkTextPrimary = Color(0xFFF7F4EF);
  static const darkTextSecondary = Color(0xFFC4BDB4);

  static const error = Color(0xFFB42318);
  static const errorSoft = Color(0xFFFDECEC);
  static const darkError = Color(0xFFFFB4AB);
  static const darkErrorContainer = Color(0xFF6E1E1A);
}
