import 'package:flutter/material.dart';
import 'package:solar_ui/core/theme/app_layout.dart';
import 'package:solar_ui/core/theme/solar_theme_colors.dart';

class SolarPrimaryButton extends StatelessWidget {
  const SolarPrimaryButton({
    required this.label,
    required this.onPressed,
    this.icon,
    this.isLoading = false,
    this.expand = false,
    super.key,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool isLoading;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final button = FilledButton(
      onPressed: isLoading ? null : onPressed,
      child: _ButtonContent(label: label, icon: icon, isLoading: isLoading),
    );

    return expand ? SizedBox(width: double.infinity, child: button) : button;
  }
}

class SolarSecondaryButton extends StatelessWidget {
  const SolarSecondaryButton({
    required this.label,
    required this.onPressed,
    this.icon,
    this.expand = false,
    this.onDark = false,
    super.key,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool expand;
  final bool onDark;

  @override
  Widget build(BuildContext context) {
    final button = OutlinedButton(
      onPressed: onPressed,
      style: onDark
          ? OutlinedButton.styleFrom(
              foregroundColor: context.solarColors.onHero,
              side: BorderSide(
                color: context.solarColors.onHero.withValues(alpha: 0.7),
              ),
            )
          : null,
      child: _ButtonContent(label: label, icon: icon),
    );

    return expand ? SizedBox(width: double.infinity, child: button) : button;
  }
}

class _ButtonContent extends StatelessWidget {
  const _ButtonContent({
    required this.label,
    this.icon,
    this.isLoading = false,
  });

  final String label;
  final IconData? icon;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (isLoading)
          const SizedBox.square(
            dimension: AppSizes.iconSmall,
            child: CircularProgressIndicator(strokeWidth: 2),
          )
        else if (icon != null)
          Icon(icon, size: AppSizes.iconSmall),
        if (isLoading || icon != null) const SizedBox(width: AppSpacing.xs),
        Flexible(
          fit: FlexFit.loose,
          child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
        ),
      ],
    );
  }
}
