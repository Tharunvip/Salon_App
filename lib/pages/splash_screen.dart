import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../design_system.dart';
import '../firebase_service.dart';
import '../customer_home.dart';
import '../language_provider.dart';
import 'onboarding_screen.dart';
import 'language_selection_screen.dart';
import 'admin_page.dart';
import '../owner_dashboard.dart';
import '../partner_dashboard.dart';
import '../login_registration.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnim;
  late Animation<double> _scaleAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 1800));
    _fadeAnim = Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(parent: _controller, curve: const Interval(0, 0.6, curve: Curves.easeOut)));
    _scaleAnim = Tween<double>(begin: 0.6, end: 1).animate(CurvedAnimation(parent: _controller, curve: const Interval(0, 0.6, curve: Curves.easeOutBack)));
    _slideAnim = Tween<Offset>(begin: const Offset(0, 0.5), end: Offset.zero).animate(CurvedAnimation(parent: _controller, curve: const Interval(0.3, 1, curve: Curves.easeOut)));
    _controller.forward();
    _init();
  }

  Future<void> _init() async {
    await Future.delayed(const Duration(milliseconds: 3000));
    if (!mounted) return;

    final lp = context.read<LanguageProvider>();
    if (lp.firstLaunch) {
      Navigator.pushReplacement(context, MaterialPageRoute(
        builder: (_) => const LanguageSelectionScreen(isFirstLaunch: true),
      ));
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final onboardingDone = prefs.getBool('onboarding_done') ?? false;
    if (!mounted) return;
    if (!onboardingDone) {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const OnboardingScreen()));
      return;
    }

    await lp.syncFromFirebase();
    final auth = FirebaseAuth.instance;
    var user = auth.currentUser;
    if (user == null) {
      try {
        user = await auth.authStateChanges().first.timeout(const Duration(seconds: 5));
      } catch (_) {
        user = auth.currentUser;
      }
    }

    if (user != null) {
      for (var attempt = 0; attempt < 3; attempt++) {
        try {
          final appUser = await FirebaseService().getCurrentAppUser();
          if (appUser != null) {
            if (!mounted) return;
            Widget destination;
            if (appUser.role == 'admin') {
              destination = AdminPage(user: appUser);
            } else if (appUser.role == 'owner') {
              destination = OwnerDashboard(user: appUser);
            } else if (appUser.role == 'partner') {
              destination = PartnerDashboard(user: appUser);
            } else {
              destination = CustomerHome(user: appUser);
            }
            Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => destination));
            return;
          }
        } catch (e) {
          debugPrint('[Splash] Auto-login attempt ${attempt + 1} error: $e');
        }
        if (attempt < 2) await Future.delayed(const Duration(milliseconds: 900));
      }
    }
    if (mounted) {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginPage()));
    }
  }

  @override
  void dispose() { _controller.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: LinearGradient(
          colors: [Color(0xFF004D40), Color(0xFF00695C), Color(0xFF1A1A2E)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        )),
        child: Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            AnimatedBuilder(
              animation: _controller,
              builder: (c, _) => Transform.scale(
                scale: _scaleAnim.value,
                child: Opacity(
                  opacity: _fadeAnim.value,
                  child: Container(
                    padding: const EdgeInsets.all(28),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(40),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                      boxShadow: [
                        BoxShadow(color: DS.accent.withValues(alpha: 0.3), blurRadius: 40, offset: const Offset(0, 10)),
                      ],
                    ),
                    child: const Icon(Icons.content_cut, size: 72, color: DS.accent),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 32),
            AnimatedBuilder(
              animation: _controller,
              builder: (c, _) => Opacity(
                opacity: _fadeAnim.value,
                child: Column(children: [
                  ShaderMask(
                    shaderCallback: (bounds) => const LinearGradient(colors: [Color(0xFFD4AF37), Color(0xFFFFF8E1), Color(0xFFD4AF37)]).createShader(bounds),
                    child: const Text('VIP BARBER', maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 44, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 3)),
                  ),
                  const Text('Booking & Queue Management', style: TextStyle(fontSize: 13, color: Colors.white70, fontWeight: FontWeight.w400, letterSpacing: 1)),
                ]),
              ),
            ),
            const SizedBox(height: 60),
            AnimatedBuilder(
              animation: _controller,
              builder: (c, _) => SlideTransition(
                position: _slideAnim,
                child: const SizedBox(
                  height: 28, width: 28,
                  child: CircularProgressIndicator(color: DS.accent, strokeWidth: 2.5),
                ),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}
