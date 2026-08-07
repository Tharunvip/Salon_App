import 'dart:math';
import 'package:flutter/material.dart';
import 'design_system.dart';
import 'firebase_service.dart';
import 'models.dart';
import 'package:salon_app/l10n/app_localizations.dart';
import 'services/offline_guard.dart';
import 'services/payment_gateway.dart';
import 'widgets/premium_card.dart';
import 'widgets/premium_button.dart';

class PaymentPage extends StatefulWidget {
  final Shop shop;
  final ShopService service;
  final AppUser user;
  final String scheduledDate;
  final String preferredTime1;
  final String preferredTime2;
  final String preferredTime3;
  final bool isPremium;

  const PaymentPage({
    super.key,
    required this.shop,
    required this.service,
    required this.user,
    required this.scheduledDate,
    required this.preferredTime1,
    this.preferredTime2 = '',
    this.preferredTime3 = '',
    this.isPremium = false,
  });

  @override
  State<PaymentPage> createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage> with TickerProviderStateMixin {
  final svc = FirebaseService();
  String selectedPayment = 'UPI';
  bool loading = false;
  bool _paid = false;
  Booking? _booking;

  late AnimationController _fadeCtrl;
  late Animation<double> _fadeAnim;
  late AnimationController _slideCtrl;
  late Animation<Offset> _slideAnim;

  late AnimationController _confettiCtrl;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _slideCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    _slideAnim = Tween<Offset>(begin: const Offset(0, 0.05), end: Offset.zero).animate(
      CurvedAnimation(parent: _slideCtrl, curve: Curves.easeOut),
    );
    _confettiCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 2000))..repeat();
    _fadeCtrl.forward();
    _slideCtrl.forward();
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    _slideCtrl.dispose();
    _confettiCtrl.dispose();
    super.dispose();
  }

  int get payNow => widget.isPremium ? (widget.shop.premiumBookingPrice > 0 ? widget.shop.premiumBookingPrice : widget.shop.bookingPrice) : widget.shop.bookingPrice;

  int _premiumDaysAhead(String date) {
    final dt = DateTime.tryParse(date);
    if (dt == null) return 0;
    final today = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
    return dt.difference(today).inDays;
  }

  Future<void> doPayment() async {
    final l = AppLocalizations.of(context)!;
    if (!widget.shop.isOpen) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l.notifShopClosed), behavior: SnackBarBehavior.floating),
      );
      return;
    }
    if (!widget.shop.bookingsAvailable) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l.notifBookingsUnavailable), behavior: SnackBarBehavior.floating),
      );
      return;
    }
    setState(() => loading = true);
    try {
      final payment = await paymentGateway.pay(
        amount: payNow,
        reference: widget.shop.shopName,
        customerName: widget.user.name,
        customerMobile: widget.user.mobile,
        customerEmail: widget.user.email,
      );
      if (!payment.success) {
        throw Exception(payment.error ?? 'Payment was cancelled.');
      }
      final booking = await svc.createBooking(
        shop: widget.shop,
        service: widget.service,
        paymentMethod: selectedPayment,
        customerName: widget.user.name,
        customerMobile: widget.user.mobile,
        isPremium: widget.isPremium,
        premiumDaysAhead: widget.isPremium ? _premiumDaysAhead(widget.scheduledDate) : 0,
        premiumExtraPrice: widget.isPremium ? payNow : 0,
        scheduledDate: widget.scheduledDate,
        preferredTime1: widget.preferredTime1,
        preferredTime2: widget.preferredTime2,
        preferredTime3: widget.preferredTime3,
      );
      if (!mounted) return;
      setState(() {
        _booking = booking;
        _paid = true;
      });
      if (!mounted) return;
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(friendlyError(e)), behavior: SnackBarBehavior.floating),
      );
    }
    if (mounted) setState(() => loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Checkout', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 20, letterSpacing: -0.3)),
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios), onPressed: () => Navigator.pop(context)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(gradient: isDark ? DS.gradientDarkBg : DS.gradientBg),
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnim,
            child: SlideTransition(
              position: _slideAnim,
              child: _paid ? _buildConfirmation() : _buildPaymentForm(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPaymentForm() {
    final l = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: [
        GlassCard(
          padding: const EdgeInsets.all(24),
          child: Column(children: [
            Container(padding: const EdgeInsets.all(16), decoration: const BoxDecoration(color: DS.primaryVeryLight, shape: BoxShape.circle), child: const Icon(Icons.receipt_long, color: DS.primary, size: 32)),
            const SizedBox(height: 16),
            Text(l.bookingSummary, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, letterSpacing: -0.3, color: isDark ? DS.darkInk : DS.ink)),
          ]),
        ),
        const SizedBox(height: 16),
        if (widget.isPremium) ...[
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: DS.gradientGold,
              borderRadius: BorderRadius.circular(DS.rLg),
              boxShadow: [DS.shadowGold],
            ),
            child: Row(children: [
              const Icon(Icons.workspace_premium, color: Colors.white, size: 24),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Premium Booking', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: -0.3)),
                const SizedBox(height: 2),
                Text('You picked your exact slot — the owner will confirm it', style: TextStyle(color: Colors.white.withValues(alpha: 0.9), fontSize: 12)),
              ])),
            ]),
          ),
          const SizedBox(height: 16),
        ],
        GlassCard(
          child: Column(children: [
            _infoTile(Icons.store, widget.shop.shopName, widget.shop.location, isDark),
            const Divider(height: 1, indent: 16, endIndent: 16),
            _infoTile(Icons.content_cut, widget.service.name, '${widget.service.durationMinutes} ${l.minutes}', isDark),
            const Divider(height: 1, indent: 16, endIndent: 16),
            _infoTile(Icons.calendar_today, l.date, widget.scheduledDate, isDark, valueColor: DS.accent),
            const Divider(height: 1, indent: 16, endIndent: 16),
            _infoTile(widget.isPremium ? Icons.schedule : Icons.looks_one, widget.isPremium ? 'Your Time' : '1st Preference', widget.preferredTime1, isDark, valueColor: DS.accent),
            if (widget.preferredTime2.isNotEmpty) ...[
              const Divider(height: 1, indent: 16, endIndent: 16),
              _infoTile(Icons.looks_two, '2nd Preference', widget.preferredTime2, isDark, valueColor: DS.accent),
            ],
            if (widget.preferredTime3.isNotEmpty) ...[
              const Divider(height: 1, indent: 16, endIndent: 16),
              _infoTile(Icons.looks_3, '3rd Preference', widget.preferredTime3, isDark, valueColor: DS.accent),
            ],
          ]),
        ),
        const SizedBox(height: 16),
        GlassCard(
          child: Column(children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(children: [
                Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: DS.primaryVeryLight, borderRadius: BorderRadius.circular(DS.rMd)), child: const Icon(Icons.payments, color: DS.primary, size: 20)),
                const SizedBox(width: 14),
                Expanded(child: Text(l.paymentMethods, overflow: TextOverflow.ellipsis, maxLines: 1, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: isDark ? DS.darkInk : DS.ink))),
              ]),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Row(children: ['UPI', 'Card'].map((m) {
                final sel = selectedPayment == m;
                final label = m == 'UPI' ? l.upi : l.card;
                return Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => selectedPayment = m),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        color: sel ? (isDark ? DS.primary.withValues(alpha: 0.2) : DS.primaryVeryLight) : Colors.transparent,
                        borderRadius: BorderRadius.circular(DS.rMd),
                        border: Border.all(color: sel ? DS.primary : (isDark ? DS.darkBorder : DS.border), width: sel ? 1.5 : 1),
                      ),
                      child: Column(children: [
                        Icon(m == 'UPI' ? Icons.phone_android : m == 'Card' ? Icons.credit_card : Icons.money, color: sel ? DS.primary : DS.muted, size: 22),
                        const SizedBox(height: 4),
                        Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: sel ? DS.primary : DS.muted)),
                      ]),
                    ),
                  ),
                );
              }).toList()),
            ),
          ]),
        ),
        const SizedBox(height: 16),
        GlassCard(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(children: [
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Flexible(child: Text(widget.isPremium ? 'Premium Booking Fee' : 'Booking Fee', overflow: TextOverflow.ellipsis, style: TextStyle(color: isDark ? DS.darkMuted : DS.muted, fontSize: 14))),
                const SizedBox(width: 8),
                Flexible(child: Text('${l.currency}$payNow', overflow: TextOverflow.ellipsis, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: isDark ? DS.darkInk : DS.ink))),
              ]),
            ]),
          ),
        ),
        const SizedBox(height: 24),
        PButton(
          text: 'Pay ${l.currency}$payNow & Book',
          icon: Icons.shopping_cart_checkout,
          onPressed: doPayment,
          loading: loading,
        ),
        const SizedBox(height: 8),
        Center(child: Text('Dummy payment — no real charge', style: TextStyle(color: isDark ? DS.darkMuted : DS.muted, fontSize: 11, fontStyle: FontStyle.italic))),
      ],
    );
  }

  Widget _buildConfirmation() {
    final l = AppLocalizations.of(context)!;
    final b = _booking!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: [
        const SizedBox(height: 20),
        _buildSuccessAnimation(isDark),
        const SizedBox(height: 24),
        GlassCard(
          padding: const EdgeInsets.all(24),
          child: Column(children: [
            Text('Booking Sent!', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, letterSpacing: -0.5, color: isDark ? DS.darkInk : DS.ink)),
            const SizedBox(height: 6),
            Text(widget.shop.shopName, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: DS.primary)),
          ]),
        ),
        const SizedBox(height: 16),
        GlassCard(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(children: [
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Flexible(child: Text('${l.token} Number', overflow: TextOverflow.ellipsis, maxLines: 1, style: TextStyle(color: isDark ? DS.darkMuted : DS.muted, fontSize: 13))),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(color: DS.primaryVeryLight, borderRadius: BorderRadius.circular(DS.rMd)),
                  child: FittedBox(fit: BoxFit.scaleDown, child: Text('#${b.token}', style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: DS.primary))),
                ),
              ]),
              const Divider(height: 24),
              _confRow('Date', widget.scheduledDate, isDark, DS.accent),
              _confRow(widget.isPremium ? 'Your Time' : '1st Preference', widget.preferredTime1, isDark, DS.accent),
              if (widget.preferredTime2.isNotEmpty) _confRow('2nd Preference', widget.preferredTime2, isDark, DS.accent),
              if (widget.preferredTime3.isNotEmpty) _confRow('3rd Preference', widget.preferredTime3, isDark, DS.accent),
              const Divider(height: 16),
              _confRow(l.services, widget.service.name, isDark),
              _confRow(widget.isPremium ? 'Premium Fee Paid' : 'Booking Fee Paid', '${l.currency}$payNow', isDark, DS.success),
            ]),
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: DS.accentLight.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(DS.rLg),
            border: Border.all(color: DS.accent.withValues(alpha: 0.3)),
          ),
          child: Row(children: [
            const Icon(Icons.hourglass_top, color: DS.accent, size: 28),
            const SizedBox(width: 14),
            Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Waiting for Owner Confirmation', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: isDark ? DS.darkInk : DS.ink)),
                const SizedBox(height: 4),
                Text('Your booking has been sent to ${widget.shop.shopName}. The owner will confirm your appointment time shortly.', style: TextStyle(fontSize: 13, height: 1.5, color: isDark ? DS.darkMuted : DS.muted)),
              ],
            )),
          ]),
        ),
        const SizedBox(height: 24),
        PButton(text: 'Done', icon: Icons.arrow_forward, onPressed: () => Navigator.pop(context), isGold: true),
      ],
    );
  }

  Widget _buildSuccessAnimation(bool isDark) {
    return SizedBox(
      height: 120,
      child: Stack(
        alignment: Alignment.center,
        children: [
          ...List.generate(5, (i) {
            final delay = i * 200;
            return TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: 1.0),
              duration: Duration(milliseconds: 600 + delay),
              curve: Curves.easeOutBack,
              builder: (c, v, _) {
                final opacity = ((1 - v) * 0.3).clamp(0.0, 1.0);
                final scale = 1 + v * 1.5;
                return Opacity(opacity: opacity, child: Transform.scale(scale: scale, child: const Icon(Icons.circle, size: 60, color: DS.accent)));

              },
            );
          }),
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: 1.0),
            duration: const Duration(milliseconds: 800),
            curve: Curves.easeOutBack,
            builder: (c, v, _) => Transform.scale(
              scale: v,
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: DS.gradientGold,
                  shape: BoxShape.circle,
                  boxShadow: [BoxShadow(color: DS.accent.withValues(alpha: 0.4), blurRadius: 32, offset: const Offset(0, 8))],
                ),
                child: const Icon(Icons.check, color: Colors.white, size: 40),
              ),
            ),
          ),
          ...List.generate(12, (i) {
            final angle = (i / 12) * 3.14159 * 2;
            return AnimatedBuilder(
              animation: _confettiCtrl,
              builder: (c, _) {
                final dist = 30 + _confettiCtrl.value * 40;
                final opacity = (1 - _confettiCtrl.value).clamp(0.0, 0.5);
                return Positioned(
                  left: 60 + dist * 0.7 * cos(angle + _confettiCtrl.value * 2),
                  top: 60 + dist * 0.7 * sin(angle + _confettiCtrl.value * 2),
                  child: Opacity(
                    opacity: opacity,
                    child: Container(
                      width: 6, height: 6,
                      decoration: BoxDecoration(color: [DS.accent, DS.primary, DS.success, DS.accent][i % 4], shape: BoxShape.circle),
                    ),
                  ),
                );
              },
            );
          }),
        ],
      ),
    );
  }

  Widget _infoTile(IconData icon, String label, String value, bool isDark, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(children: [
        Icon(icon, color: DS.primary, size: 20),
        const SizedBox(width: 12),
        Expanded(child: Text(label, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 14, color: isDark ? DS.darkMuted : DS.muted))),
        const SizedBox(width: 8),
        Flexible(child: Text(value, overflow: TextOverflow.ellipsis, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: valueColor ?? (isDark ? DS.darkInk : DS.ink)))),
      ]),
    );
  }

  Widget _confRow(String label, String value, bool isDark, [Color? valueColor]) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(children: [
        Expanded(child: Text(label, overflow: TextOverflow.ellipsis, style: TextStyle(color: isDark ? DS.darkMuted : DS.muted, fontSize: 14))),
        const SizedBox(width: 8),
        Flexible(child: Text(value, overflow: TextOverflow.ellipsis, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: valueColor ?? (isDark ? DS.darkInk : DS.ink)))),
      ]),
    );
  }

}
