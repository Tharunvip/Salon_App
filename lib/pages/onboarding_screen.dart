import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../design_system.dart';
import '../widgets/premium_button.dart';
import '../login_registration.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});
  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final controller = PageController();
  int page = 0;

  final pages = const [
    _OnboardingData(
      icon: Icons.location_on_rounded,
      title: 'Find Nearby Salons',
      desc: 'Discover top-rated salons near you with premium services, real-time availability, and instant booking.',
      color: Color(0xFF80CBC4),
    ),
    _OnboardingData(
      icon: Icons.favorite_rounded,
      title: 'Choose Your Favourite Shop',
      desc: 'Save the shops you love, get updates from your barber, and book your regular slot in a single tap.',
      color: Color(0xFFD4AF37),
    ),
    _OnboardingData(
      icon: Icons.confirmation_number_rounded,
      title: 'Book Without Waiting',
      desc: 'Skip the queue. Book your appointment, get your token, and arrive exactly when it\'s your turn.',
      color: Color(0xFF80CBC4),
    ),
  ];

  Future<void> done() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_done', true);
    if (!mounted) return;
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginPage()));
  }

  @override
  void dispose() { controller.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF004D40), Color(0xFF00695C)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Column(children: [
            Expanded(
              child: PageView(
                controller: controller,
                onPageChanged: (i) => setState(() => page = i),
                children: pages.map((p) => _PremiumOnboardingPage(data: p)).toList(),
              ),
            ),
            Row(mainAxisAlignment: MainAxisAlignment.center, children:
              List.generate(pages.length, (i) => AnimatedContainer(
                duration: const Duration(milliseconds: 400),
                margin: const EdgeInsets.symmetric(horizontal: 4),
                height: 8,
                width: page == i ? 32 : 8,
                decoration: BoxDecoration(
                  gradient: page == i ? DS.gradientGold : LinearGradient(colors: [Colors.white24, Colors.white24]),
                  borderRadius: BorderRadius.circular(4),
                  boxShadow: page == i ? [BoxShadow(color: DS.gold.withValues(alpha: 0.4), blurRadius: 8)] : [],
                ),
              )),
            ),
            const SizedBox(height: 32),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(children: [
                TextButton(
                  onPressed: done,
                  style: TextButton.styleFrom(foregroundColor: Colors.white70),
                  child: const Text('Skip', style: TextStyle(fontWeight: FontWeight.w600)),
                ),
                const Spacer(),
                SizedBox(
                  width: 190,
                  child: PButton(
                    text: page == pages.length - 1 ? 'Get Started' : 'Next',
                    icon: Icons.arrow_forward,
                    onPressed: () {
                      if (page == pages.length - 1) { done(); } else { controller.nextPage(duration: const Duration(milliseconds: 500), curve: Curves.easeInOut); }
                    },
                    expanded: true,
                    isGold: true,
                  ),
                ),
              ]),
            ),
            const SizedBox(height: 48),
          ]),
        ),
      ),
    );
  }
}

class _OnboardingData {
  final IconData icon;
  final String title;
  final String desc;
  final Color color;
  const _OnboardingData({required this.icon, required this.title, required this.desc, required this.color});
}

class _PremiumOnboardingPage extends StatelessWidget {
  final _OnboardingData data;
  const _PremiumOnboardingPage({required this.data});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Container(
          padding: const EdgeInsets.all(36),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(48),
            border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
            boxShadow: [
              BoxShadow(color: data.color.withValues(alpha: 0.3), blurRadius: 30, offset: const Offset(0, 15)),
            ],
          ),
          child: Icon(data.icon, size: 96, color: data.color),
        ),
        const SizedBox(height: 48),
        ShaderMask(
          shaderCallback: (bounds) => LinearGradient(
            colors: [const Color(0xFFFFF3CE), DS.gold],
          ).createShader(bounds),
          child: Text(data.title, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(
            fontSize: 28, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: -0.5, height: 1.2,
          ), textAlign: TextAlign.center),
        ),
        const SizedBox(height: 16),
        Text(data.desc, maxLines: 3, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 16, color: Colors.white, height: 1.6, fontWeight: FontWeight.w500), textAlign: TextAlign.center),
      ]),
    );
  }
}
