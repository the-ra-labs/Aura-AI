import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';

class AuroraBackground extends StatefulWidget {
  const AuroraBackground({super.key, required this.child});
  final Widget child;

  @override
  State<AuroraBackground> createState() => _AuroraBackgroundState();
}

class _AuroraBackgroundState extends State<AuroraBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(seconds: 40))
        ..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  Widget _blob(Color c, double size, Alignment a, double o) => Align(
        alignment: a,
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(colors: [c.withOpacity(o), c.withOpacity(0)]),
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, b) {
      final s = math.max(b.maxWidth, b.maxHeight);
      return Stack(children: [
        const Positioned.fill(child: ColoredBox(color: AppColors.bg)),
        Positioned.fill(
          child: RepaintBoundary(
            child: AnimatedBuilder(
              animation: _c,
              builder: (_, __) {
                final t = _c.value * 2 * math.pi;
                return Stack(children: [
                  _blob(AppColors.violet, s * 0.95,
                      Alignment(-0.9 + 0.25 * math.sin(t), -0.8 + 0.2 * math.cos(t)), 0.50),
                  _blob(AppColors.cyan, s * 0.70,
                      Alignment(1.0 - 0.25 * math.cos(t), -0.1 + 0.3 * math.sin(t)), 0.30),
                  _blob(AppColors.pink, s * 0.75,
                      Alignment(0.1 + 0.4 * math.sin(t + 1), 1.0 - 0.15 * math.cos(t)), 0.28),
                  _blob(AppColors.gold, s * 0.45,
                      Alignment(0.8 + 0.1 * math.sin(t + 2), -0.95), 0.18),
                  CustomPaint(size: Size.infinite, painter: _Stars(_c.value)),
                ]);
              },
            ),
          ),
        ),
        // kinare halke dark (vignette)
        Positioned.fill(
          child: IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  radius: 1.15,
                  colors: [Colors.transparent, Colors.black.withOpacity(0.45)],
                  stops: const [0.55, 1],
                ),
              ),
            ),
          ),
        ),
        widget.child,
      ]);
    });
  }
}

class _Stars extends CustomPainter {
  _Stars(this.t);
  final double t;

  static final _pts = () {
    final r = math.Random(7);
    return List.generate(
        90,
        (_) => (r.nextDouble(), r.nextDouble(), r.nextDouble() * 1.1 + 0.3,
            r.nextDouble()));
  }();

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint();
    for (final s in _pts) {
      final o = 0.15 + 0.45 * (0.5 + 0.5 * math.sin(2 * math.pi * (t * 3 + s.$4)));
      p.color = Colors.white.withOpacity(o);
      canvas.drawCircle(Offset(s.$1 * size.width, s.$2 * size.height), s.$3, p);
    }
  }

  @override
  bool shouldRepaint(_Stars old) => true;
}