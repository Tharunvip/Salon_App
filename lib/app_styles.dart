import 'package:flutter/material.dart';

class AppColors {
  static const primary = Color(0xFF00695C);
  static const primaryLight = Color(0xFFB2DFDB);
  static const primaryVeryLight = Color(0xFFE0F2F1);
  static const secondary = Color(0xFF1B1B2F);
  static const accent = Color(0xFFD4AF37);
  static const accentLight = Color(0xFFFDF3D0);
  static const success = Color(0xFF10B981);
  static const successLight = Color(0xFFD1FAE5);
  static const error = Color(0xFFEF4444);
  static const errorLight = Color(0xFFFEE2E2);
  static const ink = Color(0xFF0F0F1A);
  static const muted = Color(0xFF6B7280);
  static const disabled = Color(0xFF9CA3AF);
  static const surface = Colors.white;
  static const border = Color(0xFFE8E8F0);
  static const page = Color(0xFFFAFAFE);
  static const gold = Color(0xFFD4AF37);
  static const goldLight = Color(0xFFFBF3D9);
  static const emerald = Color(0xFF00695C);
  static const emeraldLight = Color(0xFFE0F2F1);

  static const darkSurface = Color(0xFF1A1A2E);
  static const darkCard = Color(0xFF16213E);
  static const darkBg = Color(0xFF0F0F1A);
  static const darkInk = Color(0xFFF0F0FA);
  static const darkMuted = Color(0xFF9CA3AF);
  static const darkBorder = Color(0xFF2A2A4A);
  static const darkPage = Color(0xFF14142A);

  // Pre-created alpha colors for performance (avoid per-frame Color creation)
  static const primaryAlpha06 = Color(0x0F00695C);
  static const primaryAlpha03 = Color(0x0700695C);
  static const primaryAlpha02 = Color(0x0500695C);
  static const primaryAlpha01 = Color(0x0300695C);
  static const goldAlpha03 = Color(0x4DD4AF37);
  static const blackAlpha008 = Color(0x14000000);
  static const blackAlpha006 = Color(0x0F000000);
  static const blackAlpha004 = Color(0x0A000000);
  static const blackAlpha002 = Color(0x05000000);
  static const whiteAlpha015 = Color(0x26FFFFFF);
  static const whiteAlpha012 = Color(0x1FFFFFFF);
  static const whiteAlpha010 = Color(0x1AFFFFFF);
  static const whiteAlpha008 = Color(0x14FFFFFF);
  static const whiteAlpha005 = Color(0x0DFFFFFF);
  static const primaryAlpha02Shade = Color(0x3300695C);
  static const darkBorderAlpha03 = Color(0x4D2A2A4A);
  static const goldAlpha02 = Color(0x33D4AF37);
  static const primaryAlpha06Icon = Color(0x9900695C);
  static const whiteAlpha0085 = Color(0xD9FFFFFF);
  static const darkCardAlpha08 = Color(0xCC16213E);
  static const darkBorderAlpha03W = Color(0x4D2A2A4A);

  static const gradientPrimary = LinearGradient(
    colors: [Color(0xFF00695C), Color(0xFF004D40)],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  static const gradientGold = LinearGradient(
    colors: [Color(0xFFD4AF37), Color(0xFFB8962E)],
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
    colors: [Color(0xFF004D40), Color(0xFF00695C), Color(0xFF1A1A2E)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const gradientLogin = LinearGradient(
    colors: [Color(0xFF004D40), Color(0xFF00695C), Color(0xFF1A1A2E)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const gradientRegister = LinearGradient(
    colors: [Color(0xFF004D40), Color(0xFF00695C)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Pre-created shadow objects
  static const shadowCard = [
    BoxShadow(color: primaryAlpha06, blurRadius: 24, offset: Offset(0, 8)),
    BoxShadow(color: blackAlpha002, blurRadius: 4, offset: Offset(0, 2)),
  ];

  static const shadowGold = [
    BoxShadow(color: goldAlpha03, blurRadius: 16, offset: Offset(0, 6)),
  ];

  static const shadowPrimary = [
    BoxShadow(color: primaryAlpha02Shade, blurRadius: 16, offset: Offset(0, 6)),
  ];

  static const shadowGlass = [
    BoxShadow(color: blackAlpha004, blurRadius: 30, offset: Offset(0, 10)),
  ];

  static const shadowNav = [
    BoxShadow(color: blackAlpha008, blurRadius: 24, offset: Offset(0, -4)),
  ];

  static const shadowNone = <BoxShadow>[];

  // Shimmer base colors
  static const shimmerLightBase = Color(0xFFE8E8F0);
  static const shimmerLightHighlight = Color(0xFFF0F0F8);
}

class AppTheme {
  static ThemeData get theme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: AppColors.page,
      colorScheme: const ColorScheme.light(
        primary: AppColors.primary,
        secondary: AppColors.accent,
        surface: AppColors.surface,
        error: AppColors.error,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: AppColors.ink,
        centerTitle: true,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      inputDecorationTheme: const InputDecorationTheme(
        filled: true,
        fillColor: AppColors.page,
        labelStyle: TextStyle(color: AppColors.muted, fontSize: 14, fontWeight: FontWeight.w500),
        hintStyle: TextStyle(color: AppColors.disabled),
        prefixIconColor: AppColors.primary,
        contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(16)), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(16)), borderSide: BorderSide(color: AppColors.border)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(16)), borderSide: BorderSide(color: AppColors.primary, width: 1.5)),
        errorBorder: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(16)), borderSide: BorderSide(color: AppColors.error, width: 1.5)),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, letterSpacing: 0.5),
        ),
      ),
      snackBarTheme: const SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(16))),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Colors.white,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.muted,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        selectedLabelStyle: TextStyle(fontWeight: FontWeight.w600, fontSize: 11),
        unselectedLabelStyle: TextStyle(fontWeight: FontWeight.w400, fontSize: 11),
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.darkBg,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.primary,
        secondary: AppColors.accent,
        surface: AppColors.darkSurface,
        error: AppColors.error,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: AppColors.darkInk,
        centerTitle: true,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      inputDecorationTheme: const InputDecorationTheme(
        filled: true,
        fillColor: AppColors.darkPage,
        labelStyle: TextStyle(color: AppColors.darkMuted, fontSize: 14, fontWeight: FontWeight.w500),
        hintStyle: TextStyle(color: AppColors.darkMuted),
        prefixIconColor: AppColors.primary,
        contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(16)), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(16)), borderSide: BorderSide(color: AppColors.darkBorder)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(16)), borderSide: BorderSide(color: AppColors.primary, width: 1.5)),
        errorBorder: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(16)), borderSide: BorderSide(color: AppColors.error, width: 1.5)),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, letterSpacing: 0.5),
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.darkSurface,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.darkMuted,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        selectedLabelStyle: TextStyle(fontWeight: FontWeight.w600, fontSize: 11),
        unselectedLabelStyle: TextStyle(fontWeight: FontWeight.w400, fontSize: 11),
      ),
    );
  }
}

class PremiumTheme {
  static const inputDecoration = InputDecoration(
    filled: true,
    fillColor: Colors.white,
    labelStyle: TextStyle(color: AppColors.muted, fontSize: 14, fontWeight: FontWeight.w500),
    hintStyle: TextStyle(color: AppColors.disabled),
    prefixIconColor: AppColors.primary,
    contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 18),
    border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(16)), borderSide: BorderSide.none),
    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(16)), borderSide: BorderSide(color: AppColors.border)),
    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(16)), borderSide: BorderSide(color: AppColors.primary, width: 1.5)),
    errorBorder: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(16)), borderSide: BorderSide(color: AppColors.error, width: 1.5)),
  );
}

class PremiumCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final VoidCallback? onTap;
  final Color? borderColor;

  const PremiumCard({super.key, required this.child, this.padding, this.margin, this.onTap, this.borderColor});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: double.infinity,
      margin: margin ?? EdgeInsets.zero,
      padding: padding ?? const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor ?? (isDark ? AppColors.darkBorder : AppColors.border)),
        boxShadow: isDark ? AppColors.shadowNone : AppColors.shadowCard,
      ),
      child: onTap != null ? InkWell(onTap: onTap, borderRadius: BorderRadius.circular(20), child: child) : child,
    );
  }
}

class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;

  const GlassCard({super.key, required this.child, this.padding, this.margin});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: double.infinity,
      margin: margin ?? EdgeInsets.zero,
      padding: padding ?? const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCardAlpha08 : AppColors.whiteAlpha0085,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: isDark ? AppColors.darkBorderAlpha03W : AppColors.whiteAlpha015),
        boxShadow: isDark ? AppColors.shadowNone : AppColors.shadowGlass,
      ),
      child: child,
    );
  }
}

class PremiumBtn extends StatelessWidget {
  final String text;
  final IconData? icon;
  final VoidCallback onPressed;
  final bool loading;
  final bool expanded;
  final bool isGold;
  final bool isOutlined;
  final double height;

  const PremiumBtn({
    super.key,
    required this.text,
    this.icon,
    required this.onPressed,
    this.loading = false,
    this.expanded = true,
    this.isGold = false,
    this.isOutlined = false,
    this.height = 56,
  });

  @override
  Widget build(BuildContext context) {
    final gradient = isGold ? AppColors.gradientGold : AppColors.gradientPrimary;
      final content = loading
        ? const SizedBox(height: 22, width: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
        : Row(
            mainAxisSize: expanded ? MainAxisSize.max : MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[Icon(icon, color: isOutlined ? AppColors.primary : Colors.white, size: 20), const SizedBox(width: 10)],
              Flexible(child: Text(text, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700, letterSpacing: 0.5))),
            ],
          );

    if (isOutlined) {
      return SizedBox(
        height: height,
        width: expanded ? double.infinity : null,
        child: OutlinedButton(
          onPressed: loading ? null : onPressed,
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.primary,
            side: const BorderSide(color: AppColors.primary, width: 1.5),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            padding: const EdgeInsets.symmetric(horizontal: 24),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[Icon(icon, size: 20), const SizedBox(width: 10)],
              Flexible(child: Text(text, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, letterSpacing: 0.5))),
            ],
          ),
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
            borderRadius: BorderRadius.circular(16),
            boxShadow: isGold ? AppColors.shadowGold : AppColors.shadowPrimary,
          ),
          child: content,
        ),
      ),
    );
  }
}

class SectionHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final IconData? icon;
  final Widget? trailing;

  const SectionHeader({super.key, required this.title, this.subtitle, this.icon, this.trailing});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final ink = isDark ? AppColors.darkInk : AppColors.ink;
    final muted = isDark ? AppColors.darkMuted : AppColors.muted;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (icon != null) ...[
          Container(
            padding: const EdgeInsets.all(10),
            decoration: const BoxDecoration(color: AppColors.primaryVeryLight, borderRadius: BorderRadius.all(Radius.circular(12))),
            child: Icon(icon, color: AppColors.primary, size: 20),
          ),
          const SizedBox(width: 14),
        ],
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: TextStyle(fontSize: 18, color: ink, fontWeight: FontWeight.w800, letterSpacing: -0.3)),
              if (subtitle != null) ...[const SizedBox(height: 3), Text(subtitle!, style: TextStyle(color: muted, fontSize: 13))],
            ],
          ),
        ),
        ?trailing,
      ],
    );
  }
}

class PremiumAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  final Widget? leading;
  final bool transparent;

  const PremiumAppBar({super.key, required this.title, this.actions, this.leading, this.transparent = false});

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

class PremiumBottomNav extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;
  final List<BottomNavigationBarItem>? items;

  const PremiumBottomNav({super.key, required this.currentIndex, required this.onTap, this.items});

  static const _defaultItems = <BottomNavigationBarItem>[
    BottomNavigationBarItem(icon: Icon(Icons.home_outlined), activeIcon: Icon(Icons.home), label: 'Home'),
    BottomNavigationBarItem(icon: Icon(Icons.calendar_today_outlined), activeIcon: Icon(Icons.calendar_today), label: 'Bookings'),
    BottomNavigationBarItem(icon: Icon(Icons.notifications_outlined), activeIcon: Icon(Icons.notifications), label: 'Alerts'),
    BottomNavigationBarItem(icon: Icon(Icons.person_outline), activeIcon: Icon(Icons.person), label: 'Profile'),
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: AppColors.shadowNav,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BottomNavigationBar(
          currentIndex: currentIndex,
          onTap: onTap,
          backgroundColor: Colors.transparent,
          elevation: 0,
          selectedItemColor: AppColors.primary,
          unselectedItemColor: isDark ? AppColors.darkMuted : AppColors.muted,
          type: BottomNavigationBarType.fixed,
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 11),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w400, fontSize: 11),
          items: items ?? _defaultItems,
        ),
      ),
    );
  }
}

class ShimmerLoader extends StatefulWidget {
  final double height;
  final double width;
  final double radius;

  const ShimmerLoader({super.key, this.height = 16, this.width = double.infinity, this.radius = 12});

  @override
  State<ShimmerLoader> createState() => _ShimmerLoaderState();
}

class _ShimmerLoaderState extends State<ShimmerLoader> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 1500))..repeat();
    _slideAnim = Tween<Offset>(begin: const Offset(-0.5, 0), end: const Offset(1.5, 0)).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutSine),
    );
  }

  @override
  void dispose() { _controller.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseColor = isDark ? AppColors.darkCard : AppColors.shimmerLightBase;
    final hlColor = isDark ? AppColors.darkBorder : AppColors.shimmerLightHighlight;

    return ClipRRect(
      borderRadius: BorderRadius.circular(widget.radius),
      child: Container(
        height: widget.height,
        width: widget.width,
        color: baseColor,
        child: AnimatedBuilder(
          animation: _slideAnim,
          builder: (c, _) => FractionalTranslation(
            translation: _slideAnim.value,
            child: Container(width: 80, color: hlColor),
          ),
        ),
      ),
    );
  }
}

class LoadingShimmer extends StatelessWidget {
  final int count;
  final double itemHeight;

  const LoadingShimmer({super.key, this.count = 4, this.itemHeight = 100});

  @override
  Widget build(BuildContext context) {
    return Column(children: List.generate(count, (i) => Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: ShimmerLoader(height: itemHeight, radius: 16),
    )));
  }
}

class BadgeIcon extends StatelessWidget {
  final IconData icon;
  final int count;
  final double size;

  const BadgeIcon({super.key, required this.icon, this.count = 0, this.size = 24});

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Icon(icon, size: size),
        if (count > 0)
          Positioned(
            right: -6, top: -4,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(color: AppColors.error, shape: BoxShape.circle),
              constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
              child: Text('$count', style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w800)),
            ),
          ),
      ],
    );
  }
}

class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const EmptyState({super.key, required this.icon, required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(color: AppColors.primaryVeryLight, borderRadius: BorderRadius.all(Radius.circular(24))),
            child: Icon(icon, size: 48, color: AppColors.primaryAlpha06Icon),
          ),
          const SizedBox(height: 20),
          Text(title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: isDark ? AppColors.darkInk : AppColors.ink)),
          const SizedBox(height: 8),
          Text(subtitle, style: TextStyle(color: isDark ? AppColors.darkMuted : AppColors.muted, fontSize: 14), textAlign: TextAlign.center),
        ]),
      ),
    );
  }
}

class PremiumDialog extends StatelessWidget {
  final String title;
  final String content;
  final String confirmText;
  final String? cancelText;
  final VoidCallback onConfirm;
  final bool isGold;

  const PremiumDialog({
    super.key,
    required this.title,
    required this.content,
    required this.confirmText,
    this.cancelText,
    required this.onConfirm,
    this.isGold = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isGold ? AppColors.goldLight : AppColors.primaryVeryLight,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(isGold ? Icons.star : Icons.check_circle, size: 40, color: isGold ? AppColors.gold : AppColors.primary),
          ),
          const SizedBox(height: 20),
          Text(title, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: isDark ? AppColors.darkInk : AppColors.ink), textAlign: TextAlign.center),
          const SizedBox(height: 10),
          Text(content, style: TextStyle(color: isDark ? AppColors.darkMuted : AppColors.muted, fontSize: 14, height: 1.5), textAlign: TextAlign.center),
          const SizedBox(height: 24),
          Row(children: [
            if (cancelText != null) ...[
              Expanded(child: PremiumBtn(text: cancelText!, icon: Icons.close, onPressed: () => Navigator.pop(context), isOutlined: true)),
              const SizedBox(width: 12),
            ],
            Expanded(child: PremiumBtn(text: confirmText, icon: Icons.check, onPressed: () { Navigator.pop(context); onConfirm(); }, isGold: isGold)),
          ]),
        ]),
      ),
    );
  }
}
