import 'package:flutter/material.dart';

/// Central color palette for the Solar visual language.
///
/// Deployment branding can replace these defaults later without spreading
/// color literals throughout feature code.
abstract final class AppColors {
  static const solarOrange = Color(0xFFF2994A);
  static const solarOrangeDark = Color(0xFFC96B20);
  static const solarOrangeSoft = Color(0xFFFFF3E7);
  static const solarOrangeDarkTheme = Color(0xFFFFA85C);

  static const deepNavy = Color(0xFF1E293B);
  static const navySoft = Color(0xFFE9EEF5);

  static const canvas = Color(0xFFF6F8FB);
  static const surface = Color(0xFFFFFFFF);
  static const surfaceMuted = Color(0xFFF0F3F7);
  static const border = Color(0xFFDCE2EA);

  static const textPrimary = Color(0xFF172033);
  static const textSecondary = Color(0xFF5D6878);
  static const textOnDark = Color(0xFFFFFFFF);

  static const darkCanvas = Color(0xFF0E1726);
  static const darkSurface = Color(0xFF172235);
  static const darkSurfaceMuted = Color(0xFF202E43);
  static const darkBorder = Color(0xFF34445C);
  static const darkTextPrimary = Color(0xFFF4F7FB);
  static const darkTextSecondary = Color(0xFFABB7C8);

  static const error = Color(0xFFB42318);
  static const errorSoft = Color(0xFFFDECEC);
  static const darkError = Color(0xFFFFB4AB);
  static const darkErrorContainer = Color(0xFF6E1E1A);
}
