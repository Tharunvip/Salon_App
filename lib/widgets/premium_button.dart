import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../design_system.dart';

class PButton extends StatefulWidget {
  final String text;
  final IconData? icon;
  final VoidCallback? onPressed;
  final bool loading, expanded, isGold, isOutlined;
  final bool shimmer;
  final double height;
  final double? horizontalPadding;

  const PButton({
    super.key, required this.text, this.icon, this.onPressed,
    this.loading = false, this.expanded = true,
    this.isGold = false, this.isOutlined = false,
    this.shimmer = false,
    this.height = 52,
    this.horizontalPadding,
  });

  @override
  State<PButton> createState() => _PButtonState();
}

class _PButtonState extends State<PButton> with TickerProviderStateMixin {
  late AnimationController _c;
  late AnimationController _shimmerC;
  late AnimationController _spinC;
  late Animation<double> _scale;
  bool _pressed = false;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: DS.fast);
    _scale = Tween<double>(begin: 1, end: 0.96).animate(CurvedAnimation(parent: _c, curve: DS.easeOut));
    _shimmerC = AnimationController(vsync: this, duration: const Duration(milliseconds: 1600))..repeat(reverse: true);
    _spinC = AnimationController(vsync: this, duration: const Duration(milliseconds: 1100))..repeat();
  }
  @override
  void dispose() { _c.dispose(); _shimmerC.dispose(); _spinC.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final gradient = widget.isGold ? DS.gradientGold : DS.gradientPrimary;
    final isDisabled = widget.onPressed == null || widget.loading;

    return LayoutBuilder(
      builder: (context, constraints) {
        final fill = widget.expanded && constraints.maxWidth.isFinite;
        return SizedBox(
          height: widget.height,
          width: fill ? double.infinity : null,
          child: AnimatedBuilder(
            animation: _scale,
            builder: (c, _) => Transform.scale(
              scale: _scale.value,
              child: GestureDetector(
                onTapDown: isDisabled ? null : (_) { _c.forward(); _pressed = true; },
                onTapUp: isDisabled ? null : (_) { if (_pressed) { _c.reverse(); _pressed = false; widget.onPressed!(); } },
                onTapCancel: () { if (_pressed) { _c.reverse(); _pressed = false; } },
                child: AnimatedContainer(
                  duration: DS.fast,
                  decoration: BoxDecoration(
                    gradient: widget.isOutlined ? null : (isDisabled ? const LinearGradient(colors: [Color(0xFFD1D5DB), Color(0xFF9CA3AF)]) : gradient),
                    borderRadius: BorderRadius.circular(DS.rLg),
                    border: widget.isOutlined ? Border.all(color: widget.isGold ? DS.accent : DS.primary, width: 1.5) : null,
                    boxShadow: isDisabled ? null : (widget.isOutlined ? null : [(widget.isGold ? DS.shadowGold : DS.shadowPrimary)]),
                    color: widget.isOutlined ? Colors.transparent : null,
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(DS.rLg),
                    child: Stack(
                      fit: fill ? StackFit.expand : StackFit.loose,
                      children: [
                        if (widget.shimmer && fill && !isDisabled && !widget.isOutlined) _shimmerOverlay(),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: widget.horizontalPadding ?? 28),
                          child: _content(fill),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _shimmerOverlay() {
    return AnimatedBuilder(
      animation: _shimmerC,
      builder: (c, _) {
        final t = _shimmerC.value;
        return Align(
          alignment: Alignment(-1.6 + 3.2 * t, 0),
          child: FractionallySizedBox(
            widthFactor: 0.35,
            heightFactor: 1,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.transparent,
                    Colors.white.withValues(alpha: widget.isGold ? 0.35 : 0.18),
                    Colors.transparent,
                  ],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _content(bool fill) {
    if (widget.loading) {
      return Center(
        child: AnimatedBuilder(
          animation: _spinC,
          builder: (c, _) => CustomPaint(
            size: const Size(34, 20),
            painter: _ArcLoaderPainter(
              progress: _spinC.value,
              a: widget.isGold ? Colors.white : DS.gold,
              b: widget.isGold ? const Color(0xFFFFD75E) : DS.teal,
            ),
          ),
        ),
      );
    }
    final c = widget.isOutlined ? (widget.isGold ? DS.accent : DS.primary) : Colors.white;
    return Row(
      mainAxisSize: fill ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (widget.icon != null) ...[Icon(widget.icon, color: c, size: 20), const SizedBox(width: 10)],
        Flexible(child: Text(widget.text, overflow: TextOverflow.ellipsis, style: TextStyle(color: c, fontSize: 15, fontWeight: FontWeight.w700, letterSpacing: 0.3))),
      ],
    );
  }
}

class _ArcLoaderPainter extends CustomPainter {
  final double progress;
  final Color a;
  final Color b;

  _ArcLoaderPainter({required this.progress, required this.a, required this.b});

  @override
  void paint(Canvas canvas, Size size) {
    final rect = (Offset.zero & size).deflate(1.5);
    final base = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..color = a.withValues(alpha: 0.16);
    canvas.drawOval(rect, base);

    final sweep = math.pi * 1.3;
    final arc1 = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round
      ..color = a;
    final arc2 = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round
      ..color = b;
    canvas.drawArc(rect, progress * 2 * math.pi, sweep, false, arc1);
    canvas.drawArc(rect, (progress + 0.5) * 2 * math.pi, sweep, false, arc2);
  }

  @override
  bool shouldRepaint(covariant _ArcLoaderPainter old) => old.progress != progress || old.a != a || old.b != b;
}

class ActionChipBtn extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback? onTap;
  final Color? color;

  const ActionChipBtn({super.key, required this.label, required this.icon, this.onTap, this.color});

  @override
  Widget build(BuildContext context) {
    final c = color ?? DS.primary;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(DS.rFull),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(DS.rFull),
            border: Border.all(color: c.withValues(alpha: 0.3)),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(icon, size: 16, color: c),
            const SizedBox(width: 6),
            Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: c)),
          ]),
        ),
      ),
    );
  }
}
