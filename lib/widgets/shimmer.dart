import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../design_system.dart';

class ShimmerBox extends StatefulWidget {
  final double height, width, radius;
  const ShimmerBox({super.key, this.height = 16, this.width = double.infinity, this.radius = DS.rMd});
  @override
  State<ShimmerBox> createState() => _ShimmerBoxState();
}

class _ShimmerBoxState extends State<ShimmerBox> with SingleTickerProviderStateMixin {
  late AnimationController _c;
  late Animation<Offset> _a;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1500))..repeat();
    _a = Tween<Offset>(begin: const Offset(-0.5, 0), end: const Offset(1.5, 0)).animate(CurvedAnimation(parent: _c, curve: Curves.easeInOutSine));
  }

  @override
  void dispose() { _c.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final d = DS.isDark(context);
    final base = d ? DS.darkCard : const Color(0xFFE8E8F0);
    final hl = d ? DS.darkBorder : const Color(0xFFF0F0F8);
    return ClipRRect(
      borderRadius: BorderRadius.circular(widget.radius),
      child: Container(height: widget.height, width: widget.width, color: base, child: AnimatedBuilder(
        animation: _a,
        builder: (c, _) => FractionalTranslation(translation: _a.value, child: Container(width: 80, color: hl)),
      )),
    );
  }
}

class ShimmerList extends StatelessWidget {
  final int count;
  final double itemHeight;
  const ShimmerList({super.key, this.count = 4, this.itemHeight = 120});
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        var visible = count;
        if (constraints.hasBoundedHeight) {
          final unit = itemHeight + DS.md;
          visible = math.max(1, math.min(count, ((constraints.maxHeight + DS.md) / unit).floor()));
        }
        return SingleChildScrollView(
          physics: const NeverScrollableScrollPhysics(),
          child: Column(children: List.generate(visible, (i) => Padding(
            padding: EdgeInsets.only(bottom: i < visible - 1 ? DS.md : 0),
            child: ShimmerBox(height: itemHeight, radius: DS.rXl),
          ))),
        );
      },
    );
  }
}

class ShimmerShopCard extends StatelessWidget {
  const ShimmerShopCard({super.key});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: DS.md),
    child: ShimmerBox(height: 280, radius: DS.rXl),
  );
}

class ShimmerStatsRow extends StatelessWidget {
  final int count;
  const ShimmerStatsRow({super.key, this.count = 4});
  @override
  Widget build(BuildContext context) => Row(children: List.generate(count, (i) => Expanded(child: Padding(
    padding: EdgeInsets.only(left: i > 0 ? DS.sm : 0),
    child: ShimmerBox(height: 80, radius: DS.rLg),
  ))));
}
