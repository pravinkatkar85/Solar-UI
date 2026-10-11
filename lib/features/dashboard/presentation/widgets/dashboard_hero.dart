import 'package:flutter/material.dart';
import 'package:solar_ui/core/demo/demo_user.dart';
import 'package:solar_ui/core/theme/app_layout.dart';
import 'package:solar_ui/core/theme/solar_theme_colors.dart';
import 'package:solar_ui/core/widgets/solar_buttons.dart';

class DashboardHero extends StatelessWidget {
  const DashboardHero({
    required this.user,
    required this.onOpenWorkspace,
    super.key,
  });

  final DemoUser user;
  final VoidCallback onOpenWorkspace;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final colors = context.solarColors;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(AppRadii.large),
        border: Border.all(color: colorScheme.outlineVariant),
        boxShadow: [
          BoxShadow(
            color: colors.cardShadow,
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 680;

          return Padding(
            padding: EdgeInsets.all(compact ? AppSpacing.lg : AppSpacing.xl),
            child: compact
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _HeroContent(
                        user: user,
                        onOpenWorkspace: onOpenWorkspace,
                        compact: true,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      const _DashboardArtwork(compact: true),
                    ],
                  )
                : Row(
                    children: [
                      Expanded(
                        flex: 6,
                        child: _HeroContent(
                          user: user,
                          onOpenWorkspace: onOpenWorkspace,
                          compact: false,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.xl),
                      const Expanded(flex: 4, child: _DashboardArtwork()),
                    ],
                  ),
          );
        },
      ),
    );
  }
}

class _HeroContent extends StatelessWidget {
  const _HeroContent({
    required this.user,
    required this.onOpenWorkspace,
    required this.compact,
  });

  final DemoUser user;
  final VoidCallback onOpenWorkspace;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'WELCOME, ${user.firstName.toUpperCase()}',
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: colorScheme.primary,
            letterSpacing: 1.2,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'Your solar service\nworkspace, in one place.',
          style: compact
              ? Theme.of(context).textTheme.headlineMedium
              : Theme.of(context).textTheme.displaySmall,
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          'Keep customer care, site work and service operations clear and '
          'connected as each feature becomes available.',
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        const SizedBox(height: AppSpacing.lg),
        SolarPrimaryButton(
          label: 'Open workspace',
          icon: Icons.arrow_forward_rounded,
          expand: compact,
          onPressed: onOpenWorkspace,
        ),
      ],
    );
  }
}

class _DashboardArtwork extends StatelessWidget {
  const _DashboardArtwork({this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Semantics(
      label: 'Solar panel and connected service illustration',
      image: true,
      child: AspectRatio(
        aspectRatio: compact ? 2.8 : 1.45,
        child: Container(
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(AppRadii.medium),
          ),
          clipBehavior: Clip.antiAlias,
          child: CustomPaint(
            painter: _DashboardArtworkPainter(
              accent: colorScheme.primary,
              foreground: colorScheme.onSecondary,
              panel: colorScheme.secondary,
              energy: colorScheme.tertiary,
            ),
          ),
        ),
      ),
    );
  }
}

class _DashboardArtworkPainter extends CustomPainter {
  const _DashboardArtworkPainter({
    required this.accent,
    required this.foreground,
    required this.panel,
    required this.energy,
  });

  final Color accent;
  final Color foreground;
  final Color panel;
  final Color energy;

  @override
  void paint(Canvas canvas, Size size) {
    final sun = Offset(size.width * 0.78, size.height * 0.24);
    canvas.drawCircle(sun, size.shortestSide * 0.11, Paint()..color = accent);
    canvas.drawCircle(sun, size.shortestSide * 0.045, Paint()..color = energy);
    canvas.drawCircle(
      sun,
      size.shortestSide * 0.18,
      Paint()
        ..color = accent.withValues(alpha: 0.16)
        ..style = PaintingStyle.stroke
        ..strokeWidth = size.shortestSide * 0.07,
    );

    final panelPath = Path()
      ..moveTo(size.width * 0.17, size.height * 0.48)
      ..lineTo(size.width * 0.68, size.height * 0.43)
      ..lineTo(size.width * 0.82, size.height * 0.84)
      ..lineTo(size.width * 0.27, size.height * 0.89)
      ..close();
    canvas.drawPath(panelPath, Paint()..color = panel);
    canvas.drawPath(
      panelPath,
      Paint()
        ..color = foreground.withValues(alpha: 0.72)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );

    for (var index = 1; index < 4; index++) {
      final fraction = index / 4;
      canvas.drawLine(
        Offset(
          _lerp(size.width * 0.17, size.width * 0.68, fraction),
          _lerp(size.height * 0.48, size.height * 0.43, fraction),
        ),
        Offset(
          _lerp(size.width * 0.27, size.width * 0.82, fraction),
          _lerp(size.height * 0.89, size.height * 0.84, fraction),
        ),
        Paint()
          ..color = foreground.withValues(alpha: 0.42)
          ..strokeWidth = 1,
      );
    }
    for (var index = 1; index < 3; index++) {
      final fraction = index / 3;
      canvas.drawLine(
        Offset(
          _lerp(size.width * 0.17, size.width * 0.27, fraction),
          _lerp(size.height * 0.48, size.height * 0.89, fraction),
        ),
        Offset(
          _lerp(size.width * 0.68, size.width * 0.82, fraction),
          _lerp(size.height * 0.43, size.height * 0.84, fraction),
        ),
        Paint()
          ..color = foreground.withValues(alpha: 0.42)
          ..strokeWidth = 1,
      );
    }

    final route = Path()
      ..moveTo(sun.dx - 12, sun.dy + 12)
      ..quadraticBezierTo(
        size.width * 0.58,
        size.height * 0.34,
        size.width * 0.56,
        size.height * 0.48,
      );
    canvas.drawPath(
      route,
      Paint()
        ..color = accent.withValues(alpha: 0.75)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round,
    );
  }

  double _lerp(double start, double end, double fraction) {
    return start + ((end - start) * fraction);
  }

  @override
  bool shouldRepaint(covariant _DashboardArtworkPainter oldDelegate) {
    return accent != oldDelegate.accent ||
        foreground != oldDelegate.foreground ||
        panel != oldDelegate.panel ||
        energy != oldDelegate.energy;
  }
}
