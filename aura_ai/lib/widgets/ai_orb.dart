import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';

/// Beech mein sun, 3 gol orbits, un par planets (earth moon ke saath).
class AiOrb extends StatefulWidget {
  const AiOrb({super.key, this.size = 200, this.active = false});
  final double size;
  final bool active;

  @override
  State<AiOrb> createState() => _AiOrbState();
}

class _AiOrbState extends State<AiOrb> with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(seconds: 24))
        ..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _c,
        builder: (_, __) => CustomPaint(
          size: Size.square(widget.size),
          painter: OrbPainter(_c.value, widget.active),
        ),
      ),
    );
  }
}

class OrbPainter extends CustomPainter {
  OrbPainter(this.t, this.active);
  final double t;
  final bool active;

  void _sphere(Canvas canvas, Offset p, double r, List<Color> cols, {Color? glow}) {
    if (glow != null) {
      canvas.drawCircle(
        p,
        r * 2.6,
        Paint()
          ..shader = RadialGradient(
                  colors: [glow.withOpacity(0.45), glow.withOpacity(0)])
              .createShader(Rect.fromCircle(center: p, radius: r * 2.6)),
      );
    }
    canvas.drawCircle(
      p,
      r,
      Paint()
        ..shader = RadialGradient(
                center: const Alignment(-0.4, -0.4), radius: 1.1, colors: cols)
            .createShader(Rect.fromCircle(center: p, radius: r)),
    );
  }

  Offset _planet(Canvas canvas, Offset c, double orbit, int rev, double phase,
      double r, List<Color> cols, Color glow) {
    final angle = 2 * math.pi * (t * rev) + phase;
    final s = rev >= 0 ? 1.0 : -1.0;
    final rect = Rect.fromCircle(center: c, radius: orbit);
    for (var i = 0; i < 14; i++) {
      canvas.drawArc(
        rect,
        angle - s * (i + 1) * 0.05,
        s * 0.05,
        false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeWidth = r * 0.9 * (1 - i / 20)
          ..color = glow.withOpacity(0.55 * (1 - i / 14)),
      );
    }
    final pos = c + Offset(math.cos(angle), math.sin(angle)) * orbit;
    _sphere(canvas, pos, r, cols, glow: glow);
    return pos;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final R = size.width / 2;
    final a = active ? 1.0 : 0.75;
    final beat = math.sin(t * 2 * math.pi * 24);

    // bahar ka halo
    canvas.drawCircle(
      c,
      R,
      Paint()
        ..shader = RadialGradient(
          colors: [
            AppColors.violet.withOpacity(0.30 * a),
            AppColors.cyan.withOpacity(0.07 * a),
            Colors.transparent,
          ],
          stops: const [0, 0.6, 1],
        ).createShader(Rect.fromCircle(center: c, radius: R)),
    );

    // gol orbits
    for (final f in const [0.50, 0.73, 0.96]) {
      final r = R * f;
      canvas.drawCircle(
        c,
        r,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1
          ..shader = SweepGradient(colors: [
            Colors.white.withOpacity(0.03),
            Colors.white.withOpacity(0.28),
            Colors.white.withOpacity(0.03),
            Colors.white.withOpacity(0.20),
            Colors.white.withOpacity(0.03),
          ]).createShader(Rect.fromCircle(center: c, radius: r)),
      );
    }

    // sun
    final coreR = R * 0.26 * (1 + (active ? 0.05 : 0.02) * beat);
    canvas.drawCircle(
      c,
      coreR * 3,
      Paint()
        ..shader = RadialGradient(
          colors: [
            AppColors.gold.withOpacity(0.55 * a),
            AppColors.pink.withOpacity(0.18 * a),
            Colors.transparent,
          ],
          stops: const [0, 0.5, 1],
        ).createShader(Rect.fromCircle(center: c, radius: coreR * 3)),
    );
    canvas.drawCircle(
      c,
      coreR,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.3, -0.35),
          radius: 1.0,
          colors: const [
            Color(0xFFFFF6D6),
            Color(0xFFFFC15E),
            Color(0xFFFF6A3D),
            Color(0xFF8A2A5C),
          ],
          stops: const [0, 0.35, 0.75, 1],
        ).createShader(Rect.fromCircle(center: c, radius: coreR)),
    );
    canvas.save();
    canvas.translate(c.dx, c.dy);
    canvas.rotate(t * 2 * math.pi * 2);
    canvas.drawCircle(
      Offset.zero,
      coreR,
      Paint()
        ..shader = SweepGradient(colors: [
          Colors.white.withOpacity(0),
          Colors.white.withOpacity(0.25),
          Colors.white.withOpacity(0),
          Colors.white.withOpacity(0.14),
          Colors.white.withOpacity(0),
        ]).createShader(Rect.fromCircle(center: Offset.zero, radius: coreR)),
    );
    canvas.restore();
    final hp = c + Offset(-coreR * 0.35, -coreR * 0.4);
    canvas.drawCircle(
      hp,
      coreR * 0.3,
      Paint()
        ..shader = RadialGradient(colors: [
          Colors.white.withOpacity(0.55),
          Colors.white.withOpacity(0),
        ]).createShader(Rect.fromCircle(center: hp, radius: coreR * 0.3)),
    );

    // planets
    _planet(canvas, c, R * 0.50, 3, 0.0, R * 0.055,
        const [Color(0xFFFFE2A8), Color(0xFFFFB454), Color(0xFF8A4A12)],
        AppColors.gold);

    final earthR = R * 0.08;
    final earth = _planet(canvas, c, R * 0.73, 2, 2.0, earthR,
        const [Color(0xFFB8F0FF), Color(0xFF2F86FF), Color(0xFF0B1E5C)],
        AppColors.cyan);
    final mAng = t * 2 * math.pi * 12;
    final moon = earth + Offset(math.cos(mAng), math.sin(mAng)) * (earthR * 2.4);
    _sphere(canvas, moon, R * 0.026,
        const [Color(0xFFFFFFFF), Color(0xFFBFC3D9), Color(0xFF50546E)]);

    _planet(canvas, c, R * 0.96, -1, 4.0, R * 0.065,
        const [Color(0xFFE6C8FF), Color(0xFFB36BFF), Color(0xFF3A1670)],
        AppColors.purple);
  }

  @override
  bool shouldRepaint(OrbPainter old) => old.t != t || old.active != active;
}

/// Chhota static brand mark (avatars ke liye, animation nahi, light).
class MiniOrb extends StatelessWidget {
  const MiniOrb({super.key, this.size = 32});
  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(alignment: Alignment.center, children: [
        Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
                color: AppColors.violet.withOpacity(0.7), width: size * 0.05),
          ),
        ),
        Container(
          width: size * 0.62,
          height: size * 0.62,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const RadialGradient(
              center: Alignment(-0.35, -0.4),
              colors: [
                Color(0xFFFFF3C4),
                AppColors.gold,
                Color(0xFFFF6A3D),
                Color(0xFF7A1F5C),
              ],
              stops: [0, 0.3, 0.7, 1],
            ),
            boxShadow: [
              BoxShadow(
                  color: AppColors.gold.withOpacity(0.55), blurRadius: size * 0.4),
            ],
          ),
        ),
      ]),
    );
  }
}

/// AI jawab likhte waqt glowing dots.
class TypingDots extends StatefulWidget {
  const TypingDots({super.key});

  @override
  State<TypingDots> createState() => _TypingDotsState();
}

class _TypingDotsState extends State<TypingDots>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1300))
        ..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (_, __) => Row(mainAxisSize: MainAxisSize.min, children: [
        for (var i = 0; i < 3; i++)
          Builder(builder: (_) {
            final v = (math.sin((_c.value - i * 0.18) * 2 * math.pi) + 1) / 2;
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 3, vertical: 6),
              width: 8 + 3 * v,
              height: 8 + 3 * v,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Color.lerp(AppColors.cyan, AppColors.purple, i / 2)!
                    .withOpacity(0.45 + 0.55 * v),
                boxShadow: [
                  BoxShadow(
                      color: AppColors.violet.withOpacity(0.5 * v), blurRadius: 8)
                ],
              ),
            );
          }),
      ]),
    );
  }
}