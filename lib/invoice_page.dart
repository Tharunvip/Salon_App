import 'package:flutter/material.dart';
import 'package:salon_app/design_system.dart';
import 'package:salon_app/widgets/premium_card.dart';
import 'firebase_service.dart';
import 'package:salon_app/l10n/app_localizations.dart';

class InvoicePage extends StatefulWidget {
  final String ownerId;
  final String shopName;
  const InvoicePage({super.key, required this.ownerId, required this.shopName});
  @override
  State<InvoicePage> createState() => _InvoicePageState();
}

class _InvoicePageState extends State<InvoicePage> with SingleTickerProviderStateMixin {
  final svc = FirebaseService();
  late AnimationController _staggerCtrl;
  late Animation<double> _stagger;
  String selectedPeriod = 'today';
  Map<String, int>? revenue;
  bool loading = false;

  @override
  void initState() {
    super.initState();
    _staggerCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 700));
    _stagger = CurvedAnimation(parent: _staggerCtrl, curve: Curves.easeOut);
    _staggerCtrl.forward();
    _load();
  }

  Future<void> _load() async {
    setState(() => loading = true);
    final now = DateTime.now();
    DateTime? from, to;
    switch (selectedPeriod) {
      case 'today':
        from = DateTime(now.year, now.month, now.day);
        to = DateTime(now.year, now.month, now.day, 23, 59, 59);
        break;
      case 'week':
        from = now.subtract(Duration(days: now.weekday - 1));
        from = DateTime(from.year, from.month, from.day);
        to = DateTime(now.year, now.month, now.day, 23, 59, 59);
        break;
      case 'month':
        from = DateTime(now.year, now.month, 1);
        to = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
        break;
      case 'year':
        from = DateTime(now.year, 1, 1);
        to = DateTime(now.year, 12, 31, 23, 59, 59);
        break;
    }
    revenue = await svc.getRevenue(widget.ownerId, from: from, to: to);
    if (mounted) setState(() => loading = false);
  }

  Widget _buildRevStagger(double delay, Widget child) {
    return AnimatedBuilder(
      animation: _staggerCtrl,
      builder: (c, _) {
        final t = ((_stagger.value - delay) / (1 - delay)).clamp(0.0, 1.0);
        return Opacity(
          opacity: t,
          child: Transform.translate(offset: Offset(0, 15 * (1 - Curves.easeOut.transform(t))), child: child),
        );
      },
    );
  }

  @override
  void dispose() { _staggerCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      appBar: AppBar(title: Text('${widget.shopName} - ${l.revenue}', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 20, letterSpacing: -0.3)), centerTitle: false),
      body: Container(
        decoration: BoxDecoration(gradient: isDark ? DS.gradientDarkBg : DS.gradientBg),
        child: ListView(padding: const EdgeInsets.all(16), children: [
          GlassCard(child: Padding(
            padding: const EdgeInsets.all(16),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                _periodChip('Today', 'today'),
                const SizedBox(width: 6),
                _periodChip('Week', 'week'),
                const SizedBox(width: 6),
                _periodChip('Month', 'month'),
                const SizedBox(width: 6),
                _periodChip('Year', 'year'),
              ]),
            ),
          )),
          const SizedBox(height: 16),
          if (loading)
            const Center(child: CircularProgressIndicator())
          else
            GlassCard(child: Column(children: [
              Padding(padding: const EdgeInsets.all(16), child: Text('${l.revenue} ${l.overview}', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: isDark ? DS.darkInk : DS.ink))),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Column(children: [
                  _buildRevStagger(0.0, _revCard(Icons.receipt, l.totalEarnings, '${l.currency}${revenue?['total'] ?? 0}', DS.primary, DS.primaryLight)),
                  const SizedBox(height: 10),
                  _buildRevStagger(0.1, _revCard(Icons.monetization_on, 'Booking Fees', '${l.currency}${revenue?['bookingFees'] ?? 0}', DS.accent, DS.accentLight)),
                  const SizedBox(height: 10),
                  _buildRevStagger(0.2, _revCard(Icons.payment, 'Service Payments', '${l.currency}${revenue?['serviceRevenue'] ?? 0}', DS.success, DS.successLight)),
                  const SizedBox(height: 10),
                  _buildRevStagger(0.3, _revCard(Icons.confirmation_number, l.totalBookings, '${revenue?['count'] ?? 0}', DS.primary, DS.primaryLight)),
                ]),
              ),
            ])),
        ]),
      ),
    );
  }

  Widget _periodChip(String label, String value) {
    final sel = selectedPeriod == value;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ChoiceChip(
      label: Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: sel ? Colors.white : null)),
      selected: sel,
      selectedColor: DS.primary,
      backgroundColor: isDark ? DS.darkSurface : DS.page,
      onSelected: (_) { setState(() => selectedPeriod = value); _load(); },
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    );
  }

  Widget _revCard(IconData icon, String label, String value, Color color, Color bg) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(16)),
      child: Row(children: [
        Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: color.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(12)), child: Icon(icon, color: color, size: 22)),
        const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, overflow: TextOverflow.ellipsis, style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 13)),
          FittedBox(fit: BoxFit.scaleDown, child: Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: color))),
        ])),
      ]),
    );
  }
}
