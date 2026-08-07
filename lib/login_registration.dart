import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'customer_home.dart';
import 'firebase_service.dart';
import 'l10n/app_localizations.dart';
import 'owner_dashboard.dart';
import 'pages/legal_page.dart';
import 'partner_dashboard.dart';
import 'pages/admin_page.dart';
import 'services/offline_guard.dart';
import 'widgets/language_bottom_sheet.dart';
import 'design_system.dart';
import 'widgets/premium_card.dart';
import 'widgets/premium_button.dart';

final RegExp _emailRegex = RegExp(r'^[\w.+-]+@[\w-]+(\.[\w-]+)+$');
final RegExp _mobileRegex = RegExp(r'^\d{10}$');

bool _isValidEmail(String value) => _emailRegex.hasMatch(value.trim());

String? _passwordStrengthError(String p) {
  if (p.length < 8) return 'Password must be at least 8 characters';
  if (!RegExp(r'[A-Z]').hasMatch(p)) return 'Password needs at least 1 uppercase letter (A-Z)';
  if (!RegExp(r'[a-z]').hasMatch(p)) return 'Password needs at least 1 lowercase letter (a-z)';
  if (!RegExp(r'[0-9]').hasMatch(p)) return 'Password needs at least 1 number (0-9)';
  if (!RegExp(r'[^A-Za-z0-9]').hasMatch(p)) return 'Password needs at least 1 special character (!@#\$%...)';
  return null;
}

class LoginPage extends StatefulWidget {
  final bool showRegister;
  const LoginPage({super.key, this.showRegister = false});
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> with SingleTickerProviderStateMixin {
  final svc = FirebaseService();
  final emailCnt = TextEditingController();
  final passCnt = TextEditingController();
  bool loading = false;
  bool obscure = true;
  bool isRegister = false;
  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    isRegister = widget.showRegister;
    _animController = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _fadeAnim = Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic));
    _animController.forward();
  }

  @override
  void dispose() { _animController.dispose(); emailCnt.dispose(); passCnt.dispose(); super.dispose(); }

  Future<void> login() async {
    final email = emailCnt.text.trim();
    final pass = passCnt.text.trim();
    final l = AppLocalizations.of(context)!;
    if (email.isEmpty || pass.isEmpty) { _msg(l.fieldRequired); return; }
    setState(() => loading = true);
    try {
      final stale = FirebaseAuth.instance.currentUser;
      if (stale != null && stale.email != email) {
        await FirebaseAuth.instance.signOut();
      }
      final user = await svc.login(email: email, password: pass);
      if (!mounted) return;
      if (user.role == 'admin') {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => AdminPage(user: user)));
      } else if (user.role == 'owner') {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => OwnerDashboard(user: user)));
      } else if (user.role == 'partner') {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => PartnerDashboard(user: user)));
      } else {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => CustomerHome(user: user)));
      }
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') { _msg(l.sessionExpired); }
      else if (e.code == 'wrong-password' || e.code == 'invalid-credential' || e.code == 'invalid-login-credentials') { _msg('Incorrect email or password. Use "Forgot Password?" if you can\'t remember.'); }
      else if (e.code == 'invalid-email') { _msg(l.invalidEmail); }
      else { _msg(e.message ?? l.error); }
    } on FirebaseException catch (e) {
      debugPrint('[Login] Firestore error: code=${e.code} message=${e.message}');
      _msg('Database error: ${e.code == 'permission-denied' ? 'Access denied. Please try again or contact support.' : e.message ?? l.error}');
    } catch (e) { _msg(friendlyError(e)); }
    if (mounted) setState(() => loading = false);
  }

  Future<void> _showForgotPassword() async {
    final l = AppLocalizations.of(context)!;
    final emailPrefill = emailCnt.text.trim();
    final cnt = TextEditingController(text: emailPrefill);
    String? errorText;
    var sending = false;
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) {
          final isDark = Theme.of(dialogContext).brightness == Brightness.dark;
          return Dialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(DS.rXxl)),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: DS.primaryVeryLight, borderRadius: BorderRadius.circular(DS.rLg)), child: const Icon(Icons.lock_reset, color: DS.primary, size: 32)),
                const SizedBox(height: 16),
                Text('Reset Password', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: isDark ? DS.darkInk : DS.ink)),
                const SizedBox(height: 4),
                Text('Enter your email and we will send you a password reset link', textAlign: TextAlign.center, style: TextStyle(color: isDark ? DS.darkMuted : DS.muted, fontSize: 13)),
                const SizedBox(height: 20),
                TextField(
                  controller: cnt,
                  keyboardType: TextInputType.emailAddress,
                  style: TextStyle(color: DS.inkC(dialogContext)),
                  decoration: DS.inputDecoration(dialogContext).copyWith(
                    labelText: l.email,
                    hintText: 'your@email.com',
                    prefixIcon: const Icon(Icons.email_outlined, size: 20),
                    errorText: errorText,
                  ),
                ),
                const SizedBox(height: 20),
                Row(children: [
                  Expanded(child: PButton(text: 'Cancel', icon: Icons.close, onPressed: () => Navigator.pop(dialogContext), isOutlined: true)),
                  const SizedBox(width: 12),
                  Expanded(child: PButton(text: 'Send Link', icon: Icons.send, isGold: true, loading: sending, onPressed: () async {
                    final em = cnt.text.trim();
                    if (em.isEmpty) { setDialogState(() => errorText = l.fieldRequired); return; }
                    if (!_isValidEmail(em)) { setDialogState(() => errorText = l.invalidEmail); return; }
                    setDialogState(() { sending = true; errorText = null; });
                    try {
                      await svc.sendPasswordReset(em);
                      if (!dialogContext.mounted) return;
                      Navigator.pop(dialogContext);
                      _showResetSent(em);
                    } on FirebaseAuthException catch (e) {
                      setDialogState(() {
                        sending = false;
                        errorText = e.code == 'user-not-found' ? 'No account found with this email' : 'Failed to send reset email. Try again.';
                      });
                    } catch (_) {
                      setDialogState(() { sending = false; errorText = 'Failed to send. Check your internet connection.'; });
                    }
                  })),
                ]),
              ]),
            ),
          );
        },
      ),
    );
  }

  void _showResetSent(String email) {
    showDialog<void>(
      context: context,
      builder: (c) {
        final isDark = Theme.of(c).brightness == Brightness.dark;
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(DS.rXxl)),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: DS.success.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(DS.rLg)), child: const Icon(Icons.mark_email_read_outlined, color: DS.success, size: 32)),
              const SizedBox(height: 16),
              Text('Reset Link Sent', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: isDark ? DS.darkInk : DS.ink)),
              const SizedBox(height: 8),
              Text('Password reset link sent to\n$email\n\nOpen it from your email (check the spam folder too). You will set a new password on the page, then log in here with the new password.', textAlign: TextAlign.center, style: TextStyle(fontSize: 13, color: isDark ? DS.darkMuted : DS.muted, height: 1.5)),
              const SizedBox(height: 20),
              PButton(text: 'OK', icon: Icons.check, onPressed: () => Navigator.pop(c), isGold: true),
            ]),
          ),
        );
      },
    );
  }

  void _msg(String s) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(s), backgroundColor: DS.error, behavior: SnackBarBehavior.floating, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(DS.rMd))));
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: DS.gradientSplash),
        child: SafeArea(
          child: Stack(
            children: [
              FadeTransition(
                opacity: _fadeAnim,
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final horizontalPadding = constraints.maxWidth < 360 ? 16.0 : 24.0;
                    final cardPadding = constraints.maxWidth < 360 ? 20.0 : 28.0;
                    return Center(
                      child: SingleChildScrollView(
                        padding: EdgeInsets.all(horizontalPadding),
                        child: Column(mainAxisSize: MainAxisSize.min, children: [
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(DS.rXxl),
                              border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
                            ),
                            child: const Icon(Icons.content_cut, size: 44, color: DS.accent),
                          ),
                          const SizedBox(height: 16),
                          ShaderMask(
                            shaderCallback: (bounds) => const LinearGradient(colors: [Color(0xFFD4AF37), Color(0xFFFFF8E1)]).createShader(bounds),
                            child: const Text('VIP BARBER', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 2)),
                          ),
                          const SizedBox(height: 6),
                          FadeTransition(opacity: _fadeAnim, child: Text(isRegister ? l.register : l.welcomeToApp, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 16, color: Colors.white70, fontWeight: FontWeight.w400))),
                          const SizedBox(height: 32),
                          GlassCard(
                            padding: EdgeInsets.all(cardPadding),
                            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Text(l.login, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: DS.inkC(context))),
                              const SizedBox(height: 6),
                              Text('Sign in to continue', maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 13, color: DS.mutedC(context))),
                              const SizedBox(height: 20),
                              TextField(
                                controller: emailCnt,
                                style: TextStyle(color: DS.inkC(context)),
                                decoration: DS.inputDecoration(context).copyWith(
                                  labelText: l.email, hintText: 'your@email.com',
                                  prefixIcon: const Icon(Icons.email_outlined, size: 20),
                                ),
                                keyboardType: TextInputType.emailAddress,
                              ),
                              const SizedBox(height: 14),
                              TextField(
                                controller: passCnt,
                                obscureText: obscure,
                                style: TextStyle(color: DS.inkC(context)),
                                decoration: DS.inputDecoration(context).copyWith(
                                  labelText: l.password, hintText: 'Enter your password',
                                  prefixIcon: const Icon(Icons.lock_outline, size: 20),
                                  suffixIcon: IconButton(icon: Icon(obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined, size: 20), onPressed: () => setState(() => obscure = !obscure)),
                                ),
                              ),
                              const SizedBox(height: 10),
                              Align(
                                alignment: Alignment.centerRight,
                                child: TextButton(
                                  onPressed: _showForgotPassword,
                                  child: Text(l.forgotPassword, style: const TextStyle(color: DS.primary, fontWeight: FontWeight.w600, fontSize: 13)),
                                ),
                              ),
                              const SizedBox(height: 6),
                              PButton(text: l.login, icon: Icons.arrow_forward, onPressed: login, loading: loading),
                              const SizedBox(height: 14),
                              Center(child: Wrap(
                                alignment: WrapAlignment.center,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                children: [
                                  Text(l.dontHaveAccount, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: DS.mutedC(context), fontSize: 13)),
                                  TextButton(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RegisterPage())),
                                    child: Text(l.register, style: const TextStyle(color: DS.primary, fontWeight: FontWeight.w700, fontSize: 14))),
                                ],
                              )),
                            ]),
                          ),
                          const SizedBox(height: 14),
                          _legalLinks(context),
                        ]),
                      ),
                    );
                  },
                ),
              ),
              Positioned(
                top: 8,
                right: 16,
                child: GestureDetector(
                  onTap: () => LanguageBottomSheet.show(context),
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(DS.rMd)),
                    child: const Icon(Icons.language, color: Colors.white, size: 22),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _legalLinks(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 4,
      children: [
        TextButton(
          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LegalPage(title: 'Privacy Policy', assetPath: 'docs/PRIVACY_POLICY.md'))),
          child: const Text('Privacy Policy', style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600)),
        ),
        const Text('•', style: TextStyle(color: Colors.white54, fontSize: 12)),
        TextButton(
          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LegalPage(title: 'Terms of Service', assetPath: 'docs/TERMS_OF_SERVICE.md'))),
          child: const Text('Terms of Service', style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600)),
        ),
      ],
    );
  }
}

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});
  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> with SingleTickerProviderStateMixin {
  final svc = FirebaseService();
  final nameCnt = TextEditingController();
  final emailCnt = TextEditingController();
  final mobileCnt = TextEditingController();
  final passCnt = TextEditingController();
  final shopCnt = TextEditingController();
  final partnerCodeCnt = TextEditingController();
  bool loading = false;
  bool obscure = true;
  bool agreeToTerms = false;
  int step = 0;
  String role = 'customer';
  late AnimationController _animController;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(vsync: this, duration: const Duration(milliseconds: 400));
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    nameCnt.dispose(); emailCnt.dispose(); mobileCnt.dispose(); passCnt.dispose(); shopCnt.dispose(); partnerCodeCnt.dispose();
    super.dispose();
  }

  void _nextStep() {
    final l = AppLocalizations.of(context)!;
    if (step == 0 && nameCnt.text.trim().isEmpty) { _msg('Enter your name'); return; }
    if (step == 1) {
      final email = emailCnt.text.trim();
      if (email.isEmpty) { _msg('Enter your email'); return; }
      if (!_isValidEmail(email)) { _msg(l.invalidEmail); return; }
      final mobile = mobileCnt.text.trim();
      if (mobile.isEmpty) { _msg('Enter your mobile number'); return; }
      if (!_mobileRegex.hasMatch(mobile)) { _msg('Enter a valid 10-digit mobile number'); return; }
      final pErr = _passwordStrengthError(passCnt.text);
      if (pErr != null) { _msg(pErr); return; }
    }
    if (step < 2) {
      _animController.reset();
      setState(() => step++);
      _animController.forward();
    } else {
      _register();
    }
  }

  Future<void> _register() async {
    final partnerCode = partnerCodeCnt.text.trim();
    if (partnerCode.isNotEmpty) {
      final existing = await svc.getPartnerByCode(partnerCode);
      if (existing == null) { _msg('Invalid partner code'); return; }
    }
    if (!agreeToTerms) {
      _msg('Please accept the Terms of Service and Privacy Policy to continue.');
      return;
    }
    setState(() => loading = true);
    try {
      final user = await svc.register(
        name: nameCnt.text.trim(), email: emailCnt.text.trim(), mobile: mobileCnt.text.trim(),
        password: passCnt.text.trim(), role: role, shopName: shopCnt.text.trim(),
        partnerCode: partnerCode.isNotEmpty ? partnerCode : null,
      );
      if (!mounted) return;
      if (user.role == 'owner') {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => OwnerDashboard(user: user)));
      } else if (user.role == 'partner') {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => PartnerDashboard(user: user)));
      } else {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => CustomerHome(user: user)));
      }
    } on FirebaseAuthException catch (e) {
      if (e.code == 'email-already-in-use') { _msg('Email already registered. Please login.'); }
      else { _msg(e.message ?? 'Registration failed'); }
    } catch (e) { _msg(friendlyError(e)); }
    if (mounted) setState(() => loading = false);
  }

  void _msg(String s) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(s), backgroundColor: DS.error, behavior: SnackBarBehavior.floating, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(DS.rMd))));
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: DS.gradientSplash),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final hp = constraints.maxWidth < 360 ? 12.0 : 20.0;
              final cardPad = constraints.maxWidth < 360 ? 18.0 : 24.0;
              return Stack(
                children: [
                  SingleChildScrollView(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(minHeight: constraints.maxHeight),
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(hp, 8, hp, 24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(l.register, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: -0.5)),
                            const SizedBox(height: 6),
                            Text('Step ${step + 1} of 3', style: const TextStyle(color: Colors.white70, fontSize: 14)),
                            const SizedBox(height: 16),
                            Row(mainAxisAlignment: MainAxisAlignment.center, children: List.generate(3, (i) => AnimatedContainer(
                              duration: const Duration(milliseconds: 400),
                              margin: const EdgeInsets.symmetric(horizontal: 3),
                              width: step >= i ? 48 : 12, height: 6,
                              decoration: BoxDecoration(
                                color: step >= i ? const Color(0xFFD4AF37) : Colors.white.withValues(alpha: 0.3),
                                borderRadius: BorderRadius.circular(3),
                              ),
                            ))),
                            const SizedBox(height: 24),
                            AnimatedBuilder(
                              animation: _animController,
                              builder: (c, _) => Transform.scale(
                                scale: 0.3 + (_animController.value * 0.7),
                                child: GlassCard(
                                  padding: EdgeInsets.all(cardPad),
                                  child: step == 0
                                      ? _step1()
                                      : step == 1
                                          ? _step2()
                                          : _step3(),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 0,
                    left: hp,
                    child: IconButton(icon: const Icon(Icons.arrow_back, color: Colors.white), onPressed: () => Navigator.pop(context)),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _step1() {
    final l = AppLocalizations.of(context)!;
    return SingleChildScrollView(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Personal Details', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: DS.inkC(context))),
      const SizedBox(height: 6),
      Text('Tell us about yourself', style: TextStyle(fontSize: 13, color: DS.mutedC(context))),
      const SizedBox(height: 24),
      TextField(controller: nameCnt, style: TextStyle(color: DS.inkC(context)), decoration: DS.inputDecoration(context).copyWith(labelText: l.name, hintText: 'John Doe', prefixIcon: const Icon(Icons.person_outline, size: 20))),
      const SizedBox(height: 20),
      PButton(text: l.continueApp, icon: Icons.arrow_forward, onPressed: _nextStep),
    ]));
  }

  Widget _step2() {
    final l = AppLocalizations.of(context)!;
    return SingleChildScrollView(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Account Details', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: DS.inkC(context))),
      const SizedBox(height: 6),
      Text('Setup your login credentials', style: TextStyle(fontSize: 13, color: DS.mutedC(context))),
      const SizedBox(height: 24),
      TextField(controller: emailCnt, style: TextStyle(color: DS.inkC(context)), decoration: DS.inputDecoration(context).copyWith(labelText: l.email, hintText: 'your@email.com', prefixIcon: const Icon(Icons.email_outlined, size: 20)), keyboardType: TextInputType.emailAddress),
      const SizedBox(height: 16),
      TextField(controller: mobileCnt, style: TextStyle(color: DS.inkC(context)), decoration: DS.inputDecoration(context).copyWith(labelText: l.mobile, hintText: '10-digit mobile number', prefixIcon: const Icon(Icons.phone_outlined, size: 20), counterText: ''), keyboardType: TextInputType.phone, maxLength: 10, inputFormatters: [FilteringTextInputFormatter.digitsOnly]),
      const SizedBox(height: 16),
      TextField(controller: passCnt, obscureText: obscure, style: TextStyle(color: DS.inkC(context)), decoration: DS.inputDecoration(context).copyWith(labelText: l.password, hintText: 'Min 8: A-Z, a-z, 0-9, special', prefixIcon: const Icon(Icons.lock_outline, size: 20), suffixIcon: IconButton(icon: Icon(obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined, size: 20), onPressed: () => setState(() => obscure = !obscure)))),
      const SizedBox(height: 20),
      Row(children: [
        Expanded(child: PButton(text: l.back, icon: Icons.arrow_back, horizontalPadding: 16, onPressed: () { setState(() => step--); }, isOutlined: true)),
        const SizedBox(width: 12),
        Expanded(child: PButton(text: l.continueApp, icon: Icons.arrow_forward, horizontalPadding: 16, onPressed: _nextStep)),
      ]),
    ]));
  }

  Widget _step3() {
    final l = AppLocalizations.of(context)!;
    return SingleChildScrollView(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Choose Role', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: DS.inkC(context))),
      const SizedBox(height: 6),
      Text('How will you use the app?', style: TextStyle(fontSize: 13, color: DS.mutedC(context))),
      const SizedBox(height: 24),
      _roleCard(Icons.person_outline, 'Customer', 'Book salon services and track queue', 'customer'),
      const SizedBox(height: 12),
      _roleCard(Icons.store_outlined, 'Salon Owner', l.shopSettings, 'owner'),
      if (role == 'owner') ...[
        const SizedBox(height: 16),
        TextField(controller: shopCnt, style: TextStyle(color: DS.inkC(context)), decoration: DS.inputDecoration(context).copyWith(labelText: l.shopName, hintText: 'Your Salon Name', prefixIcon: const Icon(Icons.store, size: 20))),
        const SizedBox(height: 16),
        TextField(controller: partnerCodeCnt, style: TextStyle(color: DS.inkC(context)), decoration: DS.inputDecoration(context).copyWith(labelText: 'Partner Code (Optional)', hintText: 'Enter partner code if any', prefixIcon: const Icon(Icons.card_giftcard, size: 20))),
      ],
      const SizedBox(height: 20),
      InkWell(
        onTap: () => setState(() => agreeToTerms = !agreeToTerms),
        borderRadius: BorderRadius.circular(DS.rMd),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Checkbox(value: agreeToTerms, onChanged: (v) => setState(() => agreeToTerms = v ?? false), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4))),
          const SizedBox(width: 8),
          Expanded(child: Padding(
            padding: const EdgeInsets.only(top: 10),
            child: Text.rich(
              TextSpan(style: TextStyle(fontSize: 12, color: DS.mutedC(context), height: 1.4), children: [
                const TextSpan(text: 'I agree to the '),
                WidgetSpan(child: GestureDetector(onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LegalPage(title: 'Terms of Service', assetPath: 'docs/TERMS_OF_SERVICE.md'))), child: const Text('Terms of Service', style: TextStyle(color: DS.primary, fontWeight: FontWeight.w700)))),
                const TextSpan(text: ' and '),
                WidgetSpan(child: GestureDetector(onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LegalPage(title: 'Privacy Policy', assetPath: 'docs/PRIVACY_POLICY.md'))), child: const Text('Privacy Policy', style: TextStyle(color: DS.primary, fontWeight: FontWeight.w700)))),
              ]),
            ),
          )),
        ]),
      ),
      const SizedBox(height: 12),
      Row(children: [
        Expanded(child: PButton(text: l.back, icon: Icons.arrow_back, horizontalPadding: 16, onPressed: () { setState(() => step--); }, isOutlined: true)),
        const SizedBox(width: 12),
        Expanded(child: PButton(text: l.register, icon: Icons.check, horizontalPadding: 16, onPressed: _register, loading: loading, isGold: true)),
      ]),
    ]));
  }

  Widget _roleCard(IconData icon, String title, String desc, String value) {
    final selected = role == value;
    return GestureDetector(
      onTap: () => setState(() => role = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: selected ? DS.primary.withValues(alpha: 0.06) : DS.surfaceC(context),
          borderRadius: BorderRadius.circular(DS.rLg),
          border: Border.all(color: selected ? DS.primary : DS.borderC(context), width: selected ? 2 : 1),
        ),
        child: Row(children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: selected ? DS.primary : DS.pageC(context), borderRadius: BorderRadius.circular(DS.rMd)),
            child: Icon(icon, color: selected ? Colors.white : DS.mutedC(context), size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: selected ? DS.primary : DS.inkC(context))),
            const SizedBox(height: 2),
            Text(desc, style: TextStyle(color: DS.mutedC(context), fontSize: 12)),
          ])),
          if (selected) const Icon(Icons.check_circle, color: DS.primary, size: 22),
        ]),
      ),
    );
  }
}
