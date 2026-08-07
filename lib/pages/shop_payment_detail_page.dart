import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../design_system.dart';
import '../firebase_service.dart';
import '../models.dart';
import '../widgets/dashboard_widgets.dart';
import '../widgets/premium_nav.dart';

class ShopPaymentDetailPage extends StatefulWidget {
  final String ownerId;
  final String shopName;
  final EarningsPeriod initialPeriod;

  const ShopPaymentDetailPage({
    super.key,
    required this.ownerId,
    required this.shopName,
    this.initialPeriod = EarningsPeriod.all,
  });

  @override
  State<ShopPaymentDetailPage> createState() => _ShopPaymentDetailPageState();
}

class _ShopPaymentDetailPageState extends State<ShopPaymentDetailPage> {
  final svc = FirebaseService();
  late EarningsPeriod _period;
  List<Booking>? _bookings;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _period = widget.initialPeriod;
    _load();
  }

  Future<void> _load() async {
    if (mounted) setState(() => _loading = true);
    try {
      final bookings = await svc.getShopPaymentDetails(widget.ownerId, period: _period);
      if (mounted) setState(() { _bookings = bookings; _loading = false; });
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = DS.isDark(context);
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(gradient: isDark ? DS.gradientDarkBg : DS.gradientBg),
        child: SafeArea(
          child: Column(children: [
            FloatingAppBar(
              title: 'Payment Details',
              leading: IconButton(
                icon: Icon(Icons.arrow_back, color: isDark ? DS.darkInk : DS.ink),
                onPressed: () => Navigator.pop(context),
              ),
              titleWidget: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(widget.shopName, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: isDark ? DS.darkInk : DS.ink)),
                Text(_periodLabelDetail(_period), style: TextStyle(fontSize: 12, color: isDark ? DS.darkMuted : DS.muted)),
              ]),
            ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: _load,
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(20),
                  children: [
                    _periodChipsDetail(),
                    const SizedBox(height: 14),
                    if (_loading)
                      const DashboardLoading()
                    else if (_bookings == null || _bookings!.isEmpty)
                      const DashboardEmptyState(message: 'No payments found for this period')
                    else ...[
                      _summaryRow(),
                      const SizedBox(height: 14),
                      Text(
                        '${_bookings!.length} service${_bookings!.length == 1 ? '' : 's'} completed',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: DS.inkC(context)),
                      ),
                      const SizedBox(height: 10),
                      ..._bookings!.map((b) => _paymentCard(b)),
                    ],
                  ],
                ),
              ),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _periodChipsDetail() {
    final isDark = DS.isDark(context);
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(children: [
        for (final p in const [EarningsPeriod.all, EarningsPeriod.day, EarningsPeriod.week, EarningsPeriod.month, EarningsPeriod.year]) ...[
          if (p != EarningsPeriod.all) const SizedBox(width: 6),
          GestureDetector(
            onTap: () {
              if (_period == p) return;
              setState(() => _period = p);
              _load();
            },
            child: AnimatedContainer(
              duration: DS.fast,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              decoration: BoxDecoration(
                color: _period == p ? DS.success : (isDark ? const Color(0xCC16213E) : Colors.white),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: _period == p ? DS.success : (isDark ? const Color(0x4D2A2A4A) : const Color(0x26FFFFFF))),
              ),
              child: Text(_periodLabelDetail(p), style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: _period == p ? Colors.white : (isDark ? DS.darkMuted : DS.muted))),
            ),
          ),
        ],
      ]),
    );
  }

  String _periodLabelDetail(EarningsPeriod p) {
    switch (p) {
      case EarningsPeriod.all:
        return 'All time';
      case EarningsPeriod.day:
        return 'Today';
      case EarningsPeriod.week:
        return 'This Week';
      case EarningsPeriod.month:
        return 'This Month';
      case EarningsPeriod.year:
        return 'This Year';
    }
  }

  Widget _summaryRow() {
    final list = _bookings!;
    final income = list.fold<int>(0, (s, b) => s + b.price);
    final charges = list.fold<int>(0, (s, b) => s + b.bookingPrice);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: DS.gradientGold,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [DS.shadowGold],
      ),
      child: Row(children: [
        Expanded(child: _summaryStat('Services', '${list.length}', Icons.event_available)),
        Container(width: 1, height: 34, color: Colors.white.withValues(alpha: 0.3)),
        const SizedBox(width: 10),
        Expanded(child: _summaryStat('Income', '\u20B9$income', Icons.payments)),
        Container(width: 1, height: 34, color: Colors.white.withValues(alpha: 0.3)),
        const SizedBox(width: 10),
        Expanded(child: _summaryStat('Booking Charges', '\u20B9$charges', Icons.receipt_long)),
      ]),
    );
  }

  Widget _summaryStat(String label, String value, IconData icon) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Icon(icon, size: 13, color: Colors.white.withValues(alpha: 0.85)),
        const SizedBox(width: 4),
        Flexible(child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 10, color: Colors.white.withValues(alpha: 0.8)))),
      ]),
      const SizedBox(height: 4),
      FittedBox(fit: BoxFit.scaleDown, child: Text(value, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: Colors.white))),
    ]);
  }

  Widget _paymentCard(Booking b) {
    final isDark = DS.isDark(context);
    final statusColor = _statusColor(b.status);
    return Container(
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
          Container(
            width: 38, height: 38,
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [DS.primary, DS.primaryLight]),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.content_cut, size: 18, color: Colors.white),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(b.serviceName.isEmpty ? 'Service' : b.serviceName, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: isDark ? DS.darkInk : DS.ink)),
            const SizedBox(height: 2),
            Text('Token #${b.token} · ${b.customerName.isEmpty ? 'Customer' : b.customerName}', maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 12, color: isDark ? DS.darkMuted : DS.muted)),
          ])),
          StatusBadge(label: _statusLabel(b.status), color: statusColor),
        ]),
        const SizedBox(height: 10),
        Row(children: [
          Icon(Icons.calendar_today, size: 12, color: isDark ? DS.darkMuted : DS.muted),
          const SizedBox(width: 4),
          Text(DateFormat('d MMM yyyy').format(b.createdAt), style: TextStyle(fontSize: 12, color: isDark ? DS.darkMuted : DS.muted)),
          const SizedBox(width: 14),
          Icon(Icons.schedule, size: 12, color: isDark ? DS.darkMuted : DS.muted),
          const SizedBox(width: 4),
          Text(DateFormat('h:mm a').format(b.createdAt), style: TextStyle(fontSize: 12, color: isDark ? DS.darkMuted : DS.muted)),
          const Spacer(),
          Text('₹${b.price + b.bookingPrice}', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: DS.success)),
        ]),
        const Divider(height: 18),
        Row(children: [
          _payStat('Service', '\u20B9${b.price}', DS.primary),
          const SizedBox(width: 12),
          _payStat('Booking Charge', '\u20B9${b.bookingPrice}', DS.accent),
        ]),
      ]),
    );
  }

  Widget _payStat(String label, String value, Color color) {
    return Expanded(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w500, color: DS.muted)),
        const SizedBox(height: 2),
        FittedBox(fit: BoxFit.scaleDown, child: Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: color))),
      ]),
    );
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'completed':
        return 'Completed';
      case 'paid':
        return 'Paid';
      case 'confirmed':
        return 'Confirmed';
      default:
        return status.isEmpty ? 'Paid' : status[0].toUpperCase() + status.substring(1);
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'completed':
        return DS.success;
      case 'paid':
        return DS.primary;
      case 'confirmed':
        return DS.accent;
      default:
        return DS.success;
    }
  }
}
