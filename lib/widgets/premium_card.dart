import 'package:flutter/material.dart';
import '../design_system.dart';

class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding, margin;
  final VoidCallback? onTap;
  final Color? tint;
  final double radius;

  const GlassCard({super.key, required this.child, this.padding, this.margin, this.onTap, this.tint, this.radius = DS.rXxl});

  @override
  Widget build(BuildContext context) {
    final d = DS.isDark(context);
    return AnimatedContainer(
      duration: DS.fast,
      width: double.infinity,
      margin: margin ?? EdgeInsets.zero,
      padding: padding ?? const EdgeInsets.all(DS.lg),
      decoration: BoxDecoration(
        color: tint?.withValues(alpha: d ? 0.08 : 0.06) ?? (d ? const Color(0xCC16213E) : const Color(0xD9FFFFFF)),
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: tint?.withValues(alpha: d ? 0.15 : 0.12) ?? (d ? const Color(0x4D2A2A4A) : const Color(0x26FFFFFF))),
        boxShadow: d ? null : DS.shadowGlass,
      ),
      child: onTap != null
          ? Material(color: Colors.transparent, child: InkWell(onTap: onTap, borderRadius: BorderRadius.circular(radius), child: child))
          : child,
    );
  }
}

class PremiumCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding, margin;
  final VoidCallback? onTap;
  final double radius;
  final List<BoxShadow>? shadows;
  final Color? borderColor;

  const PremiumCard({super.key, required this.child, this.padding, this.margin, this.onTap, this.radius = DS.rXl, this.shadows, this.borderColor});

  @override
  Widget build(BuildContext context) {
    final d = DS.isDark(context);
    return AnimatedContainer(
      duration: DS.fast,
      width: double.infinity,
      margin: margin ?? EdgeInsets.zero,
      padding: padding ?? const EdgeInsets.all(DS.md),
      decoration: BoxDecoration(
        color: DS.surfaceC(context),
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: borderColor ?? DS.borderC(context).withValues(alpha: 0.5)),
        boxShadow: shadows ?? (d ? [DS.shadowSm] : DS.shadowCard),
      ),
      child: onTap != null
          ? Material(color: Colors.transparent, child: InkWell(onTap: onTap, borderRadius: BorderRadius.circular(radius), child: child))
          : child,
    );
  }
}

class GradientCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding, margin;
  final Gradient gradient;
  final double radius;

  const GradientCard({super.key, required this.child, this.padding, this.margin, required this.gradient, this.radius = DS.rXl});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: margin ?? EdgeInsets.zero,
      padding: padding ?? const EdgeInsets.all(DS.lg),
      decoration: BoxDecoration(gradient: gradient, borderRadius: BorderRadius.circular(radius), boxShadow: DS.shadowElevated),
      child: child,
    );
  }
}

class AnimatedCard extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final double radius;
  final EdgeInsetsGeometry? margin;
  final Color? borderColor;

  const AnimatedCard({super.key, required this.child, this.onTap, this.radius = DS.rXl, this.margin, this.borderColor});

  @override
  State<AnimatedCard> createState() => _AnimatedCardState();
}

class _AnimatedCardState extends State<AnimatedCard> with SingleTickerProviderStateMixin {
  late AnimationController _c;
  late Animation<double> _scale;
  bool _pressed = false;

  @override
  void initState() { super.initState(); _c = AnimationController(vsync: this, duration: DS.fast); _scale = Tween<double>(begin: 1, end: 0.97).animate(CurvedAnimation(parent: _c, curve: DS.easeOut)); }

  @override
  void dispose() { _c.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final d = DS.isDark(context);
    return AnimatedBuilder(
      animation: _scale,
      builder: (c, _) => Transform.scale(
        scale: _scale.value,
        child: GestureDetector(
          onTapDown: widget.onTap != null ? (_) { _c.forward(); _pressed = true; } : null,
          onTapUp: widget.onTap != null ? (_) { if (_pressed) _c.reverse(); _pressed = false; widget.onTap!(); } : null,
          onTapCancel: () { if (_pressed) { _c.reverse(); _pressed = false; } },
          child: AnimatedContainer(
            duration: DS.fast,
            margin: widget.margin ?? EdgeInsets.zero,
            decoration: BoxDecoration(
              color: DS.surfaceC(context),
              borderRadius: BorderRadius.circular(widget.radius),
              border: Border.all(color: widget.borderColor ?? DS.borderC(context).withValues(alpha: 0.5)),
              boxShadow: d ? [DS.shadowSm] : DS.shadowCard,
            ),
            child: ClipRRect(borderRadius: BorderRadius.circular(widget.radius), child: widget.child),
          ),
        ),
      ),
    );
  }
}
