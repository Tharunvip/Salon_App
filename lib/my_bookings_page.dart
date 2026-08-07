import 'dart:async';
import 'package:flutter/material.dart';
import 'package:salon_app/l10n/app_localizations.dart';
import 'firebase_service.dart';
import 'models.dart';
import 'design_system.dart';
import 'services/notification_service.dart';
import 'services/offline_guard.dart';
import 'services/payment_gateway.dart';
import 'widgets/premium_button.dart';
import 'widgets/shimmer.dart';
import 'widgets/empty_state.dart';
import 'widgets/section_header.dart';

class MyBookingsPage extends StatefulWidget {
  final AppUser user;
  const MyBookingsPage({super.key, required this.user});

  @override
  State<MyBookingsPage> createState() => _MyBookingsPageState();
}

class _MyBookingsPageState extends State<MyBookingsPage> with SingleTickerProviderStateMixin {
  final svc = FirebaseService();
  late AnimationController _staggerCtrl;
  late Animation<double> _stagger;

  @override
  void initState() {
    super.initState();
    _staggerCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _stagger = CurvedAnimation(parent: _staggerCtrl, curve: DS.easeOut);
    _staggerCtrl.forward();
  }

  @override
  void dispose() { _staggerCtrl.dispose(); super.dispose(); }

  Widget _buildStaggered(double delay, Widget child) {
    return AnimatedBuilder(
      animation: _staggerCtrl,
      builder: (c, _) {
        final t = ((_stagger.value - delay) / (1 - delay)).clamp(0.0, 1.0);
        return Opacity(opacity: t, child: Transform.translate(offset: Offset(0, 20 * (1 - Curves.easeOut.transform(t))), child: child));
      },
    );
  }

  Future<void> _cancelBooking(Booking b) async {
    final l = AppLocalizations.of(context)!;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(DS.rXxl)),
        title: Text(l.cancelBooking),
        content: Text('${l.cancelBooking} ${l.tokenNumber(b.token)}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: Text(l.no)),
          TextButton(onPressed: () => Navigator.pop(c, true), child: Text(l.yes, style: const TextStyle(color: DS.error))),
        ],
      ),
    );
    if (confirm == true) {
      try {
        await svc.cancelBooking(b.id);
        await NotificationService().cancelReminder(b.id);
        if (mounted) _msg(l.bookingCancelled);
      } catch (e) {
        _msg('${l.error}: $e');
      }
    }
  }

  void _msg(String m) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m), behavior: SnackBarBehavior.floating));

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final isDark = DS.isDark(context);
    return Container(
      decoration: BoxDecoration(gradient: isDark ? DS.gradientDarkBg : DS.gradientBg),
      child: SafeArea(
        bottom: false,
        child: StreamBuilder<List<Booking>>(
          stream: svc.watchCustomerBookings(widget.user.uid),
          builder: (c, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return Column(children: [
                _header(context, l: l, active: 0, past: 0),
                const Expanded(child: Padding(padding: EdgeInsets.all(16), child: ShimmerShopCard())),
              ]);
            }
            final bookings = snap.data ?? [];
            if (bookings.isEmpty) {
              return Column(children: [
                _header(context, l: l, active: 0, past: 0),
                Expanded(child: EmptyState(icon: Icons.event_busy, title: l.noBookings, subtitle: 'Time to treat yourself!')),
              ]);
            }

            final active = bookings.where((b) =>
                b.status == 'pending_owner_confirmation' ||
                b.status == 'confirmed' ||
                b.status == 'in_progress' ||
                (b.status == 'completed' && !b.isPaid && b.remainingAmount > 0)).toList();
            final past = bookings.where((b) =>
                b.status == 'paid' ||
                (b.status == 'completed' && b.isPaid) ||
                b.status == 'cancelled').toList();

            return Column(children: [
              _header(context, l: l, active: active.length, past: past.length),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () async => setState(() {}),
                  color: DS.primary,
                  child: AnimatedSwitcher(
                    duration: DS.fast,
                    child: ListView(
                      key: ValueKey('${active.length}-${past.length}'),
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 110),
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: [
                        if (active.isNotEmpty) ...[
                          _buildStaggered(0.0, SectionHeader(
                            title: 'Active Bookings',
                            subtitle: l.chooseService,
                            icon: Icons.auto_awesome,
                            trailing: _countBadge(active.length, DS.primary),
                          )),
                          const SizedBox(height: 12),
                          ...active.asMap().entries.map((entry) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _buildStaggered(0.1 + entry.key * 0.05, _BookingCard(
                              key: ValueKey(entry.value.id),
                              booking: entry.value,
                              onCancel: entry.value.status == 'confirmed' && !entry.value.reachedShop
                                  ? () => _cancelBooking(entry.value)
                                  : null,
                            )),
                          )),
                          const SizedBox(height: 24),
                        ],
                        if (past.isNotEmpty) ...[
                          _buildStaggered(0.3, SectionHeader(
                            title: 'Past Bookings',
                            subtitle: 'Your booking history',
                            icon: Icons.history,
                            trailing: _countBadge(past.length, DS.muted),
                          )),
                          const SizedBox(height: 12),
                          ...past.asMap().entries.map((entry) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _buildStaggered(0.4 + entry.key * 0.03, _BookingCard(
                              key: ValueKey(entry.value.id),
                              booking: entry.value,
                              onCancel: null,
                            )),
                          )),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ]);
          },
        ),
      ),
    );
  }

  Widget _countBadge(int count, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(DS.rFull)),
      child: Text('$count', style: TextStyle(fontWeight: FontWeight.w800, color: color, fontSize: 13)),
    );
  }

  Widget _header(BuildContext context, {required AppLocalizations l, required int active, required int past}) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [DS.primaryDark, DS.primary, DS.teal], begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(DS.rXl),
        boxShadow: [DS.shadowPrimary],
      ),
      child: Stack(children: [
        Positioned(right: -26, top: -26, child: Container(width: 120, height: 120, decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withValues(alpha: 0.06)))),
        Positioned(right: 26, bottom: -34, child: Container(width: 100, height: 100, decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: DS.accent.withValues(alpha: 0.4), width: 12)))),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.14), borderRadius: BorderRadius.circular(DS.rMd), border: Border.all(color: Colors.white.withValues(alpha: 0.18))),
              child: const Icon(Icons.event_note, color: DS.accent, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(l.myBookings, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: -0.4)),
              const SizedBox(height: 2),
              Text('Track your appointments & tokens', style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 13)),
            ])),
          ]),
          const SizedBox(height: 16),
          Row(children: [
            Expanded(child: _heroStat(label: 'Active', value: '$active', color: DS.accent)),
            const SizedBox(width: 10),
            Expanded(child: _heroStat(label: 'Past', value: '$past', color: DS.successLight)),
            const SizedBox(width: 10),
            Expanded(child: _heroStat(label: 'Total', value: '${active + past}', color: Colors.white)),
          ]),
        ]),
      ]),
    );
  }

  Widget _heroStat({required String label, required String value, required Color color}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(DS.rMd), border: Border.all(color: Colors.white.withValues(alpha: 0.14))),
      child: Column(children: [
        Text(value, style: TextStyle(fontSize: 19, fontWeight: FontWeight.w900, color: color)),
        const SizedBox(height: 1),
        Text(label.toUpperCase(), style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w700, letterSpacing: 0.9, color: Colors.white70)),
      ]),
    );
  }
}

class _BookingCard extends StatefulWidget {
  final Booking booking;
  final VoidCallback? onCancel;

  const _BookingCard({super.key, required this.booking, this.onCancel});

  @override
  State<_BookingCard> createState() => _BookingCardState();
}

class _BookingCardState extends State<_BookingCard> {
  final svc = FirebaseService();
  Map<String, dynamic>? _prediction;
  bool _loadingPrediction = false;
  Timer? _predTimer;
  String _payMethod = 'UPI';
  bool _paying = false;

  @override
  void initState() {
    super.initState();
    if (widget.booking.scheduledDate.isEmpty) {
      _loadPrediction();
      _predTimer = Timer.periodic(const Duration(seconds: 10), (_) => _loadPrediction());
    }
  }

  @override
  void dispose() { _predTimer?.cancel(); super.dispose(); }

  Future<void> _loadPrediction() async {
    final b = widget.booking;
    if (b.status != 'confirmed' && b.status != 'in_progress') return;
    if (b.scheduledDate.isNotEmpty) return;
    if (_loadingPrediction) return;
    _loadingPrediction = true;
    try {
      final pred = await svc.getCustomerQueueInfo(b.ownerId, b.token);
      if (mounted) setState(() => _prediction = pred);
    } catch (_) {}
    _loadingPrediction = false;
  }

  ({Color color, Color dark, IconData icon, String label}) _statusMeta(String status) => switch (status) {
    'pending_owner_confirmation' => (color: DS.warning, dark: const Color(0xFFB45309), icon: Icons.hourglass_top, label: 'Pending'),
    'confirmed' => (color: DS.primary, dark: const Color(0xFF00695C), icon: Icons.check_circle_outline, label: 'Confirmed'),
    'in_progress' => (color: DS.accent, dark: const Color(0xFFB8962E), icon: Icons.bolt, label: 'In Progress'),
    'paid' => (color: DS.teal, dark: const Color(0xFF0D9488), icon: Icons.payments_outlined, label: 'Paid'),
    'completed' => (color: DS.success, dark: const Color(0xFF059669), icon: Icons.task_alt, label: 'Completed'),
    'cancelled' => (color: DS.error, dark: const Color(0xFFDC2626), icon: Icons.cancel_outlined, label: 'Cancelled'),
    _ => (color: DS.muted, dark: DS.muted, icon: Icons.event_note, label: status),
  };

  Widget _statusChip(String label, Color color, {IconData? icon}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(DS.rFull), border: Border.all(color: color.withValues(alpha: 0.25))),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        if (icon != null) ...[Icon(icon, size: 12, color: color), const SizedBox(width: 5)],
        Text(label.toUpperCase(), maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w800, color: color, letterSpacing: 0.6)),
      ]),
    );
  }

  Widget _infoTile(BuildContext context, {required IconData icon, required String label, required String value, required Color color}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(DS.rMd),
        border: Border.all(color: color.withValues(alpha: 0.14)),
      ),
      child: Row(children: [
        Container(
          padding: const EdgeInsets.all(5),
          decoration: BoxDecoration(color: color.withValues(alpha: 0.14), borderRadius: BorderRadius.circular(DS.rSm)),
          child: Icon(icon, size: 13, color: color),
        ),
        const SizedBox(width: 8),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label.toUpperCase(), maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 8.5, fontWeight: FontWeight.w700, letterSpacing: 0.5, color: DS.mutedC(context))),
          const SizedBox(height: 1),
          Text(value, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800, color: DS.inkC(context))),
        ])),
      ]),
    );
  }

  List<Widget> _buildRemainingPayment(BuildContext context, Booking b) {
    final l = AppLocalizations.of(context)!;
    final isDark = DS.isDark(context);
    final widgets = <Widget>[];
    if (b.offlinePaymentRequested) {
      widgets.add(Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: DS.warning.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(DS.rMd),
            border: Border.all(color: DS.warning.withValues(alpha: 0.3)),
          ),
          child: Row(children: [
            const Icon(Icons.hourglass_top, size: 18, color: DS.warning),
            const SizedBox(width: 10),
            Expanded(child: Text('Cash payment of ${l.currency}${b.remainingAmount} requested. The owner will confirm once they receive it.', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: DS.warning, height: 1.4))),
          ]),
        ),
      ));
    } else {
      widgets.add(Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Pay Remaining ${l.currency}${b.remainingAmount}', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: isDark ? DS.darkInk : DS.ink)),
          const SizedBox(height: 10),
          Row(children: ['UPI', 'Card', 'Cash'].map((m) {
            final sel = _payMethod == m;
            final label = m == 'UPI' ? l.upi : m == 'Card' ? l.card : l.cash;
            return Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _payMethod = m),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: sel ? (isDark ? DS.primary.withValues(alpha: 0.2) : DS.primaryVeryLight) : Colors.transparent,
                    borderRadius: BorderRadius.circular(DS.rMd),
                    border: Border.all(color: sel ? DS.primary : (isDark ? DS.darkBorder : DS.border), width: sel ? 1.5 : 1),
                  ),
                  child: Column(children: [
                    Icon(m == 'UPI' ? Icons.phone_android : m == 'Card' ? Icons.credit_card : Icons.money, color: sel ? DS.primary : DS.muted, size: 20),
                    const SizedBox(height: 3),
                    Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: sel ? DS.primary : DS.muted)),
                  ]),
                ),
              ),
            );
          }).toList()),
          const SizedBox(height: 12),
          PButton(
            text: _payMethod == 'Cash' ? 'Pay Cash at Shop' : '${l.payRemaining} ${l.currency}${b.remainingAmount}',
            icon: _payMethod == 'Cash' ? Icons.money : Icons.payments,
            isGold: true,
            loading: _paying,
            onPressed: () => _payRemaining(b),
          ),
        ]),
      ));
    }
    return widgets;
  }

  Future<void> _payRemaining(Booking b) async {
    final l = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _paying = true);
    try {
      if (_payMethod == 'Cash') {
        await svc.requestOfflinePayment(
          bookingId: b.id,
          ownerId: b.ownerId,
          customerId: b.customerId,
          customerName: b.customerName,
          serviceName: b.serviceName,
          remainingAmount: b.remainingAmount,
        );
        messenger.showSnackBar(const SnackBar(
          content: Text('Cash payment requested. The owner will confirm once they receive it.'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: DS.warning,
        ));
      } else {
        final payment = await paymentGateway.pay(
          amount: b.remainingAmount,
          reference: b.shopName,
          customerName: b.customerName,
          customerMobile: b.customerMobile,
        );
        if (!payment.success) {
          messenger.showSnackBar(const SnackBar(
            content: Text('Payment was cancelled.'),
            behavior: SnackBarBehavior.floating,
          ));
          return;
        }
        await svc.payRemaining(b.id, paymentMethod: _payMethod);
        messenger.showSnackBar(SnackBar(
          content: Text('${l.remainingAmount} ${l.currency}${b.remainingAmount} ${l.paid}!'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: DS.success,
        ));
      }
    } catch (e) {
      messenger.showSnackBar(SnackBar(
        content: Text(friendlyError(e)),
        behavior: SnackBarBehavior.floating,
      ));
    }
    if (mounted) setState(() => _paying = false);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final b = widget.booking;
    final isDark = DS.isDark(context);
    final m = _statusMeta(b.status);

    final tiles = <Widget>[
      _infoTile(context, icon: Icons.payments_outlined, label: l.price, value: '${l.currency}${b.price}', color: DS.primary),
      if (b.scheduledDate.isNotEmpty)
        _infoTile(context, icon: Icons.event_outlined, label: l.date, value: b.scheduledDate, color: DS.info)
      else if (b.paymentMethod.isNotEmpty)
        _infoTile(context, icon: Icons.account_balance_wallet_outlined, label: 'Payment', value: b.paymentMethod, color: DS.purple),
      if (b.scheduledTime.isNotEmpty)
        _infoTile(context, icon: Icons.schedule, label: 'Confirmed Time', value: b.scheduledTime, color: DS.success),
      if (b.preferredTime1.isNotEmpty)
        _infoTile(context, icon: Icons.access_time, label: '1st Preference', value: b.preferredTime1, color: DS.accent),
      if (b.preferredTime2.isNotEmpty)
        _infoTile(context, icon: Icons.access_time_filled, label: '2nd Preference', value: b.preferredTime2, color: DS.accent),
      if (b.preferredTime3.isNotEmpty)
        _infoTile(context, icon: Icons.more_time, label: '3rd Preference', value: b.preferredTime3, color: DS.accent),
      if (b.remainingAmount > 0)
        _infoTile(context, icon: Icons.account_balance_wallet_outlined, label: l.remainingAmount, value: '${l.currency}${b.remainingAmount}', color: DS.warning),
      if (b.paymentMethod.isNotEmpty && (b.offlinePaymentRequested || b.isPaid))
        _infoTile(context, icon: Icons.payments_outlined, label: 'Payment', value: b.paymentMethod == 'Cash' ? 'Cash (Offline)' : b.paymentMethod, color: DS.purple),
      if (b.status == 'cancelled' && b.cancelledAt != null)
        _infoTile(context, icon: Icons.event_busy, label: l.statusCancelled, value: '${b.cancelledAt!.day}/${b.cancelledAt!.month}/${b.cancelledAt!.year}', color: DS.error),
      if (b.chairNumber != null)
        _infoTile(context, icon: Icons.weekend_outlined, label: 'Chair', value: '#${b.chairNumber}', color: DS.purple),
      if (b.isPremium)
        _infoTile(context, icon: Icons.workspace_premium, label: 'Premium', value: b.premiumDaysAhead > 0 ? '${b.premiumDaysAhead} days ahead' : 'Premium Booking', color: DS.gold),
    ];

    final infoRows = <Widget>[];
    for (var i = 0; i < tiles.length; i += 2) {
      infoRows.add(Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Expanded(child: tiles[i]),
        if (i + 1 < tiles.length) ...[const SizedBox(width: 8), Expanded(child: tiles[i + 1])],
      ]));
      infoRows.add(const SizedBox(height: 8));
    }

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(DS.rXl),
        gradient: LinearGradient(
          colors: isDark ? [DS.darkCard, m.color.withValues(alpha: 0.10)] : [Colors.white, m.color.withValues(alpha: 0.035)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: m.color.withValues(alpha: 0.22)),
        boxShadow: isDark ? null : [BoxShadow(color: m.color.withValues(alpha: 0.09), blurRadius: 18, offset: const Offset(0, 8))],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
            Container(
              width: 62, height: 62,
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [m.color, m.dark], begin: Alignment.topLeft, end: Alignment.bottomRight),
                borderRadius: BorderRadius.circular(DS.rLg),
                boxShadow: [BoxShadow(color: m.color.withValues(alpha: 0.35), blurRadius: 14, offset: const Offset(0, 6))],
              ),
              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                Text(l.token.toUpperCase(), style: const TextStyle(color: Colors.white, fontSize: 7, fontWeight: FontWeight.w800, letterSpacing: 1.2)),
                const SizedBox(height: 1),
                FittedBox(fit: BoxFit.scaleDown, child: Text(l.tokenNumber(b.token), style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900))),
              ]),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Container(
                    width: 28, height: 28,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(gradient: DS.gradientGold, borderRadius: BorderRadius.circular(DS.rSm)),
                    child: Text(b.shopName.isNotEmpty ? b.shopName[0].toUpperCase() : '?', style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w800)),
                  ),
                  const SizedBox(width: 8),
                  Expanded(child: Text(b.shopName, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 15.5, fontWeight: FontWeight.w800, color: DS.inkC(context), letterSpacing: -0.3))),
                ]),
                const SizedBox(height: 4),
                Text(b.serviceName, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 13, color: DS.mutedC(context))),
              ]),
            ),
          ]),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: Row(children: [
            _statusChip(m.label, m.color, icon: m.icon),
            if (b.reachedShop) ...[
              const SizedBox(width: 8),
              _statusChip('Arrived', DS.success, icon: Icons.check_circle),
            ],
            const Spacer(),
            if (b.status == 'in_progress')
              _statusChip('LIVE', DS.error, icon: Icons.fiber_manual_record),
          ]),
        ),
        const SizedBox(height: 14),
        if (tiles.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(children: infoRows),
          ),
        ..._buildBanners(context, l),
        const SizedBox(height: 4),
      ]),
    );
  }

  List<Widget> _buildBanners(BuildContext context, AppLocalizations l) {
    final b = widget.booking;
    final list = <Widget>[];

    if (b.status == 'confirmed' && b.scheduledDate.isNotEmpty && b.scheduledTime.isNotEmpty) {
      list.add(Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [DS.success.withValues(alpha: 0.15), DS.success.withValues(alpha: 0.05)]),
            borderRadius: BorderRadius.circular(DS.rMd),
            border: Border.all(color: DS.success.withValues(alpha: 0.25)),
          ),
          child: Row(children: [
            const Icon(Icons.verified, size: 20, color: DS.success),
            const SizedBox(width: 10),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Appointment Confirmed', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: DS.success)),
              const SizedBox(height: 2),
              Text('${b.scheduledDate} at ${b.scheduledTime}', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: DS.success.withValues(alpha: 0.85))),
            ])),
          ]),
        ),
      ));
      list.add(const SizedBox(height: 12));
    }

    if (b.status == 'confirmed' && b.scheduledDate.isEmpty && _prediction != null) {
      list.add(Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [DS.accent.withValues(alpha: 0.12), DS.accent.withValues(alpha: 0.04)]),
            borderRadius: BorderRadius.circular(DS.rMd),
            border: Border.all(color: DS.accent.withValues(alpha: 0.25)),
          ),
          child: Row(children: [
            const Icon(Icons.timer_outlined, size: 20, color: DS.accent),
            const SizedBox(width: 10),
            Expanded(child: Text(
              _prediction!['ahead'] > 0
                  ? '${l.customersAhead(_prediction!['ahead'])} · ~${_prediction!['estimatedMinutes']} ${l.minutes}'
                  : '${l.notifYourTurnIsNear} · ~${_prediction!['estimatedMinutes']} ${l.minutes}',
              style: const TextStyle(fontWeight: FontWeight.w700, color: DS.accent, fontSize: 13),
            )),
          ]),
        ),
      ));
      list.add(const SizedBox(height: 12));
    }

    if (b.status == 'pending_owner_confirmation') {
      list.add(Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [DS.accent.withValues(alpha: 0.12), DS.accent.withValues(alpha: 0.04)]),
            borderRadius: BorderRadius.circular(DS.rMd),
            border: Border.all(color: DS.accent.withValues(alpha: 0.25)),
          ),
          child: Row(children: [
            const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: DS.accent)),
            const SizedBox(width: 12),
            Expanded(child: Text('Your booking has been sent to the shop. Waiting for owner confirmation.', style: TextStyle(fontWeight: FontWeight.w600, color: DS.accent, fontSize: 13, height: 1.4))),
          ]),
        ),
      ));
      list.add(const SizedBox(height: 10));
      if (widget.onCancel != null) {
        list.add(Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Align(alignment: Alignment.centerLeft, child: ActionChipBtn(label: 'Cancel Booking', icon: Icons.cancel_outlined, color: DS.error, onTap: widget.onCancel!)),
        ));
        list.add(const SizedBox(height: 4));
      }
    }

    if (b.status == 'completed' && !b.isPaid && b.remainingAmount > 0) {
      list.addAll(_buildRemainingPayment(context, b));
      list.add(const SizedBox(height: 4));
    }

    if (b.status == 'confirmed') {
      list.add(Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(children: [
          if (!b.reachedShop)
            PButton(text: 'I Reached the Shop', icon: Icons.pin_drop, isGold: true, onPressed: () async {
              final messenger = ScaffoldMessenger.of(context);
              try {
                await svc.markReachedAndNotifyOwner(
                  bookingId: b.id, customerId: b.customerId,
                  ownerId: b.ownerId, customerName: b.customerName,
                  token: b.token, shopName: b.shopName,
                );
                messenger.showSnackBar(const SnackBar(
                  content: Text('Marked as arrived! The owner has been notified.'),
                  behavior: SnackBarBehavior.floating, backgroundColor: DS.success,
                ));
              } catch (e) {
                messenger.showSnackBar(SnackBar(
                  content: Text('Error: $e'), behavior: SnackBarBehavior.floating,
                ));
              }
            }),
          if (!b.reachedShop) const SizedBox(height: 10),
          if (widget.onCancel != null)
            Align(alignment: Alignment.centerLeft, child: ActionChipBtn(label: 'Cancel Booking', icon: Icons.cancel_outlined, color: DS.error, onTap: widget.onCancel!)),
        ]),
      ));
      list.add(const SizedBox(height: 4));
    }

    return list;
  }
}
