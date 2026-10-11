import 'package:flutter/material.dart';
import 'package:solar_ui/app/theme_controller.dart';
import 'package:solar_ui/core/branding/company_profile.dart';
import 'package:solar_ui/core/demo/demo_user.dart';
import 'package:solar_ui/core/theme/app_layout.dart';
import 'package:solar_ui/core/widgets/company_logo.dart';
import 'package:solar_ui/core/widgets/solar_card.dart';
import 'package:solar_ui/core/widgets/theme_selector.dart';

/// Company identity and appearance. This is not a settings or profile workflow.
class CompanyAboutScreen extends StatelessWidget {
  const CompanyAboutScreen({
    required this.user,
    required this.themeController,
    super.key,
  });

  final DemoUser user;
  final ThemeController themeController;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.xxl,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('More', style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: AppSpacing.lg),
              SolarCard(
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 26,
                      backgroundColor: colorScheme.secondary,
                      foregroundColor: colorScheme.onSecondary,
                      child: Text(user.initials),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user.displayName,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: AppSpacing.xxs),
                          Text(
                            '${user.role} · Development preview',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              SolarCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const CompanyLogo(height: 64),
                    const SizedBox(height: AppSpacing.lg),
                    Text(
                      CompanyProfile.legalName,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      'Registered office',
                      style: Theme.of(context).textTheme.labelMedium
                          ?.copyWith(color: colorScheme.primary),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    for (final line in CompanyProfile.addressLines)
                      Text(line, style: Theme.of(context).textTheme.bodyLarge),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      'GSTIN',
                      style: Theme.of(context).textTheme.labelMedium
                          ?.copyWith(color: colorScheme.primary),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    SelectableText(
                      CompanyProfile.gstin,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                'Appearance',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: AppSpacing.sm),
              SolarThemeSelector(controller: themeController),
              const SizedBox(height: AppSpacing.md),
              Text(
                'Authentication and business operations are not connected.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
