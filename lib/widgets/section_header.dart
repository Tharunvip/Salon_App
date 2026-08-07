import 'package:flutter/material.dart';
import '../design_system.dart';

class SectionHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final IconData? icon;
  final Widget? trailing;
  final VoidCallback? onSeeAll;

  const SectionHeader({super.key, required this.title, this.subtitle, this.icon, this.trailing, this.onSeeAll});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: DS.md),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        if (icon != null) ...[
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: DS.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(DS.rMd)),
            child: Icon(icon, color: DS.primary, size: 20),
          ),
          const SizedBox(width: 14),
        ],
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: TextStyle(fontSize: 18, color: DS.inkC(context), fontWeight: FontWeight.w800, letterSpacing: -0.3)),
            if (subtitle != null) ...[const SizedBox(height: 3), Text(subtitle!, style: TextStyle(color: DS.mutedC(context), fontSize: 13))],
          ]),
        ),
        ?trailing,
        if (onSeeAll != null)
          GestureDetector(
            onTap: onSeeAll,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(color: DS.primary.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(DS.rFull)),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Text('See All', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: DS.primary)),
                const SizedBox(width: 4),
                Icon(Icons.arrow_forward_ios, size: 10, color: DS.primary),
              ]),
            ),
          ),
      ]),
    );
  }
}
