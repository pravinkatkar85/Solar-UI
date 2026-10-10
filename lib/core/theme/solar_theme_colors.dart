import 'package:flutter/material.dart';

/// Solar-specific semantic colors that are not represented by [ColorScheme].
@immutable
class SolarThemeColors extends ThemeExtension<SolarThemeColors> {
  const SolarThemeColors({
    required this.heroStart,
    required this.heroEnd,
    required this.heroSurface,
    required this.onHero,
    required this.cardShadow,
    required this.success,
    required this.onSuccessContainer,
    required this.successContainer,
    required this.warning,
    required this.onWarningContainer,
    required this.warningContainer,
    required this.info,
    required this.onInfoContainer,
    required this.infoContainer,
  });

  final Color heroStart;
  final Color heroEnd;
  final Color heroSurface;
  final Color onHero;
  final Color cardShadow;
  final Color success;
  final Color onSuccessContainer;
  final Color successContainer;
  final Color warning;
  final Color onWarningContainer;
  final Color warningContainer;
  final Color info;
  final Color onInfoContainer;
  final Color infoContainer;

  static const light = SolarThemeColors(
    heroStart: Color(0xFF172235),
    heroEnd: Color(0xFF233550),
    heroSurface: Color(0xFF2B3E5B),
    onHero: Color(0xFFF8FAFC),
    cardShadow: Color(0x12172033),
    success: Color(0xFF16794B),
    onSuccessContainer: Color(0xFF0B5734),
    successContainer: Color(0xFFE2F5EB),
    warning: Color(0xFF9A5B0A),
    onWarningContainer: Color(0xFF754204),
    warningContainer: Color(0xFFFFF0CC),
    info: Color(0xFF275DAD),
    onInfoContainer: Color(0xFF1E4B91),
    infoContainer: Color(0xFFE6F0FF),
  );

  static const dark = SolarThemeColors(
    heroStart: Color(0xFF19263A),
    heroEnd: Color(0xFF263B59),
    heroSurface: Color(0xFF304765),
    onHero: Color(0xFFF8FAFC),
    cardShadow: Color(0x52040A12),
    success: Color(0xFF5DD39E),
    onSuccessContainer: Color(0xFF9CE8C3),
    successContainer: Color(0xFF153F31),
    warning: Color(0xFFF2B95F),
    onWarningContainer: Color(0xFFFFD68F),
    warningContainer: Color(0xFF4C381C),
    info: Color(0xFF8DB7FF),
    onInfoContainer: Color(0xFFBDD3FF),
    infoContainer: Color(0xFF223C66),
  );

  @override
  SolarThemeColors copyWith({
    Color? heroStart,
    Color? heroEnd,
    Color? heroSurface,
    Color? onHero,
    Color? cardShadow,
    Color? success,
    Color? onSuccessContainer,
    Color? successContainer,
    Color? warning,
    Color? onWarningContainer,
    Color? warningContainer,
    Color? info,
    Color? onInfoContainer,
    Color? infoContainer,
  }) {
    return SolarThemeColors(
      heroStart: heroStart ?? this.heroStart,
      heroEnd: heroEnd ?? this.heroEnd,
      heroSurface: heroSurface ?? this.heroSurface,
      onHero: onHero ?? this.onHero,
      cardShadow: cardShadow ?? this.cardShadow,
      success: success ?? this.success,
      onSuccessContainer: onSuccessContainer ?? this.onSuccessContainer,
      successContainer: successContainer ?? this.successContainer,
      warning: warning ?? this.warning,
      onWarningContainer: onWarningContainer ?? this.onWarningContainer,
      warningContainer: warningContainer ?? this.warningContainer,
      info: info ?? this.info,
      onInfoContainer: onInfoContainer ?? this.onInfoContainer,
      infoContainer: infoContainer ?? this.infoContainer,
    );
  }

  @override
  SolarThemeColors lerp(covariant SolarThemeColors? other, double t) {
    if (other == null) return this;

    return SolarThemeColors(
      heroStart: Color.lerp(heroStart, other.heroStart, t)!,
      heroEnd: Color.lerp(heroEnd, other.heroEnd, t)!,
      heroSurface: Color.lerp(heroSurface, other.heroSurface, t)!,
      onHero: Color.lerp(onHero, other.onHero, t)!,
      cardShadow: Color.lerp(cardShadow, other.cardShadow, t)!,
      success: Color.lerp(success, other.success, t)!,
      onSuccessContainer: Color.lerp(
        onSuccessContainer,
        other.onSuccessContainer,
        t,
      )!,
      successContainer: Color.lerp(
        successContainer,
        other.successContainer,
        t,
      )!,
      warning: Color.lerp(warning, other.warning, t)!,
      onWarningContainer: Color.lerp(
        onWarningContainer,
        other.onWarningContainer,
        t,
      )!,
      warningContainer: Color.lerp(
        warningContainer,
        other.warningContainer,
        t,
      )!,
      info: Color.lerp(info, other.info, t)!,
      onInfoContainer: Color.lerp(onInfoContainer, other.onInfoContainer, t)!,
      infoContainer: Color.lerp(infoContainer, other.infoContainer, t)!,
    );
  }
}

extension SolarThemeColorsContext on BuildContext {
  SolarThemeColors get solarColors =>
      Theme.of(this).extension<SolarThemeColors>()!;
}
