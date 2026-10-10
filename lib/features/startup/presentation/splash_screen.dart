import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:solar_ui/core/theme/app_layout.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({
    required this.destinationBuilder,
    this.startupDuration = const Duration(milliseconds: 1900),
    super.key,
  });

  final WidgetBuilder destinationBuilder;
  final Duration startupDuration;

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  Timer? _navigationTimer;
  bool _started = false;
  bool _navigated = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1250),
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
      _controller.value = 1;
    } else {
      _controller.forward();
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
            : const Duration(milliseconds: 420),
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
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
        systemNavigationBarColor: theme.scaffoldBackgroundColor,
        systemNavigationBarIconBrightness: isDark
            ? Brightness.light
            : Brightness.dark,
      ),
      child: Scaffold(
        body: SafeArea(
          child: Stack(
            children: [
              Positioned.fill(child: _SplashBackground(animation: _controller)),
              Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(AppSpacing.xl),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 460),
                    child: AnimatedBuilder(
                      animation: _controller,
                      builder: (context, child) {
                        final reveal = Curves.easeOutCubic.transform(
                          (_controller.value / 0.72).clamp(0, 1),
                        );
                        final detailReveal = Curves.easeOut.transform(
                          ((_controller.value - 0.35) / 0.65).clamp(0, 1),
                        );

                        return Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Opacity(
                              opacity: reveal,
                              child: Transform.scale(
                                scale: 0.86 + (0.14 * reveal),
                                child: _AnimatedSolarMark(
                                  progress: _controller.value,
                                ),
                              ),
                            ),
                            const SizedBox(height: AppSpacing.xl),
                            Opacity(
                              opacity: detailReveal,
                              child: Transform.translate(
                                offset: Offset(0, 12 * (1 - detailReveal)),
                                child: Column(
                                  children: [
                                    Text(
                                      'Solar',
                                      style: theme.textTheme.displaySmall
                                          ?.copyWith(
                                            fontWeight: FontWeight.w800,
                                            color: colorScheme.onSurface,
                                          ),
                                    ),
                                    const SizedBox(height: AppSpacing.xs),
                                    Text(
                                      'Solar Service Management',
                                      textAlign: TextAlign.center,
                                      style: theme.textTheme.titleMedium
                                          ?.copyWith(
                                            color: colorScheme.onSurfaceVariant,
                                            fontWeight: FontWeight.w600,
                                          ),
                                    ),
                                    const SizedBox(height: AppSpacing.xxl),
                                    Semantics(
                                      label: 'Preparing your workspace',
                                      liveRegion: true,
                                      child: Column(
                                        children: [
                                          ClipRRect(
                                            borderRadius: BorderRadius.circular(
                                              AppRadii.pill,
                                            ),
                                            child: LinearProgressIndicator(
                                              value: _controller.value,
                                              minHeight: 4,
                                            ),
                                          ),
                                          const SizedBox(height: AppSpacing.sm),
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
            ],
          ),
        ),
      ),
    );
  }
}

class _SplashBackground extends StatelessWidget {
  const _SplashBackground({required this.animation});

  final Animation<double> animation;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        return DecoratedBox(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: const Alignment(0.65, -0.7),
              radius: 1.15,
              colors: [
                colorScheme.primary.withValues(
                  alpha: 0.12 + (animation.value * 0.05),
                ),
                Theme.of(context).scaffoldBackgroundColor,
                Theme.of(context).scaffoldBackgroundColor,
              ],
              stops: const [0, 0.48, 1],
            ),
          ),
          child: CustomPaint(
            painter: _OrbitBackgroundPainter(
              progress: animation.value,
              color: colorScheme.primary,
              lineColor: colorScheme.outlineVariant,
            ),
          ),
        );
      },
    );
  }
}

class _AnimatedSolarMark extends StatelessWidget {
  const _AnimatedSolarMark({required this.progress});

  final double progress;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return SizedBox.square(
      dimension: 150,
      child: CustomPaint(
        painter: _SolarMarkPainter(
          progress: progress,
          primary: colorScheme.primary,
          onPrimary: colorScheme.onPrimary,
          panelColor: colorScheme.secondary,
          panelLine: colorScheme.onSecondary.withValues(alpha: 0.68),
        ),
      ),
    );
  }
}

class _SolarMarkPainter extends CustomPainter {
  const _SolarMarkPainter({
    required this.progress,
    required this.primary,
    required this.onPrimary,
    required this.panelColor,
    required this.panelLine,
  });

  final double progress;
  final Color primary;
  final Color onPrimary;
  final Color panelColor;
  final Color panelLine;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height * 0.42);
    final rayPaint = Paint()
      ..color = primary.withValues(alpha: 0.62 * progress)
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    for (var index = 0; index < 12; index++) {
      final angle = ((math.pi * 2) / 12 * index) + (progress * 0.12);
      final inner = Offset(
        center.dx + math.cos(angle) * 43,
        center.dy + math.sin(angle) * 43,
      );
      final outer = Offset(
        center.dx + math.cos(angle) * 52,
        center.dy + math.sin(angle) * 52,
      );
      canvas.drawLine(inner, outer, rayPaint);
    }

    canvas.drawCircle(
      center,
      34,
      Paint()
        ..shader = RadialGradient(
          colors: [primary, primary.withValues(alpha: 0.78)],
        ).createShader(Rect.fromCircle(center: center, radius: 34)),
    );
    canvas.drawCircle(center, 8, Paint()..color = onPrimary);

    final panelTop = size.height * 0.63;
    final panelPath = Path()
      ..moveTo(size.width * 0.24, panelTop)
      ..lineTo(size.width * 0.76, panelTop)
      ..lineTo(size.width * 0.84, size.height * 0.9)
      ..lineTo(size.width * 0.16, size.height * 0.9)
      ..close();
    canvas.drawPath(panelPath, Paint()..color = panelColor);
    canvas.drawPath(
      panelPath,
      Paint()
        ..color = panelLine
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );

    for (var index = 1; index < 4; index++) {
      final x = size.width * (0.24 + (0.13 * index));
      canvas.drawLine(
        Offset(x, panelTop),
        Offset(size.width * (0.16 + (0.17 * index)), size.height * 0.9),
        Paint()
          ..color = panelLine
          ..strokeWidth = 1,
      );
    }
    canvas.drawLine(
      Offset(size.width * 0.2, size.height * 0.765),
      Offset(size.width * 0.8, size.height * 0.765),
      Paint()
        ..color = panelLine
        ..strokeWidth = 1,
    );
  }

  @override
  bool shouldRepaint(covariant _SolarMarkPainter oldDelegate) {
    return progress != oldDelegate.progress ||
        primary != oldDelegate.primary ||
        onPrimary != oldDelegate.onPrimary ||
        panelColor != oldDelegate.panelColor ||
        panelLine != oldDelegate.panelLine;
  }
}

class _OrbitBackgroundPainter extends CustomPainter {
  const _OrbitBackgroundPainter({
    required this.progress,
    required this.color,
    required this.lineColor,
  });

  final double progress;
  final Color color;
  final Color lineColor;

  @override
  void paint(Canvas canvas, Size size) {
    final orbitPaint = Paint()
      ..color = lineColor.withValues(alpha: 0.38)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    final center = Offset(size.width * 0.76, size.height * 0.3);
    final radius = math.min(size.width, size.height) * 0.25;
    canvas.drawCircle(center, radius, orbitPaint);
    canvas.drawCircle(center, radius * 1.45, orbitPaint);

    final angle = progress * math.pi * 1.2;
    final satellite = Offset(
      center.dx + math.cos(angle) * radius,
      center.dy + math.sin(angle) * radius,
    );
    canvas.drawCircle(
      satellite,
      5,
      Paint()..color = color.withValues(alpha: 0.7),
    );
  }

  @override
  bool shouldRepaint(covariant _OrbitBackgroundPainter oldDelegate) {
    return progress != oldDelegate.progress ||
        color != oldDelegate.color ||
        lineColor != oldDelegate.lineColor;
  }
}
