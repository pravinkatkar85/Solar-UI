import 'package:flutter/material.dart';
import 'package:solar_ui/app/theme_controller.dart';
import 'package:solar_ui/core/theme/app_layout.dart';

class SolarThemeSelector extends StatelessWidget {
  const SolarThemeSelector({
    required this.controller,
    this.showLabel = true,
    super.key,
  });

  final ThemeController controller;
  final bool showLabel;

  @override
  Widget build(BuildContext context) {
    final mode = controller.themeMode;
    final label = _labelFor(mode);

    return PopupMenuButton<ThemeMode>(
      key: const Key('theme-selector'),
      initialValue: mode,
      tooltip: 'Choose appearance',
      onSelected: controller.setThemeMode,
      position: PopupMenuPosition.under,
      itemBuilder: (context) => ThemeMode.values
          .map(
            (option) => PopupMenuItem<ThemeMode>(
              value: option,
              child: Row(
                children: [
                  Icon(_iconFor(option), size: AppSizes.iconMedium),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(child: Text(_labelFor(option))),
                  if (option == mode) ...[
                    const SizedBox(width: AppSpacing.lg),
                    Icon(
                      Icons.check_rounded,
                      color: Theme.of(context).colorScheme.primary,
                      size: AppSizes.iconSmall,
                    ),
                  ],
                ],
              ),
            ),
          )
          .toList(),
      child: Semantics(
        button: true,
        label: 'Appearance: $label',
        child: Container(
          constraints: const BoxConstraints(
            minHeight: AppSizes.minTouchTarget,
            minWidth: AppSizes.minTouchTarget,
          ),
          padding: EdgeInsets.symmetric(
            horizontal: showLabel ? AppSpacing.sm : AppSpacing.xs,
          ),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainer,
            borderRadius: BorderRadius.circular(AppRadii.pill),
            border: Border.all(
              color: Theme.of(context).colorScheme.outlineVariant,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                _iconFor(mode),
                size: AppSizes.iconSmall,
                color: Theme.of(context).colorScheme.onSurface,
              ),
              if (showLabel) ...[
                const SizedBox(width: AppSpacing.xs),
                Text(label, style: Theme.of(context).textTheme.labelLarge),
                const SizedBox(width: AppSpacing.xxs),
                const Icon(
                  Icons.keyboard_arrow_down_rounded,
                  size: AppSizes.iconSmall,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  static String _labelFor(ThemeMode mode) {
    return switch (mode) {
      ThemeMode.system => 'System default',
      ThemeMode.light => 'Light',
      ThemeMode.dark => 'Dark',
    };
  }

  static IconData _iconFor(ThemeMode mode) {
    return switch (mode) {
      ThemeMode.system => Icons.brightness_auto_outlined,
      ThemeMode.light => Icons.light_mode_outlined,
      ThemeMode.dark => Icons.dark_mode_outlined,
    };
  }
}
