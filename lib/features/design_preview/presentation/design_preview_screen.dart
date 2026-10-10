import 'package:flutter/material.dart';
import 'package:solar_ui/app/theme_controller.dart';
import 'package:solar_ui/core/theme/app_layout.dart';
import 'package:solar_ui/core/theme/solar_theme_colors.dart';
import 'package:solar_ui/core/widgets/solar_buttons.dart';
import 'package:solar_ui/core/widgets/solar_card.dart';
import 'package:solar_ui/core/widgets/solar_feedback.dart';
import 'package:solar_ui/core/widgets/solar_form_field.dart';
import 'package:solar_ui/core/widgets/theme_selector.dart';

/// Temporary visual reference used until the product landing flow is approved.
///
/// This screen intentionally contains no authentication, navigation, live
/// customer data, or business-state assumptions.
class DesignPreviewScreen extends StatelessWidget {
  const DesignPreviewScreen({required this.themeController, super.key});

  final ThemeController themeController;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final horizontalPadding =
                constraints.maxWidth < AppSizes.compactBreakpoint
                ? AppSpacing.md
                : AppSpacing.xl;

            return SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                horizontalPadding,
                AppSpacing.md,
                horizontalPadding,
                AppSpacing.xxl,
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxWidth: AppSizes.contentMaxWidth,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _PreviewHeader(themeController: themeController),
                      const SizedBox(height: AppSpacing.xl),
                      const _HeroSection(),
                      const SizedBox(height: AppSpacing.xxl),
                      const _FeatureSection(),
                      const SizedBox(height: AppSpacing.xxl),
                      const _ComponentSection(),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _PreviewHeader extends StatelessWidget {
  const _PreviewHeader({required this.themeController});

  final ThemeController themeController;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return LayoutBuilder(
      builder: (context, constraints) {
        final showThemeLabel = constraints.maxWidth >= 560;

        return Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: colorScheme.primary,
                borderRadius: BorderRadius.circular(AppRadii.medium),
                boxShadow: [
                  BoxShadow(
                    color: colorScheme.primary.withValues(alpha: 0.24),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              alignment: Alignment.center,
              child: Icon(
                Icons.wb_sunny_rounded,
                color: colorScheme.onPrimary,
                size: AppSizes.iconLarge,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Solar',
                    style: Theme.of(context).textTheme.titleLarge
                        ?.copyWith(letterSpacing: -0.4),
                  ),
                  Text(
                    'Service management',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            SolarThemeSelector(
              controller: themeController,
              showLabel: showThemeLabel,
            ),
          ],
        );
      },
    );
  }
}

class _HeroSection extends StatelessWidget {
  const _HeroSection();

  @override
  Widget build(BuildContext context) {
    final colors = context.solarColors;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [colors.heroStart, colors.heroEnd],
        ),
        borderRadius: BorderRadius.circular(AppRadii.large),
        boxShadow: [
          BoxShadow(
            color: colors.cardShadow.withValues(alpha: 0.9),
            blurRadius: 42,
            offset: const Offset(0, 18),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isCompact = constraints.maxWidth < AppSizes.compactBreakpoint;

          return Padding(
            padding: EdgeInsets.all(isCompact ? AppSpacing.lg : AppSpacing.xxl),
            child: isCompact
                ? const Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _HeroCopy(isCompact: true),
                      SizedBox(height: AppSpacing.xl),
                      _SolarSystemIllustration(),
                    ],
                  )
                : const Row(
                    children: [
                      Expanded(flex: 11, child: _HeroCopy(isCompact: false)),
                      SizedBox(width: AppSpacing.xxl),
                      Expanded(flex: 9, child: _SolarSystemIllustration()),
                    ],
                  ),
          );
        },
      ),
    );
  }
}

class _HeroCopy extends StatelessWidget {
  const _HeroCopy({required this.isCompact});

  final bool isCompact;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final heroColor = context.solarColors.onHero;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SolarStatusIndicator(
          label: 'Design system preview',
          tone: SolarStatusTone.info,
        ),
        const SizedBox(height: AppSpacing.lg),
        Text(
          'Solar service,\ndesigned around trust.',
          style: (isCompact ? textTheme.headlineMedium : textTheme.displaySmall)
              ?.copyWith(color: heroColor, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: AppSpacing.md),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: Text(
            'A calm, dependable foundation for catalogue, installation, '
            'service and support experiences.',
            style: textTheme.bodyLarge?.copyWith(
              color: heroColor.withValues(alpha: 0.78),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        const _HeroActions(),
      ],
    );
  }
}

class _HeroActions extends StatelessWidget {
  const _HeroActions();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 430) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SolarPrimaryButton(
                label: 'Preview action',
                icon: Icons.arrow_forward_rounded,
                expand: true,
                onPressed: () => _showPreviewMessage(context),
              ),
              const SizedBox(height: AppSpacing.sm),
              SolarSecondaryButton(
                label: 'View components',
                icon: Icons.widgets_outlined,
                expand: true,
                onDark: true,
                onPressed: () => _showPreviewMessage(context),
              ),
            ],
          );
        }

        return Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            SolarPrimaryButton(
              label: 'Preview action',
              icon: Icons.arrow_forward_rounded,
              onPressed: () => _showPreviewMessage(context),
            ),
            SolarSecondaryButton(
              label: 'View components',
              icon: Icons.widgets_outlined,
              onDark: true,
              onPressed: () => _showPreviewMessage(context),
            ),
          ],
        );
      },
    );
  }
}

class _SolarSystemIllustration extends StatelessWidget {
  const _SolarSystemIllustration();

  @override
  Widget build(BuildContext context) {
    final colors = context.solarColors;
    final colorScheme = Theme.of(context).colorScheme;

    return Semantics(
      label: 'Solar panel connected to home energy and service support',
      image: true,
      child: AspectRatio(
        aspectRatio: 1.28,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: colors.heroSurface.withValues(alpha: 0.72),
            borderRadius: BorderRadius.circular(AppRadii.large),
            border: Border.all(color: colors.onHero.withValues(alpha: 0.12)),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppRadii.large),
            child: Stack(
              children: [
                Positioned.fill(
                  child: CustomPaint(
                    painter: _SolarSystemPainter(
                      accent: colorScheme.primary,
                      line: colors.onHero.withValues(alpha: 0.2),
                      panel: const Color(0xFF31547E),
                      panelLine: colors.onHero.withValues(alpha: 0.58),
                    ),
                  ),
                ),
                Positioned(
                  top: AppSpacing.md,
                  left: AppSpacing.md,
                  child: _IllustrationLabel(
                    icon: Icons.bolt_rounded,
                    label: 'Connected energy',
                    foreground: colors.onHero,
                  ),
                ),
                Positioned(
                  top: AppSpacing.lg + 48,
                  right: AppSpacing.md,
                  child: _IllustrationNode(
                    icon: Icons.home_work_outlined,
                    color: colors.onHero,
                  ),
                ),
                Positioned(
                  left: AppSpacing.lg,
                  bottom: AppSpacing.lg,
                  child: _IllustrationNode(
                    icon: Icons.handyman_outlined,
                    color: colors.onHero,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _IllustrationLabel extends StatelessWidget {
  const _IllustrationLabel({
    required this.icon,
    required this.label,
    required this.foreground,
  });

  final IconData icon;
  final String label;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: foreground.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppRadii.pill),
        border: Border.all(color: foreground.withValues(alpha: 0.12)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: AppSizes.iconSmall, color: foreground),
          const SizedBox(width: AppSpacing.xs),
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium
                ?.copyWith(color: foreground),
          ),
        ],
      ),
    );
  }
}

class _IllustrationNode extends StatelessWidget {
  const _IllustrationNode({required this.icon, required this.color});

  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: AppSizes.minTouchTarget,
      height: AppSizes.minTouchTarget,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        shape: BoxShape.circle,
        border: Border.all(color: color.withValues(alpha: 0.18)),
      ),
      alignment: Alignment.center,
      child: Icon(icon, color: color, size: AppSizes.iconMedium),
    );
  }
}

class _SolarSystemPainter extends CustomPainter {
  const _SolarSystemPainter({
    required this.accent,
    required this.line,
    required this.panel,
    required this.panelLine,
  });

  final Color accent;
  final Color line;
  final Color panel;
  final Color panelLine;

  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = line.withValues(alpha: 0.32)
      ..strokeWidth = 0.8;
    const gridGap = 28.0;
    for (var x = 0.0; x < size.width; x += gridGap) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    for (var y = 0.0; y < size.height; y += gridGap) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    final sunCenter = Offset(size.width * 0.76, size.height * 0.22);
    canvas.drawCircle(
      sunCenter,
      size.shortestSide * 0.15,
      Paint()
        ..shader =
            RadialGradient(
              colors: [
                accent.withValues(alpha: 0.34),
                accent.withValues(alpha: 0),
              ],
            ).createShader(
              Rect.fromCircle(
                center: sunCenter,
                radius: size.shortestSide * 0.15,
              ),
            ),
    );
    canvas.drawCircle(
      sunCenter,
      size.shortestSide * 0.065,
      Paint()..color = accent,
    );

    final energyPath = Path()
      ..moveTo(sunCenter.dx - 4, sunCenter.dy + 18)
      ..cubicTo(
        size.width * 0.62,
        size.height * 0.42,
        size.width * 0.76,
        size.height * 0.55,
        size.width * 0.64,
        size.height * 0.7,
      );
    canvas.drawPath(
      energyPath,
      Paint()
        ..color = accent.withValues(alpha: 0.75)
        ..strokeWidth = 2.2
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round,
    );

    final panelPath = Path()
      ..moveTo(size.width * 0.22, size.height * 0.48)
      ..lineTo(size.width * 0.72, size.height * 0.43)
      ..lineTo(size.width * 0.85, size.height * 0.82)
      ..lineTo(size.width * 0.3, size.height * 0.88)
      ..close();
    canvas.drawPath(panelPath, Paint()..color = panel);
    canvas.drawPath(
      panelPath,
      Paint()
        ..color = panelLine
        ..strokeWidth = 1.6
        ..style = PaintingStyle.stroke,
    );

    for (var column = 1; column < 4; column++) {
      final fraction = column / 4;
      canvas.drawLine(
        Offset(
          _lerp(size.width * 0.22, size.width * 0.72, fraction),
          _lerp(size.height * 0.48, size.height * 0.43, fraction),
        ),
        Offset(
          _lerp(size.width * 0.3, size.width * 0.85, fraction),
          _lerp(size.height * 0.88, size.height * 0.82, fraction),
        ),
        Paint()
          ..color = panelLine
          ..strokeWidth = 1,
      );
    }
    for (var row = 1; row < 3; row++) {
      final fraction = row / 3;
      canvas.drawLine(
        Offset(
          _lerp(size.width * 0.22, size.width * 0.3, fraction),
          _lerp(size.height * 0.48, size.height * 0.88, fraction),
        ),
        Offset(
          _lerp(size.width * 0.72, size.width * 0.85, fraction),
          _lerp(size.height * 0.43, size.height * 0.82, fraction),
        ),
        Paint()
          ..color = panelLine
          ..strokeWidth = 1,
      );
    }

    canvas.drawLine(
      Offset(size.width * 0.58, size.height * 0.85),
      Offset(size.width * 0.58, size.height * 0.95),
      Paint()
        ..color = panelLine
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round,
    );
  }

  double _lerp(double start, double end, double fraction) {
    return start + ((end - start) * fraction);
  }

  @override
  bool shouldRepaint(covariant _SolarSystemPainter oldDelegate) {
    return accent != oldDelegate.accent ||
        line != oldDelegate.line ||
        panel != oldDelegate.panel ||
        panelLine != oldDelegate.panelLine;
  }
}

class _FeatureSection extends StatelessWidget {
  const _FeatureSection();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionHeading(
          eyebrow: 'PRODUCT LANGUAGE',
          title: 'Designed for the full solar journey',
          description:
              'A consistent experience can support discovery, installation '
              'and long-term care without becoming a generic admin interface.',
        ),
        const SizedBox(height: AppSpacing.lg),
        LayoutBuilder(
          builder: (context, constraints) {
            final isCompact = constraints.maxWidth < 820;
            final cardWidth = isCompact
                ? constraints.maxWidth
                : (constraints.maxWidth - (AppSpacing.md * 2)) / 3;

            return Wrap(
              spacing: AppSpacing.md,
              runSpacing: AppSpacing.md,
              children: [
                _CapabilityCard(
                  width: cardWidth,
                  number: '01',
                  icon: Icons.grid_view_rounded,
                  title: 'Discover',
                  description:
                      'A clear visual language for catalogue and enquiry.',
                ),
                _CapabilityCard(
                  width: cardWidth,
                  number: '02',
                  icon: Icons.solar_power_outlined,
                  title: 'Install',
                  description:
                      'Confident progress from order through commissioning.',
                ),
                _CapabilityCard(
                  width: cardWidth,
                  number: '03',
                  icon: Icons.home_repair_service_outlined,
                  title: 'Care',
                  description:
                      'Dependable service, site visit and support experiences.',
                ),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _CapabilityCard extends StatelessWidget {
  const _CapabilityCard({
    required this.width,
    required this.number,
    required this.icon,
    required this.title,
    required this.description,
  });

  final double width;
  final String number;
  final IconData icon;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return SizedBox(
      width: width,
      child: SolarCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(AppRadii.medium),
                  ),
                  alignment: Alignment.center,
                  child: Icon(
                    icon,
                    color: colorScheme.onPrimaryContainer,
                    size: AppSizes.iconMedium,
                  ),
                ),
                const Spacer(),
                Text(
                  number,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: colorScheme.primary,
                    letterSpacing: 1.4,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xl),
            Text(title, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: AppSpacing.xs),
            Text(description, style: Theme.of(context).textTheme.bodyMedium),
          ],
        ),
      ),
    );
  }
}

class _ComponentSection extends StatelessWidget {
  const _ComponentSection();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionHeading(
          eyebrow: 'CORE COMPONENTS',
          title: 'Consistent by default',
          description:
              'Shared controls carry the same spacing, states, contrast and '
              'touch targets across light and dark appearances.',
        ),
        const SizedBox(height: AppSpacing.lg),
        SolarCard(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isCompact =
                  constraints.maxWidth < AppSizes.compactBreakpoint;
              const form = _FormPreview();
              const feedback = _FeedbackPreview();

              if (isCompact) {
                return const Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    form,
                    SizedBox(height: AppSpacing.xl),
                    Divider(),
                    SizedBox(height: AppSpacing.xl),
                    feedback,
                  ],
                );
              }

              return const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: form),
                  SizedBox(width: AppSpacing.xl),
                  SizedBox(height: 270, child: VerticalDivider()),
                  SizedBox(width: AppSpacing.xl),
                  Expanded(child: feedback),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}

class _FormPreview extends StatelessWidget {
  const _FormPreview();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _ComponentTitle(
          icon: Icons.tune_rounded,
          title: 'Input and actions',
          description: 'Focused, spacious and easy to scan.',
        ),
        const SizedBox(height: AppSpacing.lg),
        const SolarTextField(
          label: 'Sample input',
          hint: 'Enter text',
          helperText: 'Demonstrates the shared field style.',
          prefixIcon: Icons.edit_outlined,
        ),
        const SizedBox(height: AppSpacing.md),
        SolarPrimaryButton(
          label: 'Primary action',
          expand: true,
          onPressed: () => _showPreviewMessage(context),
        ),
        const SizedBox(height: AppSpacing.sm),
        SolarSecondaryButton(
          label: 'Secondary action',
          expand: true,
          onPressed: () => _showPreviewMessage(context),
        ),
      ],
    );
  }
}

class _FeedbackPreview extends StatelessWidget {
  const _FeedbackPreview();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _ComponentTitle(
          icon: Icons.notifications_active_outlined,
          title: 'Status and progress',
          description: 'Color is always reinforced by a text label.',
        ),
        const SizedBox(height: AppSpacing.lg),
        const Wrap(
          spacing: AppSpacing.xs,
          runSpacing: AppSpacing.xs,
          children: [
            SolarStatusIndicator(
              label: 'Success',
              tone: SolarStatusTone.success,
            ),
            SolarStatusIndicator(
              label: 'Attention',
              tone: SolarStatusTone.warning,
            ),
            SolarStatusIndicator(
              label: 'Information',
              tone: SolarStatusTone.info,
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xl),
        const SolarLoadingIndicator(label: 'Loading preview'),
        const SizedBox(height: AppSpacing.md),
        Text(
          'Progress indicators include an accessible description and remain '
          'visible on every supported surface.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ],
    );
  }
}

class _SectionHeading extends StatelessWidget {
  const _SectionHeading({
    required this.eyebrow,
    required this.title,
    required this.description,
  });

  final String eyebrow;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 720),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            eyebrow,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: colorScheme.primary,
              letterSpacing: 1.5,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(title, style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: AppSpacing.xs),
          Text(description, style: Theme.of(context).textTheme.bodyLarge),
        ],
      ),
    );
  }
}

class _ComponentTitle extends StatelessWidget {
  const _ComponentTitle({
    required this.icon,
    required this.title,
    required this.description,
  });

  final IconData icon;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainer,
            borderRadius: BorderRadius.circular(AppRadii.small),
          ),
          alignment: Alignment.center,
          child: Icon(icon, color: colorScheme.primary),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: AppSpacing.xxs),
              Text(description, style: Theme.of(context).textTheme.bodyMedium),
            ],
          ),
        ),
      ],
    );
  }
}

void _showPreviewMessage(BuildContext context) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      const SnackBar(
        content: Text('Design preview only — no workflow is connected yet.'),
      ),
    );
}
