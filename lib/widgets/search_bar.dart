import 'package:flutter/material.dart';
import '../design_system.dart';

class AnimatedSearchBar extends StatefulWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback? onTap;

  const AnimatedSearchBar({super.key, required this.controller, required this.onChanged, this.onTap});

  @override
  State<AnimatedSearchBar> createState() => _AnimatedSearchBarState();
}

class _AnimatedSearchBarState extends State<AnimatedSearchBar> with SingleTickerProviderStateMixin {
  late AnimationController _c;
  bool _focused = false;

  @override
  void initState() { super.initState(); _c = AnimationController(vsync: this, duration: DS.fast); }

  @override
  void dispose() { _c.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final d = DS.isDark(context);
    return GestureDetector(
      onTap: widget.onTap,
      child: AnimatedContainer(
        duration: DS.med,
        height: 52,
        decoration: BoxDecoration(
          color: d ? DS.darkCard : Colors.white,
          borderRadius: BorderRadius.circular(DS.rLg),
          border: Border.all(color: _focused ? DS.primary.withValues(alpha: 0.5) : DS.borderC(context).withValues(alpha: 0.5)),
          boxShadow: d ? null : [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 12, offset: const Offset(0, 4))],
        ),
        child: TextField(
          controller: widget.controller,
          onChanged: widget.onChanged,
          onTap: () => setState(() => _focused = true),
          onSubmitted: (_) => setState(() => _focused = false),
          style: TextStyle(fontSize: 15, color: DS.inkC(context), fontWeight: FontWeight.w500),
          decoration: InputDecoration(
            hintText: 'Search salons...',
            hintStyle: TextStyle(color: DS.mutedC(context)),
            prefixIcon: Icon(Icons.search_rounded, color: DS.mutedC(context)),
            suffixIcon: widget.controller.text.isNotEmpty
                ? IconButton(icon: Icon(Icons.close_rounded, size: 20, color: DS.mutedC(context)), onPressed: () { widget.controller.clear(); widget.onChanged(''); setState(() {}); })
                : null,
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(vertical: 14),
          ),
        ),
      ),
    );
  }
}
