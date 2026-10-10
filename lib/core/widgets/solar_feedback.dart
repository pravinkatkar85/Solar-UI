import 'package:flutter/material.dart';
import 'package:solar_ui/core/theme/app_layout.dart';
import 'package:solar_ui/core/theme/solar_theme_colors.dart';

enum SolarStatusTone { neutral, success, warning, info }

class SolarStatusIndicator extends StatelessWidget {
  const SolarStatusIndicator({
    required this.label,
    this.tone = SolarStatusTone.neutral,
    super.key,
  });

  final String label;
  final SolarStatusTone tone;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final semanticColors = context.solarColors;
    final colors = switch (tone) {
      SolarStatusTone.success => (
        foreground: semanticColors.onSuccessContainer,
        indicator: semanticColors.success,
        background: semanticColors.successContainer,
      ),
      SolarStatusTone.warning => (
        foreground: semanticColors.onWarningContainer,
        indicator: semanticColors.warning,
        background: semanticColors.warningContainer,
      ),
      SolarStatusTone.info => (
        foreground: semanticColors.onInfoContainer,
        indicator: semanticColors.info,
        background: semanticColors.infoContainer,
      ),
      SolarStatusTone.neutral => (
        foreground: colorScheme.onSecondaryContainer,
        indicator: colorScheme.secondary,
        background: colorScheme.secondaryContainer,
      ),
    };

    return Semantics(
      label: 'Status: $label',
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colors.background,
          borderRadius: BorderRadius.circular(AppRadii.pill),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: AppSpacing.xs,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              DecoratedBox(
                decoration: BoxDecoration(
                  color: colors.indicator,
                  shape: BoxShape.circle,
                ),
                child: const SizedBox.square(dimension: 7),
              ),
              const SizedBox(width: AppSpacing.xs),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: colors.foreground,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class SolarLoadingIndicator extends StatelessWidget {
  const SolarLoadingIndicator({
    this.label = 'Loading',
    this.compact = false,
    super.key,
  });

  final String label;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final indicatorSize = compact ? AppSizes.iconSmall : AppSizes.iconMedium;

    return Semantics(
      label: label,
      liveRegion: true,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox.square(
            dimension: indicatorSize,
            child: const CircularProgressIndicator(strokeWidth: 2.5),
          ),
          const SizedBox(width: AppSpacing.sm),
          Text(label, style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }
}
