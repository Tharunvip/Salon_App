import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../design_system.dart';
import '../widgets/premium_card.dart';
import '../widgets/premium_button.dart';
import '../widgets/premium_nav.dart';
import '../widgets/dashboard_widgets.dart';
import '../firebase_service.dart';
import '../models.dart';
import 'shop_payment_detail_page.dart';

class PartnerProfilePage extends StatefulWidget {
  final Map<String, dynamic> partnerData;
  const PartnerProfilePage({super.key, required this.partnerData});
  @override
  State<PartnerProfilePage> createState() => _PartnerProfilePageState();
}

class _PartnerProfilePageState extends State<PartnerProfilePage> {
  final svc = FirebaseService();
  Map<String, dynamic>? _shopData;
  bool _loading = true;
  EarningsPeriod _period = EarningsPeriod.all;

  String get _partnerUid => widget.partnerData['uid'] ?? '';
  String get _partnerName => widget.partnerData['name'] ?? '';
  String get _partnerEmail => widget.partnerData['email'] ?? '';
  String get _partnerMobile => widget.partnerData['mobile'] ?? '';
  String get _partnerCode => widget.partnerData['partnerCode'] ?? '';

  @override
  void initState() {
    super.initState();
    _loadShopData();
  }

  Future<void> _loadShopData() async {
    try {
      final data = await svc.getPartnerShopsWithEarnings(_partnerCode, period: _period);
      if (mounted) setState(() { _shopData = data; _loading = false; });
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = DS.isDark(context);
    return StreamBuilder<DocumentSnapshot>(
      stream: svc.db.collection('users').doc(_partnerUid).snapshots(),
      builder: (context, snap) {
        final data = snap.data?.data() as Map<String, dynamic>?;
        final partnerStatus = (data?['partnerStatus'] as String?) ?? 'active';
        final isBlocked = partnerStatus == 'blocked';
        return Scaffold(
          body: Container(
            decoration: BoxDecoration(gradient: isDark ? DS.gradientDarkBg : DS.gradientBg),
            child: SafeArea(
              child: Column(children: [
                FloatingAppBar(
                  title: _partnerName,
                  leading: IconButton(
                    icon: Icon(Icons.arrow_back, color: DS.inkC(context)),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: () async {
                      setState(() => _loading = true);
                      await _loadShopData();
                    },
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(24),
                      child: StaggeredColumn(children: [
                        _buildPartnerHeader(isBlocked),
                        _buildInfoCard(),
                        _buildPartnerCodeChip(),
                        _buildShopsRevenueSection(),
                        const SizedBox(height: 8),
                        _buildActionButtons(isBlocked),
                        const SizedBox(height: 20),
                      ]),
                    ),
                  ),
                ),
              ]),
            ),
          ),
        );
      },
    );
  }

  Widget _buildPartnerHeader(bool isBlocked) {
    return PremiumHeroCard(
      icon: isBlocked ? Icons.block : Icons.handshake,
      title: _partnerName,
      subtitle: isBlocked ? 'Access blocked by admin' : 'Partner access granted',
      gradient: isBlocked
          ? const LinearGradient(colors: [Color(0xFFEF4444), Color(0xFFB91C1C)], begin: Alignment.topLeft, end: Alignment.bottomRight)
          : DS.gradientGold,
      avatar: Container(
        height: 54, width: 54,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            colors: isBlocked ? [const Color(0xFFEF4444), const Color(0xFFEF4444).withValues(alpha: 0.7)] : const [DS.accent, Color(0xFFB8962E)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          border: Border.all(color: Colors.white.withValues(alpha: 0.5), width: 2.5),
        ),
        child: Icon(isBlocked ? Icons.block : Icons.handshake, color: Colors.white, size: 26),
      ),
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: (isBlocked ? const Color(0xFFEF4444) : DS.success).withValues(alpha: 0.22),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: (isBlocked ? const Color(0xFFEF4444) : DS.success).withValues(alpha: 0.45)),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(isBlocked ? Icons.block : Icons.check_circle, size: 12, color: isBlocked ? const Color(0xFFEF4444) : DS.success),
          const SizedBox(width: 4),
          Text(isBlocked ? 'BLOCKED' : 'ACTIVE', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: isBlocked ? const Color(0xFFEF4444) : DS.success)),
        ]),
      ),
    );
  }

  Widget _buildInfoCard() {
    return GlassCard(
      padding: const EdgeInsets.all(24),
      child: Column(children: [
        InfoTile(icon: Icons.person, label: _partnerName),
        const SizedBox(height: 16),
        InfoTile(icon: Icons.email, label: _partnerEmail),
        const SizedBox(height: 16),
        InfoTile(icon: Icons.phone, label: _partnerMobile),
        const SizedBox(height: 16),
        InfoTile(
          icon: Icons.vpn_key,
          label: 'Partner Code',
          trailing: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: DS.purple.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              _partnerCode,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: DS.purple),
            ),
          ),
        ),
      ]),
    );
  }

  Widget _buildPartnerCodeChip() {
    return GlassCard(
      padding: const EdgeInsets.all(20),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [DS.purple, DS.purple.withValues(alpha: 0.7)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: DS.purple.withValues(alpha: 0.3), blurRadius: 16, offset: const Offset(0, 6))],
        ),
        child: Row(children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.vpn_key, size: 24, color: Colors.white),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Partner Code', style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.8))),
              const SizedBox(height: 4),
              Text(
                _partnerCode,
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 1),
              ),
            ]),
          ),
        ]),
      ),
    );
  }

  Widget _buildShopsRevenueSection() {
    return SectionCard(
      icon: Icons.storefront,
      title: 'Linked Shops & Revenue',
      accentColor: DS.success,
      child: _loading
          ? const DashboardLoading()
          : (_shopData != null && (_shopData!['shops'] as List).isNotEmpty)
              ? Column(children: [
                  _periodChips(),
                  const SizedBox(height: 14),
                  EarningsHeroBanner(
                    totalFees: 0,
                    totalRevenue: _shopData!['totalRevenue'] ?? 0,
                    totalBookings: _shopData!['totalBookings'] ?? 0,
                    feesLabel: 'Total Fees',
                    revenueLabel: 'Total Revenue',
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '${_shopData!['totalShops']} Shop${(_shopData!['totalShops'] as int) == 1 ? '' : 's'}',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: DS.inkC(context)),
                  ),
                  const SizedBox(height: 12),
                  ...(_shopData!['shops'] as List<Map<String, dynamic>>).map((data) => _shopRevenueTile(data)),
                ])
              : const DashboardEmptyState(message: 'No shops linked with this partner code'),
    );
  }

  Widget _periodChips() {
    final isDark = DS.isDark(context);
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(children: [
        for (final p in const [EarningsPeriod.all, EarningsPeriod.day, EarningsPeriod.week, EarningsPeriod.month, EarningsPeriod.year]) ...[
          if (p != EarningsPeriod.all) const SizedBox(width: 6),
          GestureDetector(
            onTap: () {
              if (_period == p) return;
              setState(() {
                _period = p;
                _loading = true;
              });
              _loadShopData();
            },
            child: AnimatedContainer(
              duration: DS.fast,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              decoration: BoxDecoration(
                color: _period == p ? DS.success : (isDark ? const Color(0xCC16213E) : Colors.white),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: _period == p ? DS.success : (isDark ? const Color(0x4D2A2A4A) : const Color(0x26FFFFFF))),
              ),
              child: Text(_periodLabel(p), style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: _period == p ? Colors.white : (isDark ? DS.darkMuted : DS.muted))),
            ),
          ),
        ],
      ]),
    );
  }

  String _periodLabel(EarningsPeriod p) {
    switch (p) {
      case EarningsPeriod.all:
        return 'All';
      case EarningsPeriod.day:
        return 'Day';
      case EarningsPeriod.week:
        return 'Week';
      case EarningsPeriod.month:
        return 'Month';
      case EarningsPeriod.year:
        return 'Year';
    }
  }

  Widget _shopRevenueTile(Map<String, dynamic> data) {
    final Shop shop = data['shop'];
    final int revenue = data['revenue'] ?? 0;
    final int charges = data['bookingCharges'] ?? 0;
    final int count = data['bookingCount'] ?? 0;
    final Color statusColor = shop.accessStatus == 'granted'
        ? DS.success
        : shop.accessStatus == 'blocked'
            ? const Color(0xFFEF4444)
            : DS.accent;
    final String statusLabel = shop.accessStatus == 'granted' ? 'Active' : shop.accessStatus == 'blocked' ? 'Blocked' : 'Pending';
    final isDark = DS.isDark(context);
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ShopPaymentDetailPage(
        ownerId: shop.ownerId,
        shopName: shop.shopName,
        initialPeriod: _period,
      ))),
      child: Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xCC16213E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? const Color(0x4D2A2A4A) : const Color(0x26FFFFFF)),
        boxShadow: isDark ? null : [DS.shadowSm],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(
            child: Text(
              shop.shopName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: isDark ? DS.darkInk : DS.ink),
            ),
          ),
          const SizedBox(width: 8),
          StatusBadge(label: statusLabel, color: statusColor),
        ]),
        const SizedBox(height: 10),
        Row(children: [
          _miniStat('Revenue', '\u20B9$revenue', DS.success),
          const SizedBox(width: 12),
          _miniStat('Fees', '\u20B9$charges', DS.primary),
          const SizedBox(width: 12),
          _miniStat('Bookings', '$count', DS.accent),
        ]),
      ]),
      ),
    );
  }

  Widget _miniStat(String label, String value, Color color) {
    return Expanded(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w500, color: DS.muted)),
        const SizedBox(height: 2),
        FittedBox(fit: BoxFit.scaleDown, child: Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: color))),
      ]),
    );
  }

  Widget _buildActionButtons(bool isBlocked) {
    return Column(children: [
      if (isBlocked)
        PButton(
          text: 'Unblock Partner',
          icon: Icons.lock_open,
          onPressed: _unblockPartner,
          isGold: true,
        )
      else
        PButton(
          text: 'Block Partner',
          icon: Icons.block,
          isOutlined: true,
          onPressed: _blockPartner,
        ),
      const SizedBox(height: 12),
      PButton(
        text: 'Remove Partner',
        icon: Icons.delete_forever,
        isOutlined: true,
        onPressed: _confirmDelete,
      ),
    ]);
  }

  Future<void> _blockPartner() async {
    await svc.updatePartnerStatus(_partnerUid, 'blocked');
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: const Text('Partner blocked successfully'),
        behavior: SnackBarBehavior.floating,
      ));
    }
  }

  Future<void> _unblockPartner() async {
    await svc.updatePartnerStatus(_partnerUid, 'active');
    await svc.updatePartnerRequestStatus(_partnerUid, 'granted');
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: const Text('Partner unblocked successfully'),
        behavior: SnackBarBehavior.floating,
      ));
    }
  }

  void _confirmDelete() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(DS.rXxl)),
        title: const Text('Remove Partner', style: TextStyle(fontWeight: FontWeight.w800)),
        content: Text('Are you sure you want to remove $_partnerName? This will delete their account permanently.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text('Cancel', style: TextStyle(color: DS.isDark(ctx) ? DS.darkMuted : DS.muted))),
          PButton(
            text: 'Remove',
            icon: Icons.delete_forever,
            isOutlined: true,
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await svc.deletePartner(_partnerUid);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: const Text('Partner removed successfully'),
                    behavior: SnackBarBehavior.floating,
                  ));
                  Navigator.pop(context);
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text('Error: $e'),
                    backgroundColor: DS.error,
                    behavior: SnackBarBehavior.floating,
                  ));
                }
              }
            },
          ),
        ],
      ),
    );
  }
}
