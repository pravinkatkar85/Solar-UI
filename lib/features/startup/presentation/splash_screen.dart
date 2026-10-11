import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:solar_ui/core/branding/company_profile.dart';
import 'package:solar_ui/core/theme/app_colors.dart';
import 'package:solar_ui/core/theme/app_layout.dart';
import 'package:solar_ui/core/widgets/company_logo.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({
    required this.destinationBuilder,
    this.startupDuration = const Duration(seconds: 5),
    super.key,
  });

  final WidgetBuilder destinationBuilder;
  final Duration startupDuration;

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _revealController;
  late final AnimationController _sunController;
  Timer? _navigationTimer;
  bool _started = false;
  bool _navigated = false;

  @override
  void initState() {
    super.initState();
    _revealController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _sunController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;

    final reduceMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    if (reduceMotion) {
      _revealController.value = 1;
      _sunController.value = 0.35;
    } else {
      _revealController.forward();
      _sunController.repeat();
    }

    final delay = reduceMotion
        ? const Duration(milliseconds: 450)
        : widget.startupDuration;
    _navigationTimer = Timer(delay, _openDashboard);
  }

  void _openDashboard() {
    if (!mounted || _navigated) return;
    _navigated = true;

    final reduceMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder<void>(
        pageBuilder: (context, animation, secondaryAnimation) {
          return widget.destinationBuilder(context);
        },
        transitionDuration: reduceMotion
            ? Duration.zero
            : const Duration(milliseconds: 460),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
            ),
            child: child,
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _navigationTimer?.cancel();
    _revealController.dispose();
    _sunController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final background = isDark ? AppColors.darkCanvas : AppColors.canvas;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
        systemNavigationBarColor: background,
        systemNavigationBarIconBrightness: isDark
            ? Brightness.light
            : Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: background,
        body: Stack(
          children: [
            const Positioned.fill(child: _SplashWash()),
            SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.xl,
                    vertical: AppSpacing.lg,
                  ),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 460),
                    child: AnimatedBuilder(
                      animation: _revealController,
                      builder: (context, child) {
                        final reveal = Curves.easeOutCubic.transform(
                          _revealController.value,
                        );
                        final detail = Curves.easeOut.transform(
                          ((_revealController.value - 0.25) / 0.75).clamp(0, 1),
                        );

                        return Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Opacity(
                              opacity: reveal,
                              child: Transform.scale(
                                scale: 0.92 + (0.08 * reveal),
                                child: const CompanyLogo(height: 78),
                              ),
                            ),
                            const SizedBox(height: AppSpacing.xl),
                            Opacity(
                              opacity: detail,
                              child: Transform.translate(
                                offset: Offset(0, 14 * (1 - detail)),
                                child: Column(
                                  children: [
                                    Text(
                                      CompanyProfile.productName,
                                      textAlign: TextAlign.center,
                                      style: theme.textTheme.titleLarge
                                          ?.copyWith(
                                            fontWeight: FontWeight.w700,
                                          ),
                                    ),
                                    const SizedBox(height: AppSpacing.xl),
                                    Semantics(
                                      label: 'Preparing your workspace',
                                      liveRegion: true,
                                      child: Column(
                                        children: [
                                          _SunLoader(animation: _sunController),
                                          const SizedBox(height: AppSpacing.md),
                                          Text(
                                            'Preparing your workspace',
                                            style: theme.textTheme.bodyMedium,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SplashWash extends StatelessWidget {
  const _SplashWash();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final sun = theme.colorScheme.primary;

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: RadialGradient(
          center: const Alignment(0, -0.35),
          radius: 1.1,
          colors: [
            sun.withValues(
              alpha: theme.brightness == Brightness.dark ? 0.16 : 0.22,
            ),
            theme.scaffoldBackgroundColor,
          ],
        ),
      ),
    );
  }
}

class _SunLoader extends StatelessWidget {
  const _SunLoader({required this.animation});

  final Animation<double> animation;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return SizedBox(
      width: 168,
      height: 112,
      child: AnimatedBuilder(
        animation: animation,
        builder: (context, child) {
          return CustomPaint(
            painter: _SunLoaderPainter(
              progress: animation.value,
              sun: colorScheme.primary,
              panel: colorScheme.secondary,
              line: colorScheme.onSecondary,
            ),
          );
        },
      ),
    );
  }
}

class _SunLoaderPainter extends CustomPainter {
  const _SunLoaderPainter({
    required this.progress,
    required this.sun,
    required this.panel,
    required this.line,
  });

  final double progress;
  final Color sun;
  final Color panel;
  final Color line;

  @override
  void paint(Canvas canvas, Size size) {
    final sunCenter = Offset(
      size.width * (0.22 + (0.56 * progress)),
      size.height * (0.34 - (0.08 * math.sin(progress * math.pi))),
    );

    canvas.drawCircle(
      sunCenter,
      28,
      Paint()..color = sun.withValues(alpha: 0.16),
    );
    for (var index = 0; index < 8; index++) {
      final angle = (progress * math.pi * 2) + (index * math.pi / 4);
      final reach = 16 + (index.isEven ? 4 : 0);
      canvas.drawLine(
        Offset(
          sunCenter.dx + math.cos(angle) * 12,
          sunCenter.dy + math.sin(angle) * 12,
        ),
        Offset(
          sunCenter.dx + math.cos(angle) * reach,
          sunCenter.dy + math.sin(angle) * reach,
        ),
        Paint()
          ..color = sun.withValues(alpha: 0.85)
          ..strokeWidth = 2.2
          ..strokeCap = StrokeCap.round,
      );
    }
    canvas.drawCircle(sunCenter, 9, Paint()..color = sun);

    final panelPath = Path()
      ..moveTo(size.width * 0.08, size.height * 0.62)
      ..lineTo(size.width * 0.92, size.height * 0.56)
      ..lineTo(size.width * 0.86, size.height * 0.9)
      ..lineTo(size.width * 0.02, size.height * 0.96)
      ..close();
    canvas.drawPath(panelPath, Paint()..color = panel);

    canvas.save();
    canvas.clipPath(panelPath);
    final sweep = size.width * progress;
    canvas.drawRect(
      Rect.fromLTWH(sweep - 28, 0, 36, size.height),
      Paint()..color = sun.withValues(alpha: 0.38),
    );
    canvas.restore();

    final gridPaint = Paint()
      ..color = line.withValues(alpha: 0.45)
      ..strokeWidth = 1;
    for (var index = 1; index < 4; index++) {
      final fraction = index / 4;
      canvas.drawLine(
        Offset(
          _lerp(size.width * 0.08, size.width * 0.92, fraction),
          _lerp(size.height * 0.62, size.height * 0.56, fraction),
        ),
        Offset(
          _lerp(size.width * 0.02, size.width * 0.86, fraction),
          _lerp(size.height * 0.96, size.height * 0.9, fraction),
        ),
        gridPaint,
      );
    }
    canvas.drawLine(
      Offset(size.width * 0.05, size.height * 0.78),
      Offset(size.width * 0.89, size.height * 0.73),
      gridPaint,
    );
  }

  double _lerp(double start, double end, double fraction) {
    return start + ((end - start) * fraction);
  }

  @override
  bool shouldRepaint(covariant _SunLoaderPainter oldDelegate) {
    return progress != oldDelegate.progress ||
        sun != oldDelegate.sun ||
        panel != oldDelegate.panel ||
        line != oldDelegate.line;
  }
}
