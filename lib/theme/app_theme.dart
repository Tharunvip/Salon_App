import 'package:flutter/material.dart';

class DesignSystem {
  // Brand colors
  static const primary = Color(0xFF00695C);
  static const primaryDark = Color(0xFF004D40);
  static const primaryLight = Color(0xFFB2DFDB);
  static const primaryVeryLight = Color(0xFFE0F2F1);
  static const accent = Color(0xFFD4AF37);
  static const accentLight = Color(0xFFFDF3D0);

  // Semantic colors
  static const success = Color(0xFF10B981);
  static const successLight = Color(0xFFD1FAE5);
  static const warning = Color(0xFFF59E0B);
  static const warningLight = Color(0xFFFEF3C7);
  static const error = Color(0xFFEF4444);
  static const errorLight = Color(0xFFFEE2E2);
  static const info = Color(0xFF3B82F6);
  static const infoLight = Color(0xFFDBEAFE);
  static const purple = Color(0xFF7C3AED);
  static const purpleLight = Color(0xFFEDE9FE);

  // Neutral colors
  static const ink = Color(0xFF0F0F1A);
  static const inkLight = Color(0xFF1A1A2E);
  static const muted = Color(0xFF6B7280);
  static const disabled = Color(0xFF9CA3AF);
  static const border = Color(0xFFE8E8F0);
  static const surface = Colors.white;
  static const page = Color(0xFFFAFAFE);

  // Dark mode
  static const darkSurface = Color(0xFF1A1A2E);
  static const darkCard = Color(0xFF16213E);
  static const darkBg = Color(0xFF0F0F1A);
  static const darkInk = Color(0xFFF0F0FA);
  static const darkMuted = Color(0xFF9CA3AF);
  static const darkBorder = Color(0xFF2A2A4A);
  static const darkPage = Color(0xFF14142A);

  // Gradients
  static const gradientPrimary = LinearGradient(
    colors: [primary, primaryDark],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );
  static const gradientGold = LinearGradient(
    colors: [accent, Color(0xFFB8962E)],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );
  static const gradientBg = LinearGradient(
    colors: [Color(0xFFFAFAFE), Color(0xFFF0FDFA), Color(0xFFFFFDF5)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static const gradientDarkBg = LinearGradient(
    colors: [Color(0xFF0F0F1A), Color(0xFF1A1A2E)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static const gradientSplash = LinearGradient(
    colors: [Color(0xFF004D40), primary, Color(0xFF1A1A2E)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Shadows
  static const shadowSm = BoxShadow(color: Color(0x0A000000), blurRadius: 4, offset: Offset(0, 1));
  static const shadowMd = BoxShadow(color: Color(0x12000000), blurRadius: 12, offset: Offset(0, 4));
  static const shadowLg = BoxShadow(color: Color(0x1A000000), blurRadius: 24, offset: Offset(0, 8));
  static const shadowPrimary = BoxShadow(color: Color(0x3300695C), blurRadius: 16, offset: Offset(0, 6));
  static const shadowGold = BoxShadow(color: Color(0x4DD4AF37), blurRadius: 16, offset: Offset(0, 6));
  static const shadowNav = BoxShadow(color: Color(0x14000000), blurRadius: 24, offset: Offset(0, -4));

  // Spacing
  static const double spaceXs = 4;
  static const double spaceSm = 8;
  static const double spaceMd = 16;
  static const double spaceLg = 24;
  static const double spaceXl = 32;

  // Border radius
  static const double radiusSm = 8;
  static const double radiusMd = 12;
  static const double radiusLg = 16;
  static const double radiusXl = 20;
  static const double radiusXxl = 24;
  static const double radiusFull = 999;

  // Typography helpers
  static const TextStyle h1 = TextStyle(fontSize: 28, fontWeight: FontWeight.w900, letterSpacing: -0.5, height: 1.1);
  static const TextStyle h2 = TextStyle(fontSize: 22, fontWeight: FontWeight.w800, letterSpacing: -0.3);
  static const TextStyle h3 = TextStyle(fontSize: 18, fontWeight: FontWeight.w800, letterSpacing: -0.3);
  static const TextStyle body = TextStyle(fontSize: 15, fontWeight: FontWeight.w500);
  static const TextStyle bodySmall = TextStyle(fontSize: 13, fontWeight: FontWeight.w500);
  static const TextStyle caption = TextStyle(fontSize: 11, fontWeight: FontWeight.w600);
  static const TextStyle label = TextStyle(fontSize: 14, fontWeight: FontWeight.w600, letterSpacing: 0.3);

  static bool isDark(BuildContext c) => Theme.of(c).brightness == Brightness.dark;
  static Color inkColor(BuildContext c) => isDark(c) ? darkInk : ink;
  static Color mutedColor(BuildContext c) => isDark(c) ? darkMuted : muted;
  static Color surfaceColor(BuildContext c) => isDark(c) ? darkCard : surface;
  static Color borderColor(BuildContext c) => isDark(c) ? darkBorder : border;
}

class ModernCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final VoidCallback? onTap;
  final Color? borderColor;
  final Color? bgColor;
  final double radius;
  final List<BoxShadow>? shadows;

  const ModernCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.onTap,
    this.borderColor,
    this.bgColor,
    this.radius = DesignSystem.radiusXl,
    this.shadows,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: double.infinity,
      margin: margin ?? EdgeInsets.zero,
      padding: padding ?? const EdgeInsets.all(DesignSystem.spaceMd),
      decoration: BoxDecoration(
        color: bgColor ?? DesignSystem.surfaceColor(context),
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: borderColor ?? DesignSystem.borderColor(context).withValues(alpha: 0.5)),
        boxShadow: shadows ?? (isDark ? [DesignSystem.shadowSm] : [DesignSystem.shadowMd]),
      ),
      child: onTap != null
          ? Material(color: Colors.transparent, child: InkWell(onTap: onTap, borderRadius: BorderRadius.circular(radius), child: child))
          : child,
    );
  }
}

class ModernBtn extends StatelessWidget {
  final String text;
  final IconData? icon;
  final VoidCallback onPressed;
  final bool loading;
  final bool expanded;
  final bool isGold;
  final bool isOutlined;
  final double height;

  const ModernBtn({
    super.key,
    required this.text,
    this.icon,
    required this.onPressed,
    this.loading = false,
    this.expanded = true,
    this.isGold = false,
    this.isOutlined = false,
    this.height = 52,
  });

  @override
  Widget build(BuildContext context) {
    final gradient = isGold ? DesignSystem.gradientGold : DesignSystem.gradientPrimary;

    if (isOutlined) {
      return SizedBox(
        height: height,
        width: expanded ? double.infinity : null,
        child: OutlinedButton(
          onPressed: loading ? null : onPressed,
          style: OutlinedButton.styleFrom(
            foregroundColor: DesignSystem.primary,
            side: const BorderSide(color: DesignSystem.primary, width: 1.5),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(DesignSystem.radiusLg)),
            padding: const EdgeInsets.symmetric(horizontal: 24),
          ),
          child: _content(primary: DesignSystem.primary),
        ),
      );
    }

    return SizedBox(
      height: height,
      width: expanded ? double.infinity : null,
      child: GestureDetector(
        onTap: loading ? null : onPressed,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          decoration: BoxDecoration(
            gradient: gradient,
            borderRadius: BorderRadius.circular(DesignSystem.radiusLg),
            boxShadow: [isGold ? DesignSystem.shadowGold : DesignSystem.shadowPrimary],
          ),
          child: _content(primary: Colors.white),
        ),
      ),
    );
  }

  Widget _content({required Color primary}) {
    if (loading) {
      return const SizedBox(height: 22, width: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5));
    }
    return Row(
      mainAxisSize: expanded ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (icon != null) ...[Icon(icon, color: primary, size: 20), const SizedBox(width: 10)],
        Flexible(child: Text(text, overflow: TextOverflow.ellipsis, style: TextStyle(color: primary, fontSize: 15, fontWeight: FontWeight.w700, letterSpacing: 0.5))),
      ],
    );
  }
}

class ModernAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  final Widget? leading;
  final bool transparent;

  const ModernAppBar({super.key, required this.title, this.actions, this.leading, this.transparent = false});

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 20, letterSpacing: -0.3)),
      actions: actions,
      leading: leading,
      backgroundColor: transparent ? Colors.transparent : null,
      elevation: 0,
      centerTitle: false,
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

class StatusBadge extends StatelessWidget {
  final String status;
  final double fontSize;

  const StatusBadge({super.key, required this.status, this.fontSize = 10});

  @override
  Widget build(BuildContext context) {
    final (icon, color) = switch (status) {
      'available' => (Icons.check_circle, DesignSystem.success),
      'waiting_to_start' => (Icons.hourglass_top, DesignSystem.purple),
      'in_service' => (Icons.build, DesignSystem.info),
      'paused' => (Icons.pause_circle, DesignSystem.warning),
      'completed' => (Icons.check_circle_outline, DesignSystem.muted),
      'confirmed' => (Icons.check_circle_outline, DesignSystem.primary),
      'in_progress' => (Icons.play_circle_outline, DesignSystem.accent),
      'paid' => (Icons.paid, DesignSystem.accent),
      'cancelled' => (Icons.cancel_outlined, DesignSystem.error),
      _ => (Icons.schedule, DesignSystem.muted),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(DesignSystem.radiusSm),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 10, color: color),
        const SizedBox(width: 4),
        Text(status.replaceAll('_', ' ').toUpperCase(), style: TextStyle(fontSize: fontSize, fontWeight: FontWeight.w800, color: color, letterSpacing: 0.3)),
      ]),
    );
  }
}


