import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';

class GradientButton extends StatefulWidget {
  const GradientButton({
    super.key,
    required this.label,
    this.icon,
    this.onTap,
    this.expand = true,
    this.loading = false,
    this.gradient = AppColors.brand,
  });
  final String label;
  final IconData? icon;
  final VoidCallback? onTap;
  final bool expand, loading;
  final Gradient gradient;

  @override
  State<GradientButton> createState() => _GradientButtonState();
}

class _GradientButtonState extends State<GradientButton> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onTap != null && !widget.loading;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: enabled ? (_) => setState(() => _down = true) : null,
      onTapUp: enabled ? (_) => setState(() => _down = false) : null,
      onTapCancel: () => setState(() => _down = false),
      onTap: enabled ? widget.onTap : null,
      child: AnimatedScale(
        scale: _down ? 0.96 : 1,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: AnimatedOpacity(
          opacity: enabled ? 1 : 0.55,
          duration: const Duration(milliseconds: 200),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 22),
            decoration: BoxDecoration(
              gradient: widget.gradient,
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                    color: AppColors.violet.withOpacity(0.45),
                    blurRadius: 22,
                    offset: const Offset(0, 8)),
              ],
            ),
            child: Row(
              mainAxisSize: widget.expand ? MainAxisSize.max : MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (widget.loading)
                  const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                else ...[
                  if (widget.icon != null) ...[
                    Icon(widget.icon, size: 20, color: Colors.white),
                    const SizedBox(width: 8),
                  ],
                  Text(widget.label,
                      style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                          color: Colors.white)),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class GlassIconButton extends StatefulWidget {
  const GlassIconButton({
    super.key,
    required this.icon,
    this.onTap,
    this.tooltip,
    this.filled = false,
    this.size = 42,
  });
  final IconData icon;
  final VoidCallback? onTap;
  final String? tooltip;
  final bool filled;
  final double size;

  @override
  State<GlassIconButton> createState() => _GlassIconButtonState();
}

class _GlassIconButtonState extends State<GlassIconButton> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    final visual = Container(
      width: widget.size,
      height: widget.size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: widget.filled ? AppColors.brand : null,
        color: widget.filled ? null : Colors.white.withOpacity(0.08),
        border: Border.all(color: Colors.white.withOpacity(0.14)),
        boxShadow: widget.filled
            ? [
                BoxShadow(
                    color: AppColors.violet.withOpacity(0.5),
                    blurRadius: 16,
                    offset: const Offset(0, 5))
              ]
            : null,
      ),
      child: Icon(widget.icon, size: 20, color: Colors.white),
    );

    // onTap null ho to (jaise PopupMenuButton ka child) sirf visual
    if (widget.onTap == null) return visual;

    Widget w = GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => setState(() => _down = true),
      onTapUp: (_) => setState(() => _down = false),
      onTapCancel: () => setState(() => _down = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _down ? 0.88 : 1,
        duration: const Duration(milliseconds: 110),
        child: visual,
      ),
    );
    if (widget.tooltip != null) w = Tooltip(message: widget.tooltip!, child: w);
    return w;
  }
}