import 'package:flutter/material.dart';
import '../design_system.dart';

class PremiumBottomNav extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;
  final List<NavItem> items;

  const PremiumBottomNav({super.key, required this.currentIndex, required this.onTap, this.items = _defaultItems});

  static const _defaultItems = [
    NavItem(icon: Icons.home_outlined, activeIcon: Icons.home_rounded, label: 'Home'),
    NavItem(icon: Icons.calendar_today_outlined, activeIcon: Icons.calendar_today_rounded, label: 'Bookings'),
    NavItem(icon: Icons.notifications_outlined, activeIcon: Icons.notifications_rounded, label: 'Alerts'),
    NavItem(icon: Icons.person_outline, activeIcon: Icons.person_rounded, label: 'Profile'),
  ];

  @override
  Widget build(BuildContext context) {
    final d = DS.isDark(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: d ? DS.darkCard : const Color(0xE6FFFFFF),
        borderRadius: BorderRadius.circular(DS.rXxl),
        boxShadow: [DS.shadowNav, BoxShadow(color: Colors.black.withValues(alpha: d ? 0.2 : 0.04), blurRadius: 20, offset: const Offset(0, 4))],
      ),
      child: Row(
        children: items.asMap().entries.map((e) => Expanded(child: _NavItemWidget(
          item: e.value,
          isSelected: e.key == currentIndex,
          onTap: () => onTap(e.key),
        ))).toList(),
      ),
    );
  }
}

class NavItem {
  final IconData icon, activeIcon;
  final String label;
  final int? badge;
  const NavItem({required this.icon, required this.activeIcon, required this.label, this.badge});
}

class _NavItemWidget extends StatelessWidget {
  final NavItem item;
  final bool isSelected;
  final VoidCallback onTap;

  const _NavItemWidget({required this.item, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: DS.med,
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? DS.primary.withValues(alpha: 0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(DS.rLg),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(isSelected ? item.activeIcon : item.icon, size: 24, color: isSelected ? DS.primary : DS.mutedC(context)),
                if (item.badge != null && item.badge! > 0)
                  Positioned(
                    right: -9, top: -5,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                      constraints: const BoxConstraints(minWidth: 15, minHeight: 15),
                      decoration: BoxDecoration(color: DS.error, borderRadius: BorderRadius.circular(8)),
                      child: Text('${item.badge}', textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.w800)),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Text(item.label, style: TextStyle(fontSize: 10, fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500, color: isSelected ? DS.primary : DS.mutedC(context))),
          ],
        ),
      ),
    );
  }
}

class FloatingAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  final Widget? leading;
  final Widget? titleWidget;
  final bool transparent;

  const FloatingAppBar({super.key, this.title = '', this.actions, this.leading, this.titleWidget, this.transparent = false});

  @override
  Widget build(BuildContext context) {
    final d = DS.isDark(context);
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      decoration: BoxDecoration(
        color: transparent ? Colors.transparent : (d ? DS.darkCard.withValues(alpha: 0.9) : Colors.white.withValues(alpha: 0.9)),
        borderRadius: BorderRadius.circular(DS.rLg),
        boxShadow: transparent ? null : [BoxShadow(color: Colors.black.withValues(alpha: d ? 0.15 : 0.06), blurRadius: 20, offset: const Offset(0, 4))],
      ),
      child: AppBar(
        title: titleWidget ?? Text(title, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 20, letterSpacing: -0.3, color: DS.inkC(context))),
        actions: actions,
        leading: leading,
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        surfaceTintColor: Colors.transparent,
      ),
    );
  }

  @override
  Size get preferredSize => Size.fromHeight(kToolbarHeight + 16);
}
