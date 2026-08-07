import 'package:flutter/material.dart';
import '../design_system.dart';
import 'premium_card.dart';

// ═══════════════════════════════════════════════════════════════
// Staggered Animation Column — children slide up one by one
// ═══════════════════════════════════════════════════════════════

class StaggeredColumn extends StatelessWidget {
  final List<Widget> children;
  final int baseDelay;
  final int stepDelay;
  final EdgeInsetsGeometry? padding;

  const StaggeredColumn({
    super.key,
    required this.children,
    this.baseDelay = 60,
    this.stepDelay = 100,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding ?? EdgeInsets.zero,
      child: Column(children: [
        for (int i = 0; i < children.length; i++)
          AnimUtil.slideUp(child: children[i], delay: baseDelay + (i * stepDelay)),
      ]),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// Premium Hero Card — full-width gradient hero with stats
// (matches owner dashboard hero style)
// ═══════════════════════════════════════════════════════════════

class HeroStat {
  final String label;
  final String value;
  final Color? color;
  const HeroStat(this.label, this.value, {this.color});
}

class PremiumHeroCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Gradient gradient;
  final List<HeroStat> stats;
  final Widget? avatar;
  final Widget? trailing;

  const PremiumHeroCard({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.gradient = DS.gradientPrimary,
    this.stats = const [],
    this.avatar,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(DS.rXl),
        boxShadow: const [DS.shadowGold],
      ),
      child: Stack(children: [
        Positioned(right: -26, top: -26, child: Container(width: 120, height: 120, decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withValues(alpha: 0.06)))),
        Positioned(right: 26, bottom: -34, child: Container(width: 100, height: 100, decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Colors.white.withValues(alpha: 0.18), width: 12)))),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            avatar ??
                Container(
                  height: 54, width: 54,
                  decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(DS.rLg), border: Border.all(color: Colors.white.withValues(alpha: 0.4))),
                  child: Icon(icon, color: Colors.white, size: 26),
                ),
            const SizedBox(width: 14),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: -0.5)),
              const SizedBox(height: 4),
              Text(subtitle, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: Colors.white.withValues(alpha: 0.85), fontSize: 12.5, fontWeight: FontWeight.w500)),
            ])),
            if (trailing != null) ...[const SizedBox(width: 10), trailing!],
          ]),
          if (stats.isNotEmpty) ...[
            const SizedBox(height: 14),
            Row(children: [
              for (var i = 0; i < stats.length; i++) ...[
                if (i > 0) const SizedBox(width: 10),
                Expanded(child: _statChip(stats[i])),
              ],
            ]),
          ],
        ]),
      ]),
    );
  }

  Widget _statChip(HeroStat s) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(DS.rMd), border: Border.all(color: Colors.white.withValues(alpha: 0.14))),
      child: Column(children: [
        Text(s.value, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: s.color ?? Colors.white, height: 1.1)),
        const SizedBox(height: 2),
        Text(s.label.toUpperCase(), maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 8.5, fontWeight: FontWeight.w700, letterSpacing: 0.9, color: Colors.white70)),
      ]),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// Dashboard Header — gradient banner with icon + title
// ═══════════════════════════════════════════════════════════════

class DashboardHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Gradient gradient;
  final Gradient? badgeGradient;
  final Color? iconColor;
  final Widget? badge;

  const DashboardHeader({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.gradient = DS.gradientPrimary,
    this.badgeGradient,
    this.iconColor,
    this.badge,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = DS.isDark(context);
    return Column(children: [
      const SizedBox(height: 16),
      AnimUtil.scaleIn(
        delay: 0,
        child: Container(
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            gradient: badgeGradient ?? gradient,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: (iconColor ?? DS.primary).withValues(alpha: 0.4),
                blurRadius: 40,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Icon(icon, size: 52, color: iconColor ?? Colors.white),
        ),
      ),
      const SizedBox(height: 24),
      AnimUtil.fadeIn(
        delay: 100,
        child: Text(
          title,
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w900,
            color: isDark ? DS.darkInk : DS.ink,
            letterSpacing: -0.5,
          ),
        ),
      ),
      const SizedBox(height: 6),
      AnimUtil.fadeIn(
        delay: 200,
        child: Text(
          subtitle,
          style: TextStyle(fontSize: 15, color: isDark ? DS.darkMuted : DS.muted),
        ),
      ),
      if (badge != null) ...[const SizedBox(height: 12), badge!],
      const SizedBox(height: 8),
    ]);
  }
}

// ═══════════════════════════════════════════════════════════════
// Color Stat Card — single stat with gradient icon bg
// ═══════════════════════════════════════════════════════════════

class ColorStatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final int value;
  final Color color;
  final bool loading;
  final VoidCallback? onTap;

  const ColorStatCard({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    this.loading = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = DS.isDark(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xCC16213E) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.15)),
        boxShadow: isDark ? null : [DS.shadowSm],
      ),
      child: Row(children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [color, color.withValues(alpha: 0.7)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 16, color: Colors.white),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: isDark ? DS.darkMuted : DS.muted,
                ),
              ),
              const SizedBox(height: 1),
              if (loading)
                Container(width: 24, height: 16, decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(4)))
              else
                AnimatedCounter(
                  value: value,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: isDark ? DS.darkInk : DS.ink,
                  ),
                ),
            ],
          ),
        ),
      ]),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// Animated Counter — smooth count from 0 to value
// ═══════════════════════════════════════════════════════════════

class AnimatedCounter extends StatelessWidget {
  final int value;
  final TextStyle? style;
  final String prefix;
  final String suffix;

  const AnimatedCounter({
    super.key,
    required this.value,
    this.style,
    this.prefix = '',
    this.suffix = '',
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<int>(
      tween: IntTween(begin: 0, end: value),
      duration: const Duration(milliseconds: 800),
      curve: Curves.easeOutCubic,
      builder: (_, v, _) => FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(
          '$prefix$v$suffix',
          style: style,
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// Section Card — reusable glass card with gradient icon header
// ═══════════════════════════════════════════════════════════════

class SectionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final int? count;
  final Color accentColor;
  final Widget child;
  final Widget? headerAction;

  const SectionCard({
    super.key,
    required this.icon,
    required this.title,
    this.count,
    required this.accentColor,
    required this.child,
    this.headerAction,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = DS.isDark(context);
    return GlassCard(
      padding: const EdgeInsets.all(24),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [accentColor, accentColor.withValues(alpha: 0.7)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(color: accentColor.withValues(alpha: 0.25), blurRadius: 8, offset: const Offset(0, 2)),
              ],
            ),
            child: Icon(icon, size: 20, color: Colors.white),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              count != null ? '$title ($count)' : title,
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: isDark ? DS.darkInk : DS.ink),
            ),
          ),
          ?headerAction,
        ]),
        const SizedBox(height: 20),
        child,
      ]),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// Status Badge — colored pill badge
// ═══════════════════════════════════════════════════════════════

class StatusBadge extends StatelessWidget {
  final String label;
  final Color color;

  const StatusBadge({super.key, required this.label, required this.color});

  factory StatusBadge.active() => const StatusBadge(label: 'Active', color: DS.success);
  factory StatusBadge.blocked() => const StatusBadge(label: 'Blocked', color: Color(0xFFEF4444));
  factory StatusBadge.pending() => const StatusBadge(label: 'Pending', color: DS.accent);
  factory StatusBadge.granted() => const StatusBadge(label: 'Granted', color: DS.success);
  factory StatusBadge.custom(String label, Color color) => StatusBadge(label: label, color: color);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        overflow: TextOverflow.ellipsis,
        maxLines: 1,
        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: color),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// Info Row — icon container + label + value
// ═══════════════════════════════════════════════════════════════

class InfoTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? subtitle;
  final Widget? trailing;

  const InfoTile({super.key, required this.icon, required this.label, this.subtitle, this.trailing});

  @override
  Widget build(BuildContext context) {
    final isDark = DS.isDark(context);
    return Row(children: [
      Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [DS.primaryLight, DS.primaryLight.withValues(alpha: 0.5)],
          ),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, size: 18, color: DS.primary),
      ),
      const SizedBox(width: 14),
      Expanded(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: isDark ? DS.darkInk : DS.ink),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 2),
            Text(
              subtitle!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 12, color: isDark ? DS.darkMuted : DS.muted),
            ),
          ],
        ]),
      ),
      ?trailing,
    ]);
  }
}

// ═══════════════════════════════════════════════════════════════
// Shop Tile — reusable shop row
// ═══════════════════════════════════════════════════════════════

class ShopTile extends StatelessWidget {
  final String shopName;
  final String ownerName;
  final String status;
  final String? partnerName;
  final String? partnerCode;
  final VoidCallback? onTap;
  final Widget? trailing;

  const ShopTile({
    super.key,
    required this.shopName,
    required this.ownerName,
    required this.status,
    this.partnerName,
    this.partnerCode,
    this.onTap,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = DS.isDark(context);
    final isActive = status == 'granted';
    final isBlocked = status == 'blocked';
    final Color statusColor = isActive ? DS.success : isBlocked ? const Color(0xFFEF4444) : DS.accent;
    final String statusLabel = isActive ? 'Active' : isBlocked ? 'Blocked' : 'Pending';

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xCC16213E) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark
                ? const Color(0x4D2A2A4A)
                : (isActive
                    ? DS.success.withValues(alpha: 0.2)
                    : isBlocked
                        ? const Color(0xFFEF4444).withValues(alpha: 0.2)
                        : const Color(0x26FFFFFF)),
          ),
          boxShadow: isDark ? null : [DS.shadowSm],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(
              child: Text(
                shopName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: isDark ? DS.darkInk : DS.ink),
              ),
            ),
            const SizedBox(width: 8),
            StatusBadge(label: statusLabel, color: statusColor),
          ]),
          const SizedBox(height: 4),
          Text(
            ownerName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 13, color: isDark ? DS.darkMuted : DS.muted),
          ),
          if (partnerCode != null && partnerCode!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: DS.purple.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: DS.purple.withValues(alpha: 0.15)),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.handshake, size: 12, color: DS.purple),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    partnerName != null && partnerName!.isNotEmpty ? '$partnerName ($partnerCode)' : '$partnerCode',
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: DS.purple),
                  ),
                ),
              ]),
            ),
          ],
          if (trailing != null) ...[const SizedBox(height: 8), trailing!],
        ]),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// Access Request Tile — with Allow/Block/Unblock actions
// ═══════════════════════════════════════════════════════════════

class AccessRequestTile extends StatelessWidget {
  final String ownerName;
  final String shopName;
  final String mobile;
  final String status;
  final String? note;
  final Widget? actionButtons;
  final Widget? trailing;

  const AccessRequestTile({
    super.key,
    required this.ownerName,
    required this.shopName,
    required this.mobile,
    required this.status,
    this.note,
    this.actionButtons,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = DS.isDark(context);
    final isGranted = status == 'granted';
    final isBlocked = status == 'blocked';
    final Color statusColor = isGranted ? DS.success : isBlocked ? const Color(0xFFEF4444) : DS.accent;
    final String statusLabel = isGranted ? 'Granted' : isBlocked ? 'Blocked' : 'Pending';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xCC16213E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: statusColor.withValues(alpha: 0.3)),
        boxShadow: isDark ? null : [DS.shadowSm],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(
            child: Text(
              ownerName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: isDark ? DS.darkInk : DS.ink),
            ),
          ),
          const SizedBox(width: 8),
          StatusBadge(label: statusLabel, color: statusColor),
        ]),
        const SizedBox(height: 6),
        Text(
          shopName,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(fontSize: 13, color: isDark ? DS.darkMuted : DS.muted),
        ),
        if (mobile.isNotEmpty) ...[
          const SizedBox(height: 2),
          Text(
            mobile,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 12, color: isDark ? DS.darkMuted : DS.muted),
          ),
        ],
        if (trailing != null) ...[const SizedBox(height: 6), trailing!],
        if (note == 'unblock_request' && status == 'pending') ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: const Color(0xFFF97316).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.lock_open, size: 12, color: Color(0xFFF97316)),
              SizedBox(width: 4),
              Text('Unblock Requested', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFFF97316))),
            ]),
          ),
        ],
        if (actionButtons != null) ...[const SizedBox(height: 10), actionButtons!],
      ]),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// Partner Tile — for admin page partner list
// ═══════════════════════════════════════════════════════════════

class PartnerTile extends StatelessWidget {
  final String name;
  final String email;
  final String mobile;
  final String partnerCode;
  final String status;
  final VoidCallback? onTap;
  final Widget? trailing;

  const PartnerTile({
    super.key,
    required this.name,
    required this.email,
    required this.mobile,
    required this.partnerCode,
    required this.status,
    this.onTap,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = DS.isDark(context);
    final isBlocked = status == 'blocked';

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xCC16213E) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isBlocked
                ? const Color(0xFFEF4444).withValues(alpha: 0.3)
                : isDark
                    ? const Color(0x4D2A2A4A)
                    : const Color(0x26FFFFFF),
          ),
          boxShadow: isDark ? null : [DS.shadowSm],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(
              child: Text(
                name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: isDark ? DS.darkInk : DS.ink),
              ),
            ),
            const SizedBox(width: 8),
            if (isBlocked) const StatusBadge(label: 'Blocked', color: Color(0xFFEF4444)),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: DS.purple.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                partnerCode,
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: DS.purple),
              ),
            ),
          ]),
          const SizedBox(height: 4),
          Text(
            email,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 13, color: isDark ? DS.darkMuted : DS.muted),
          ),
          const SizedBox(height: 2),
          Text(
            mobile,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 12, color: isDark ? DS.darkMuted : DS.muted),
          ),
          const SizedBox(height: 6),
          Row(children: [
            Icon(Icons.chevron_right, size: 16, color: DS.primary),
            const SizedBox(width: 4),
            Text('View Details', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: DS.primary)),
          ]),
          if (trailing != null) ...[const SizedBox(height: 8), trailing!],
        ]),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// Earnings Hero Banner — gold gradient with revenue + fees
// ═══════════════════════════════════════════════════════════════

class EarningsHeroBanner extends StatelessWidget {
  final int totalFees;
  final int totalRevenue;
  final int? totalBookings;
  final bool loading;
  final String? feesLabel;
  final String? revenueLabel;

  const EarningsHeroBanner({
    super.key,
    required this.totalFees,
    required this.totalRevenue,
    this.totalBookings,
    this.loading = false,
    this.feesLabel,
    this.revenueLabel,
  });

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator(strokeWidth: 3)));
    }
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: DS.gradientGold,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [DS.shadowGold],
      ),
      child: Column(children: [
        Row(children: [
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(
                feesLabel ?? 'Booking Fees',
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 11, color: Colors.white.withValues(alpha: 0.8)),
              ),
              const SizedBox(height: 4),
              AnimatedCounter(
                value: totalFees,
                prefix: '\u20B9',
                style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: Colors.white),
              ),
            ]),
          ),
          Container(width: 1, height: 40, color: Colors.white.withValues(alpha: 0.3)),
          const SizedBox(width: 16),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(
                revenueLabel ?? 'Service Revenue',
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 11, color: Colors.white.withValues(alpha: 0.8)),
              ),
              const SizedBox(height: 4),
              AnimatedCounter(
                value: totalRevenue,
                prefix: '\u20B9',
                style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: Colors.white),
              ),
            ]),
          ),
        ]),
        if (totalBookings != null) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '$totalBookings booking${totalBookings == 1 ? '' : 's'} completed',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white.withValues(alpha: 0.9)),
            ),
          ),
        ],
      ]),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// Shop Earnings Mini Tile
// ═══════════════════════════════════════════════════════════════

class ShopEarningsMiniTile extends StatelessWidget {
  final String shopName;
  final String partnerName;
  final String partnerCode;
  final int fees;
  final int revenue;
  final int bookings;
  final VoidCallback? onTap;

  const ShopEarningsMiniTile({
    super.key,
    required this.shopName,
    this.partnerName = '',
    this.partnerCode = '',
    required this.fees,
    required this.revenue,
    required this.bookings,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = DS.isDark(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xCC16213E) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: isDark ? const Color(0x4D2A2A4A) : const Color(0x26FFFFFF)),
          boxShadow: isDark ? null : [DS.shadowSm],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(
              child: Text(
                shopName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: isDark ? DS.darkInk : DS.ink),
              ),
            ),
            if (onTap != null) ...[
              const SizedBox(width: 6),
              Icon(Icons.chevron_right, size: 18, color: onTap != null ? DS.primary : (isDark ? DS.darkMuted : DS.muted)),
            ],
          ]),
          if (partnerCode.isNotEmpty) ...[
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(color: DS.purple.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20)),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.handshake, size: 11, color: DS.purple),
                const SizedBox(width: 4),
                Flexible(child: Text(partnerName.isNotEmpty ? '$partnerName · $partnerCode' : partnerCode, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: DS.purple))),
              ]),
            ),
          ],
          const SizedBox(height: 10),
          Row(children: [
            _miniStat('Fees', '\u20B9$fees', DS.success),
            const SizedBox(width: 12),
            _miniStat('Revenue', '\u20B9$revenue', DS.primary),
            const SizedBox(width: 12),
            _miniStat('Bookings', '$bookings', DS.accent),
          ]),
        ]),
      ),
    );
  }

  Widget _miniStat(String label, String value, Color color) {
    return Expanded(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w500, color: DS.muted)),
        const SizedBox(height: 2),
        FittedBox(fit: BoxFit.scaleDown, child: Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: color))),
      ]),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// Partner Earnings Tile — per partner code totals
// ═══════════════════════════════════════════════════════════════

class PartnerEarningsTile extends StatelessWidget {
  final String partnerName;
  final String partnerCode;
  final int fees;
  final int revenue;
  final int bookings;
  final int shops;

  const PartnerEarningsTile({
    super.key,
    required this.partnerName,
    required this.partnerCode,
    required this.fees,
    required this.revenue,
    required this.bookings,
    required this.shops,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = DS.isDark(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: DS.purple.withValues(alpha: isDark ? 0.12 : 0.05),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: DS.purple.withValues(alpha: 0.25)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(Icons.handshake, size: 16, color: DS.purple),
          const SizedBox(width: 6),
          Expanded(child: Text(partnerName.isNotEmpty ? partnerName : partnerCode, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: isDark ? DS.darkInk : DS.ink))),
        ]),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(color: DS.purple.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20)),
          child: Text(partnerCode, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: DS.purple)),
        ),
        const SizedBox(height: 10),
        Row(children: [
          _miniStat('Fees', '\u20B9$fees', DS.success),
          const SizedBox(width: 12),
          _miniStat('Revenue', '\u20B9$revenue', DS.primary),
          const SizedBox(width: 12),
          _miniStat('Shops', '$shops', DS.accent),
          const SizedBox(width: 12),
          _miniStat('Bookings', '$bookings', DS.purple),
        ]),
      ]),
    );
  }

  Widget _miniStat(String label, String value, Color color) {
    return Expanded(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w500, color: DS.muted)),
        const SizedBox(height: 2),
        FittedBox(fit: BoxFit.scaleDown, child: Text(value, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: color))),
      ]),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// Empty State — styled empty message
// ═══════════════════════════════════════════════════════════════

class DashboardEmptyState extends StatelessWidget {
  final String message;

  const DashboardEmptyState({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    final isDark = DS.isDark(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.inbox_outlined, size: 36, color: isDark ? DS.darkMuted : DS.disabled),
        const SizedBox(height: 10),
        Text(
          message,
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 14, color: isDark ? DS.darkMuted : DS.muted),
        ),
      ]),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// Loading Shimmer placeholder
// ═══════════════════════════════════════════════════════════════

class DashboardLoading extends StatelessWidget {
  const DashboardLoading({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator(strokeWidth: 3)));
  }
}
