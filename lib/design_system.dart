import 'package:flutter/material.dart';

class DS {
  // ── Brand ──
  static const primary = Color(0xFF00695C);
  static const primaryDark = Color(0xFF004D40);
  static const primaryLight = Color(0xFFB2DFDB);
  static const accent = Color(0xFFD4AF37);
  static const accentLight = Color(0xFFFDF3D0);
  // ── Additional aliases (compatibility) ──
  static const primaryVeryLight = Color(0xFFE0F2F1);
  static const gold = Color(0xFFD4AF37);
  static const goldLight = Color(0xFFFBF3D9);
  static const emerald = Color(0xFF00695C);
  static const emeraldLight = Color(0xFFE0F2F1);
  static const inkLight = Color(0xFF1A1A2E);

  // ── Semantic ──
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
  static const teal = Color(0xFF0D9488);
  static const rose = Color(0xFFE11D48);

  // ── Neutrals ──
  static const ink = Color(0xFF0F0F1A);
  static const muted = Color(0xFF6B7280);
  static const disabled = Color(0xFF9CA3AF);
  static const border = Color(0xFFE8E8F0);
  static const surface = Colors.white;
  static const page = Color(0xFFFAFAFE);

  // ── Dark ──
  static const darkSurface = Color(0xFF1A1A2E);
  static const darkCard = Color(0xFF16213E);
  static const darkBg = Color(0xFF0F0F1A);
  static const darkInk = Color(0xFFF0F0FA);
  static const darkMuted = Color(0xFF9CA3AF);
  static const darkBorder = Color(0xFF2A2A4A);
  static const darkPage = Color(0xFF14142A);

  // ── Gradients ──
  static const gradientPrimary = LinearGradient(colors: [primary, primaryDark], begin: Alignment.centerLeft, end: Alignment.centerRight);
  static const gradientGold = LinearGradient(colors: [accent, Color(0xFFB8962E)], begin: Alignment.centerLeft, end: Alignment.centerRight);
  static const gradientBg = LinearGradient(colors: [Color(0xFFFAFAFE), Color(0xFFF0FDFA), Color(0xFFFFFDF5)], begin: Alignment.topLeft, end: Alignment.bottomRight);
  static const gradientDarkBg = LinearGradient(colors: [Color(0xFF0F0F1A), Color(0xFF1A1A2E)], begin: Alignment.topLeft, end: Alignment.bottomRight);
  static const gradientSplash = LinearGradient(colors: [Color(0xFF004D40), primary, Color(0xFF1A1A2E)], begin: Alignment.topLeft, end: Alignment.bottomRight);
  static const gradientSunset = LinearGradient(colors: [Color(0xFF667EEA), Color(0xFF764BA2)], begin: Alignment.topLeft, end: Alignment.bottomRight);
  static const gradientMint = LinearGradient(colors: [Color(0xFF0F9B8E), Color(0xFF00D2FF)], begin: Alignment.topLeft, end: Alignment.bottomRight);
  static const gradientCoral = LinearGradient(colors: [Color(0xFFFC5C7D), Color(0xFF6A82FB)], begin: Alignment.topLeft, end: Alignment.bottomRight);

  // ── Shadows ──
  static const shadowSm = BoxShadow(color: Color(0x0A000000), blurRadius: 4, offset: Offset(0, 1));
  static const shadowMd = BoxShadow(color: Color(0x12000000), blurRadius: 12, offset: Offset(0, 4));
  static const shadowLg = BoxShadow(color: Color(0x1A000000), blurRadius: 24, offset: Offset(0, 8));
  static const shadowPrimary = BoxShadow(color: Color(0x3300695C), blurRadius: 20, offset: Offset(0, 8));
  static const shadowGold = BoxShadow(color: Color(0x4DD4AF37), blurRadius: 20, offset: Offset(0, 8));
  static const shadowNav = BoxShadow(color: Color(0x14000000), blurRadius: 24, offset: Offset(0, -4));
  static const shadowCard = [BoxShadow(color: Color(0x0A000000), blurRadius: 24, offset: Offset(0, 8)), BoxShadow(color: Color(0x05000000), blurRadius: 4, offset: Offset(0, 2))];
  static const shadowGlass = [BoxShadow(color: Color(0x08000000), blurRadius: 40, offset: Offset(0, 12))];
  static const shadowElevated = [BoxShadow(color: Color(0x1A000000), blurRadius: 32, offset: Offset(0, 12))];

  // ── Spacing ──
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
  static const double xxl = 48;

  // ── Radius ──
  static const double rSm = 8;
  static const double rMd = 12;
  static const double rLg = 16;
  static const double rXl = 20;
  static const double rXxl = 24;
  static const double rFull = 999;

  // ── Typography ──
  static const TextStyle h1 = TextStyle(fontSize: 32, fontWeight: FontWeight.w900, letterSpacing: -0.8, height: 1.1);
  static const TextStyle h2 = TextStyle(fontSize: 26, fontWeight: FontWeight.w800, letterSpacing: -0.5, height: 1.15);
  static const TextStyle h3 = TextStyle(fontSize: 20, fontWeight: FontWeight.w700, letterSpacing: -0.3, height: 1.2);
  static const TextStyle h4 = TextStyle(fontSize: 17, fontWeight: FontWeight.w700, letterSpacing: -0.2);
  static const TextStyle body = TextStyle(fontSize: 15, fontWeight: FontWeight.w500, height: 1.5);
  static const TextStyle bodySm = TextStyle(fontSize: 13, fontWeight: FontWeight.w500, height: 1.4);
  static const TextStyle caption = TextStyle(fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 0.3);
  static const TextStyle label = TextStyle(fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 0.5);
  static const TextStyle overline = TextStyle(fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1.0);

  // ── Duration ──
  static const Duration fast = Duration(milliseconds: 200);
  static const Duration med = Duration(milliseconds: 350);
  static const Duration slow = Duration(milliseconds: 600);

  // ── Curves ──
  static const Curve easeOut = Curves.easeOutCubic;
  static const Curve easeInOut = Curves.easeInOutCubic;
  static const Curve spring = Curves.fastOutSlowIn;

  // ── Helpers ──
  static bool isDark(BuildContext c) => Theme.of(c).brightness == Brightness.dark;
  static Color inkC(BuildContext c) => isDark(c) ? darkInk : ink;
  static Color mutedC(BuildContext c) => isDark(c) ? darkMuted : muted;
  static Color surfaceC(BuildContext c) => isDark(c) ? darkCard : surface;
  static Color borderC(BuildContext c) => isDark(c) ? darkBorder : border;
  static Color pageC(BuildContext c) => isDark(c) ? darkPage : page;

  // ── Input Decoration (fully theme-aware) ──
  static InputDecoration inputDecoration(BuildContext context) {
    final dark = isDark(context);
    final cs = Theme.of(context).colorScheme;
    return InputDecoration(
      filled: true, fillColor: dark ? darkCard : Colors.white,
      labelStyle: TextStyle(color: dark ? darkInk : ink, fontSize: 14, fontWeight: FontWeight.w500),
      hintStyle: TextStyle(color: dark ? darkMuted : muted),
      prefixIconColor: cs.onSurface,
      suffixIconColor: cs.onSurface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(16)), borderSide: BorderSide.none),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(16)), borderSide: BorderSide(color: dark ? darkBorder : border)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(16)), borderSide: BorderSide(color: primary, width: 1.5)),
      errorBorder: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(16)), borderSide: BorderSide(color: error, width: 1.5)),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// Animation utilities
// ═══════════════════════════════════════════════════════════════

class AnimUtil {
  static Widget fadeIn({int? delay, required Widget child}) => _FadeIn(delay: delay, child: child);
  static Widget scaleIn({int? delay, required Widget child}) => _ScaleIn(delay: delay, child: child);
  static Widget slideUp({int? delay, required Widget child}) => _SlideUp(delay: delay, child: child);
  static Widget slideFromRight({int? delay, required Widget child}) => _SlideFromRight(delay: delay, child: child);
}

class _FadeIn extends StatefulWidget {
  final Widget child; final int? delay;
  const _FadeIn({required this.child, this.delay});
  @override
  State<_FadeIn> createState() => _FadeInState();
}
class _FadeInState extends State<_FadeIn> with SingleTickerProviderStateMixin {
  late AnimationController _c;
  late Animation<double> _a;
  @override void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: DS.med);
    _a = CurvedAnimation(parent: _c, curve: DS.easeOut);
    Future.delayed(Duration(milliseconds: widget.delay ?? 0), () { if (mounted) _c.forward(); });
  }
  @override void dispose() { _c.dispose(); super.dispose(); }
  @override Widget build(BuildContext context) => FadeTransition(opacity: _a, child: widget.child);
}

class _ScaleIn extends StatefulWidget {
  final Widget child; final int? delay;
  const _ScaleIn({required this.child, this.delay});
  @override
  State<_ScaleIn> createState() => _ScaleInState();
}
class _ScaleInState extends State<_ScaleIn> with SingleTickerProviderStateMixin {
  late AnimationController _c;
  late Animation<double> _a;
  @override void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: DS.med);
    _a = CurvedAnimation(parent: _c, curve: DS.spring);
    Future.delayed(Duration(milliseconds: widget.delay ?? 0), () { if (mounted) _c.forward(); });
  }
  @override void dispose() { _c.dispose(); super.dispose(); }
  @override Widget build(BuildContext context) => ScaleTransition(scale: _a, child: widget.child);
}

class _SlideUp extends StatefulWidget {
  final Widget child; final int? delay;
  const _SlideUp({required this.child, this.delay});
  @override
  State<_SlideUp> createState() => _SlideUpState();
}
class _SlideUpState extends State<_SlideUp> with SingleTickerProviderStateMixin {
  late AnimationController _c;
  late Animation<Offset> _a;
  @override void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: DS.med);
    _a = Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(CurvedAnimation(parent: _c, curve: DS.easeOut));
    Future.delayed(Duration(milliseconds: widget.delay ?? 0), () { if (mounted) _c.forward(); });
  }
  @override void dispose() { _c.dispose(); super.dispose(); }
  @override Widget build(BuildContext context) => SlideTransition(position: _a, child: widget.child);
}

class _SlideFromRight extends StatefulWidget {
  final Widget child; final int? delay;
  const _SlideFromRight({required this.child, this.delay});
  @override
  State<_SlideFromRight> createState() => _SlideFromRightState();
}
class _SlideFromRightState extends State<_SlideFromRight> with SingleTickerProviderStateMixin {
  late AnimationController _c;
  late Animation<Offset> _a;
  @override void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: DS.med);
    _a = Tween<Offset>(begin: const Offset(0.3, 0), end: Offset.zero).animate(CurvedAnimation(parent: _c, curve: DS.easeOut));
    Future.delayed(Duration(milliseconds: widget.delay ?? 0), () { if (mounted) _c.forward(); });
  }
  @override void dispose() { _c.dispose(); super.dispose(); }
  @override Widget build(BuildContext context) => SlideTransition(position: _a, child: widget.child);
}
