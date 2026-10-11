import 'package:flutter/material.dart';
import 'package:solar_ui/core/theme/app_colors.dart';
import 'package:solar_ui/core/theme/app_layout.dart';
import 'package:solar_ui/core/theme/solar_theme_colors.dart';

abstract final class AppTheme {
  static const _lightScheme = ColorScheme.light(
    primary: AppColors.solarOrange,
    onPrimary: AppColors.deepNavy,
    primaryContainer: AppColors.solarOrangeSoft,
    onPrimaryContainer: Color(0xFF7A3A08),
    secondary: AppColors.deepNavy,
    onSecondary: AppColors.textOnDark,
    secondaryContainer: AppColors.navySoft,
    onSecondaryContainer: AppColors.deepNavy,
    tertiary: AppColors.energyLime,
    onTertiary: Color(0xFF173006),
    tertiaryContainer: AppColors.energyLimeSoft,
    onTertiaryContainer: Color(0xFF27420C),
    error: AppColors.error,
    onError: AppColors.textOnDark,
    errorContainer: AppColors.errorSoft,
    onErrorContainer: AppColors.error,
    surface: AppColors.surface,
    onSurface: AppColors.textPrimary,
    surfaceContainerLowest: AppColors.surface,
    surfaceContainerLow: Color(0xFFFBF8F4),
    surfaceContainer: AppColors.surfaceMuted,
    surfaceContainerHigh: Color(0xFFE9E2D8),
    onSurfaceVariant: AppColors.textSecondary,
    outline: Color(0xFF8C8378),
    outlineVariant: AppColors.border,
    shadow: Color(0x1A172033),
  );

  static const _darkScheme = ColorScheme.dark(
    primary: AppColors.solarOrangeDarkTheme,
    onPrimary: Color(0xFF3F2108),
    primaryContainer: Color(0xFF60370F),
    onPrimaryContainer: Color(0xFFFFDCC2),
    secondary: Color(0xFFB9C7DA),
    onSecondary: Color(0xFF243247),
    secondaryContainer: Color(0xFF2C3A50),
    onSecondaryContainer: Color(0xFFD9E4F4),
    tertiary: AppColors.energyLimeDark,
    onTertiary: Color(0xFF1C3308),
    tertiaryContainer: Color(0xFF2C4518),
    onTertiaryContainer: Color(0xFFD8F0B4),
    error: AppColors.darkError,
    onError: Color(0xFF690005),
    errorContainer: AppColors.darkErrorContainer,
    onErrorContainer: Color(0xFFFFDAD5),
    surface: AppColors.darkSurface,
    onSurface: AppColors.darkTextPrimary,
    surfaceContainerLowest: AppColors.darkCanvas,
    surfaceContainerLow: Color(0xFF171D2A),
    surfaceContainer: AppColors.darkSurfaceMuted,
    surfaceContainerHigh: Color(0xFF30384A),
    onSurfaceVariant: AppColors.darkTextSecondary,
    outline: Color(0xFF8E877E),
    outlineVariant: AppColors.darkBorder,
    shadow: Color(0x99000000),
  );

  static ThemeData get lightTheme => _build(
    brightness: Brightness.light,
    colorScheme: _lightScheme,
    scaffoldBackground: AppColors.canvas,
    semanticColors: SolarThemeColors.light,
  );

  static ThemeData get darkTheme => _build(
    brightness: Brightness.dark,
    colorScheme: _darkScheme,
    scaffoldBackground: AppColors.darkCanvas,
    semanticColors: SolarThemeColors.dark,
  );

  static ThemeData _build({
    required Brightness brightness,
    required ColorScheme colorScheme,
    required Color scaffoldBackground,
    required SolarThemeColors semanticColors,
  }) {
    final typography = Typography.material2021(
      platform: TargetPlatform.android,
    );
    final baseTextTheme =
        (brightness == Brightness.light ? typography.black : typography.white)
            .apply(
              bodyColor: colorScheme.onSurface,
              displayColor: colorScheme.onSurface,
            );

    final roundedSmall = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppRadii.small),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: scaffoldBackground,
      canvasColor: scaffoldBackground,
      extensions: [semanticColors],
      textTheme: baseTextTheme.copyWith(
        displaySmall: baseTextTheme.displaySmall?.copyWith(
          fontSize: 42,
          height: 1.08,
          fontWeight: FontWeight.w700,
          letterSpacing: -1.2,
        ),
        headlineMedium: baseTextTheme.headlineMedium?.copyWith(
          fontSize: 28,
          height: 1.18,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.6,
        ),
        titleLarge: baseTextTheme.titleLarge?.copyWith(
          fontSize: 21,
          height: 1.3,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.2,
        ),
        titleMedium: baseTextTheme.titleMedium?.copyWith(
          fontSize: 16,
          height: 1.4,
          fontWeight: FontWeight.w700,
        ),
        bodyLarge: baseTextTheme.bodyLarge?.copyWith(
          fontSize: 16,
          height: 1.55,
          color: colorScheme.onSurfaceVariant,
        ),
        bodyMedium: baseTextTheme.bodyMedium?.copyWith(
          fontSize: 14,
          height: 1.5,
          color: colorScheme.onSurfaceVariant,
        ),
        labelLarge: baseTextTheme.labelLarge?.copyWith(
          fontSize: 15,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.1,
        ),
        labelMedium: baseTextTheme.labelMedium?.copyWith(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.1,
        ),
      ),
      iconTheme: IconThemeData(color: colorScheme.onSurfaceVariant),
      appBarTheme: AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: scaffoldBackground,
        foregroundColor: colorScheme.onSurface,
        centerTitle: false,
        surfaceTintColor: Colors.transparent,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        margin: EdgeInsets.zero,
        color: colorScheme.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.medium),
          side: BorderSide(color: colorScheme.outlineVariant),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: ButtonStyle(
          minimumSize: const WidgetStatePropertyAll(
            Size(64, AppSizes.minTouchTarget + 4),
          ),
          padding: const WidgetStatePropertyAll(
            EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.sm,
            ),
          ),
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.disabled)) {
              return colorScheme.surfaceContainerHigh;
            }
            if (states.contains(WidgetState.pressed)) {
              return brightness == Brightness.light
                  ? AppColors.solarOrangeDark
                  : AppColors.solarOrange;
            }
            return colorScheme.primary;
          }),
          foregroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.disabled)) {
              return colorScheme.onSurfaceVariant;
            }
            return colorScheme.onPrimary;
          }),
          overlayColor: WidgetStatePropertyAll(
            colorScheme.onPrimary.withValues(alpha: 0.08),
          ),
          textStyle: const WidgetStatePropertyAll(
            TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
          ),
          shape: WidgetStatePropertyAll(roundedSmall),
          elevation: const WidgetStatePropertyAll(0),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: ButtonStyle(
          minimumSize: const WidgetStatePropertyAll(
            Size(64, AppSizes.minTouchTarget + 4),
          ),
          padding: const WidgetStatePropertyAll(
            EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.sm,
            ),
          ),
          foregroundColor: WidgetStatePropertyAll(colorScheme.onSurface),
          side: WidgetStateProperty.resolveWith(
            (states) => BorderSide(
              color: states.contains(WidgetState.hovered)
                  ? colorScheme.primary
                  : colorScheme.outlineVariant,
              width: states.contains(WidgetState.focused) ? 1.5 : 1,
            ),
          ),
          overlayColor: WidgetStatePropertyAll(
            colorScheme.primary.withValues(alpha: 0.08),
          ),
          textStyle: const WidgetStatePropertyAll(
            TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
          ),
          shape: WidgetStatePropertyAll(roundedSmall),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colorScheme.surfaceContainerLow,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.md,
        ),
        labelStyle: TextStyle(color: colorScheme.onSurfaceVariant),
        floatingLabelStyle: TextStyle(
          color: colorScheme.primary,
          fontWeight: FontWeight.w600,
        ),
        hintStyle: TextStyle(color: colorScheme.onSurfaceVariant),
        helperStyle: TextStyle(color: colorScheme.onSurfaceVariant),
        prefixIconColor: colorScheme.onSurfaceVariant,
        border: _inputBorder(colorScheme.outlineVariant),
        enabledBorder: _inputBorder(colorScheme.outlineVariant),
        focusedBorder: _inputBorder(colorScheme.primary, width: 1.5),
        errorBorder: _inputBorder(colorScheme.error),
        focusedErrorBorder: _inputBorder(colorScheme.error, width: 1.5),
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 68,
        backgroundColor: Colors.transparent,
        indicatorColor: colorScheme.primaryContainer,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return TextStyle(
            fontSize: 12,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            color: selected
                ? colorScheme.onSurface
                : colorScheme.onSurfaceVariant,
          );
        }),
      ),
      dividerTheme: DividerThemeData(
        color: colorScheme.outlineVariant,
        thickness: 1,
        space: 1,
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: colorScheme.primary,
        linearTrackColor: colorScheme.primaryContainer,
        circularTrackColor: colorScheme.primaryContainer,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: colorScheme.inverseSurface,
        contentTextStyle: TextStyle(color: colorScheme.onInverseSurface),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.small),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: colorScheme.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.large),
        ),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: colorScheme.surfaceContainer,
        surfaceTintColor: Colors.transparent,
        elevation: 10,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.medium),
          side: BorderSide(color: colorScheme.outlineVariant),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: colorScheme.surfaceContainer,
        selectedColor: colorScheme.primaryContainer,
        labelStyle: TextStyle(
          color: colorScheme.onSurface,
          fontWeight: FontWeight.w600,
        ),
        side: BorderSide(color: colorScheme.outlineVariant),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.pill),
        ),
      ),
      focusColor: colorScheme.primary.withValues(alpha: 0.14),
      hoverColor: colorScheme.primary.withValues(alpha: 0.08),
      splashColor: colorScheme.primary.withValues(alpha: 0.1),
      visualDensity: VisualDensity.standard,
      materialTapTargetSize: MaterialTapTargetSize.padded,
    );
  }

  static OutlineInputBorder _inputBorder(Color color, {double width = 1}) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppRadii.small),
      borderSide: BorderSide(color: color, width: width),
    );
  }
}
