import 'dart:ui';
import 'package:flutter/material.dart';

class GlassContainer extends StatefulWidget {
  const GlassContainer({
    super.key,
    required this.child,
    this.radius = 24,
    this.padding = const EdgeInsets.all(16),
    this.margin,
    this.blur = 28,
    this.opacity = 0.07,
    this.tint,
    this.glow,
    this.onTap,
  });

  final Widget child;
  final double radius;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final double blur;
  final double opacity;
  final Color? tint;
  final Color? glow;
  final VoidCallback? onTap;

  @override
  State<GlassContainer> createState() => _GlassContainerState();
}

class _GlassContainerState extends State<GlassContainer> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    final r = BorderRadius.circular(widget.radius);
    final base = widget.tint ?? Colors.white;

    final body = Container(
      margin: widget.margin,
      decoration: BoxDecoration(
        borderRadius: r,
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.22),
              blurRadius: 26,
              offset: const Offset(0, 10)),
          if (widget.glow != null)
            BoxShadow(
                color: widget.glow!.withOpacity(0.35),
                blurRadius: 30,
                spreadRadius: -4),
        ],
      ),
      child: ClipRRect(
        borderRadius: r,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: widget.blur, sigmaY: widget.blur),
          child: CustomPaint(
            foregroundPainter: _GlassEdge(widget.radius),
            child: Container(
              padding: widget.padding,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    base.withOpacity(widget.opacity + 0.09),
                    base.withOpacity(widget.opacity),
                  ],
                ),
              ),
              child: widget.child,
            ),
          ),
        ),
      ),
    );

    if (widget.onTap == null) return body;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => setState(() => _down = true),
      onTapUp: (_) => setState(() => _down = false),
      onTapCancel: () => setState(() => _down = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _down ? 0.965 : 1,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: body,
      ),
    );
  }
}

class _GlassEdge extends CustomPainter {
  _GlassEdge(this.radius);
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final rr = RRect.fromRectAndRadius(rect.deflate(0.6), Radius.circular(radius));

    // upar ki chamak (specular sheen)
    final sheen = Rect.fromLTWH(0, 0, size.width, size.height * 0.5);
    canvas.save();
    canvas.clipRRect(rr);
    canvas.drawRect(
      sheen,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.white.withOpacity(0.10), Colors.white.withOpacity(0)],
        ).createShader(sheen),
    );
    canvas.restore();

    // chamakta hua kinara
    canvas.drawRRect(
      rr,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withOpacity(0.55),
            Colors.white.withOpacity(0.06),
            Colors.white.withOpacity(0.02),
            Colors.white.withOpacity(0.28),
          ],
          stops: const [0, 0.35, 0.7, 1],
        ).createShader(rect),
    );
  }

  @override
  bool shouldRepaint(_GlassEdge old) => old.radius != radius;
}