import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../design_system.dart';
import '../widgets/premium_card.dart';
import '../widgets/premium_button.dart';
import '../widgets/premium_nav.dart';
import '../widgets/dashboard_widgets.dart';
import '../firebase_service.dart';
import '../login_registration.dart';
import '../models.dart';
import 'admin_manage_page.dart';
import 'partner_profile_page.dart';
import 'shop_payment_detail_page.dart';

class AdminPage extends StatefulWidget {
  final AppUser user;
  const AdminPage({super.key, required this.user});
  @override
  State<AdminPage> createState() => _AdminPageState();
}

class _AdminPageState extends State<AdminPage> {
  final svc = FirebaseService();
  Map<String, dynamic>? _stats;
  Map<String, dynamic>? _earnings;
  bool _loading = true;
  bool _loadingEarnings = true;
  int _tabIndex = 0;
  EarningsPeriod _earningsPeriod = EarningsPeriod.all;

  @override
  void initState() {
    super.initState();
    _loadStats();
    _loadEarnings();
  }

  Future<void> _loadStats() async {
    try {
      final stats = await svc.getAppStats();
      if (mounted) setState(() { _stats = stats; _loading = false; });
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _loadEarnings() async {
    try {
      final earnings = await svc.getShopEarnings(period: _earningsPeriod);
      if (mounted) setState(() { _earnings = earnings; _loadingEarnings = false; });
    } catch (e) {
      if (mounted) setState(() => _loadingEarnings = false);
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
              titleWidget: Row(children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: DS.gradientGold,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [DS.shadowGold],
                  ),
                  child: const Icon(Icons.verified, size: 18, color: Colors.white),
                ),
                const SizedBox(width: 10),
                Text('Admin Console', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: isDark ? DS.darkInk : DS.ink)),
              ]),
              actions: [
                IconButton(
                  icon: Icon(Icons.logout, color: isDark ? DS.darkMuted : DS.muted),
                  onPressed: _signOut,
                ),
              ],
            ),
            Expanded(
              child: IndexedStack(
                index: _tabIndex,
                children: [
                  _buildOverviewTab(),
                  _buildShopsTab(),
                  _buildPartnersTab(),
                  _buildRequestsTab(),
                  _buildFeedbackTab(),
                ],
              ),
            ),
          ]),
        ),
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(16, 8, 16, 12),
        child: StreamBuilder<List<AccessRequest>>(
          stream: svc.watchAccessRequests(),
          builder: (c, snap) {
            final pending = (snap.data ?? []).where((r) => r.status == 'pending').length;
            return StreamBuilder<List<Map<String, dynamic>>>(
              stream: svc.watchPartnerUnblockRequests(),
              builder: (c2, snap2) {
                final partnerPending = (snap2.data ?? []).where((r) => r['status'] == 'pending').length;
                return StreamBuilder<List<Map<String, dynamic>>>(
                  stream: svc.watchPartnerEditRequests(),
                  builder: (c3, snap3) {
                    final editPending = (snap3.data ?? []).where((r) => r['status'] == 'pending').length;
                    return PremiumBottomNav(
                      currentIndex: _tabIndex,
                      onTap: (i) => setState(() => _tabIndex = i),
                      items: [
                        const NavItem(icon: Icons.grid_view_outlined, activeIcon: Icons.grid_view_rounded, label: 'Overview'),
                        const NavItem(icon: Icons.storefront_outlined, activeIcon: Icons.storefront_rounded, label: 'Shops'),
                        NavItem(icon: Icons.handshake_outlined, activeIcon: Icons.handshake_rounded, label: 'Partners', badge: partnerPending),
                        NavItem(icon: Icons.request_page_outlined, activeIcon: Icons.request_page_rounded, label: 'Requests', badge: pending + editPending),
                        const NavItem(icon: Icons.feedback_outlined, activeIcon: Icons.feedback_rounded, label: 'Feedback'),
                      ],
                    );
                  },
                );
              },
            );
          },
        ),
      ),
    );
  }

  Future<void> _signOut() async {
    final navigator = Navigator.of(context);
    await svc.logout();
    navigator.pushReplacement(MaterialPageRoute(builder: (_) => const LoginPage()));
  }

  Widget _buildOverviewTab() {
    return RefreshIndicator(
      onRefresh: () async {
        setState(() { _loadingEarnings = true; _loading = true; });
        await Future.wait([_loadStats(), _loadEarnings()]);
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24),
        child: StaggeredColumn(children: [
          PremiumHeroCard(
            icon: Icons.verified,
            title: 'Admin Console',
            subtitle: 'App owner access granted',
            gradient: DS.gradientGold,
            stats: _loading || _stats == null
                ? const [HeroStat('Owners', '...'), HeroStat('Shops', '...'), HeroStat('Users', '...')]
                : [
                    HeroStat('Owners', '${_stats!['owners'] ?? 0}', color: Colors.white),
                    HeroStat('Shops', '${_stats!['totalShops'] ?? 0}', color: Colors.white),
                    HeroStat('Users', '${_stats!['totalUsers'] ?? 0}', color: Colors.white),
                  ],
          ),
          GlassCard(
            padding: const EdgeInsets.all(20),
            child: Column(children: [
              InfoTile(icon: Icons.person, label: widget.user.name),
              const SizedBox(height: 10),
              InfoTile(icon: Icons.email, label: widget.user.email),
              const SizedBox(height: 10),
              InfoTile(icon: Icons.build, label: 'App Admin / Owner'),
            ]),
          ),
          _buildStatsGrid(),
          _buildEarningsSection(),
        ]),
      ),
    );
  }

  Widget _buildShopsTab() {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        _buildAllShopsSection(),
      ],
    );
  }

  Widget _buildPartnersTab() {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        _buildManagePartnersSection(),
        const SizedBox(height: 16),
        _buildPartnerUnblockRequestsSection(),
      ],
    );
  }

  Widget _buildRequestsTab() {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        _buildAccessRequestsSection(),
        const SizedBox(height: 16),
        _buildPartnerEditRequestsSection(),
      ],
    );
  }

  Widget _buildFeedbackTab() {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        _buildFeedbackSupportSection(),
      ],
    );
  }

  Widget _buildStatsGrid() {
    return SectionCard(
      icon: Icons.bar_chart,
      title: 'App Statistics',
      accentColor: DS.primary,
      child: _loading
          ? const DashboardLoading()
          : Column(children: [
              Row(children: [
                Expanded(child: ColorStatCard(icon: Icons.store, label: 'Owners', value: _stats?['owners'] ?? 0, color: DS.accent, onTap: () => _showUsersSheet('owner'))),
                const SizedBox(width: 10),
                Expanded(child: ColorStatCard(icon: Icons.people, label: 'Customers', value: _stats?['customers'] ?? 0, color: DS.primary, onTap: () => _showUsersSheet('customer'))),
              ]),
              const SizedBox(height: 10),
              Row(children: [
                Expanded(child: ColorStatCard(icon: Icons.storefront, label: 'Shops', value: _stats?['totalShops'] ?? 0, color: DS.purple, onTap: _showShopsSheet)),
                const SizedBox(width: 10),
                Expanded(child: ColorStatCard(icon: Icons.handshake, label: 'Partners', value: _stats?['partners'] ?? 0, color: DS.success, onTap: () => _showUsersSheet('partner'))),
              ]),
            ]),
    );
  }

  Widget _buildEarningsSection() {
    return SectionCard(
      icon: Icons.account_balance,
      title: 'Earnings & Revenue',
      accentColor: DS.success,
      child: Column(children: [
        _periodChips(),
        const SizedBox(height: 14),
        if (_loadingEarnings)
          const DashboardLoading()
        else ...[
          EarningsHeroBanner(
            totalFees: _earnings?['totalBookingCharges'] ?? 0,
            totalRevenue: _earnings?['totalRevenue'] ?? 0,
            totalBookings: _earnings?['totalBookingsCompleted'] ?? 0,
            feesLabel: 'Booking Fees (Your Profit)',
            revenueLabel: 'Service Payments',
          ),
          const SizedBox(height: 16),
          Text(
            'Per-Shop Breakdown',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: DS.inkC(context)),
          ),
          const SizedBox(height: 12),
          ...(_earnings?['perShop'] as List<ShopEarnings>? ?? []).map((e) => ShopEarningsMiniTile(
            shopName: e.shopName,
            partnerName: e.partnerName,
            partnerCode: e.partnerCode,
            fees: e.totalBookingCharges,
            revenue: e.totalRevenue,
            bookings: e.bookingCount,
            onTap: () => _openShopPayments(e),
          )),
          const SizedBox(height: 16),
          Text(
            'Partner-Code Breakdown',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: DS.inkC(context)),
          ),
          const SizedBox(height: 12),
          ...(_earnings?['perPartner'] as List<PartnerEarnings>? ?? []).map((p) => PartnerEarningsTile(
            partnerName: p.partnerName,
            partnerCode: p.partnerCode,
            fees: p.totalBookingCharges,
            revenue: p.totalRevenue,
            bookings: p.bookingCount,
            shops: p.shopCount,
          )),
        ],
      ]),
    );
  }

  void _openShopPayments(ShopEarnings e) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => ShopPaymentDetailPage(
      ownerId: e.ownerId,
      shopName: e.shopName,
      initialPeriod: _earningsPeriod,
    )));
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
              if (_earningsPeriod == p) return;
              setState(() {
                _earningsPeriod = p;
                _loadingEarnings = true;
              });
              _loadEarnings();
            },
            child: AnimatedContainer(
              duration: DS.fast,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              decoration: BoxDecoration(
                color: _earningsPeriod == p ? DS.success : (isDark ? const Color(0xCC16213E) : Colors.white),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: _earningsPeriod == p ? DS.success : (isDark ? const Color(0x4D2A2A4A) : const Color(0x26FFFFFF))),
              ),
              child: Text(_periodLabel(p), style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: _earningsPeriod == p ? Colors.white : (isDark ? DS.darkMuted : DS.muted))),
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

  Widget _buildAllShopsSection() {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: svc.watchAllShopsWithPartnerInfo(),
      builder: (c, snap) {
        final shops = snap.data ?? [];
        return SectionCard(
          icon: Icons.storefront,
          title: 'All Shops',
          count: shops.length,
          accentColor: const Color(0xFF0D9488),
          child: snap.connectionState == ConnectionState.waiting
              ? const DashboardLoading()
              : shops.isEmpty
                  ? const DashboardEmptyState(message: 'No shops yet')
                  : Column(children: shops.map((data) {
                      final Shop shop = data['shop'];
                      return ShopTile(
                        shopName: shop.shopName,
                        ownerName: shop.ownerName,
                        status: shop.accessStatus,
                        partnerName: data['partnerName'],
                        partnerCode: data['partnerCode'],
                        trailing: _shopStatusActions(shop),
                      );
                    }).toList()),
        );
      },
    );
  }

  Widget _shopStatusActions(Shop shop) {
    final String status = shop.accessStatus;
    if (status == 'blocked') {
      return SizedBox(height: 36, child: PButton(text: 'Unblock', icon: Icons.lock_open, onPressed: () => _setShopStatus(shop, 'granted')));
    }
    if (status == 'pending') {
      return Row(children: [
        Expanded(child: SizedBox(height: 36, child: PButton(text: 'Grant', icon: Icons.check, onPressed: () => _setShopStatus(shop, 'granted')))),
        const SizedBox(width: 8),
        Expanded(child: SizedBox(height: 36, child: PButton(text: 'Block', icon: Icons.block, isOutlined: true, onPressed: () => _setShopStatus(shop, 'blocked')))),
      ]);
    }
    return SizedBox(height: 36, child: PButton(text: 'Block', icon: Icons.block, isOutlined: true, onPressed: () => _setShopStatus(shop, 'blocked')));
  }

  Future<void> _setShopStatus(Shop shop, String status) async {
    final isBlock = status == 'blocked';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: DS.isDark(ctx) ? DS.darkCard : Colors.white,
        title: Text(isBlock ? 'Block ${shop.shopName}?' : 'Unblock ${shop.shopName}?', style: TextStyle(color: DS.inkC(ctx))),
        content: Text(
          isBlock
              ? 'The shop owner will be restricted from managing the shop until you unblock it.'
              : 'The shop owner will regain full access to the shop.',
          style: TextStyle(color: DS.mutedC(ctx)),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(isBlock ? 'Block' : 'Unblock', style: TextStyle(color: isBlock ? DS.error : DS.success)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await svc.updateAccessStatus(shop.ownerId, status);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(isBlock ? '${shop.shopName} blocked' : '${shop.shopName} unblocked'),
          backgroundColor: isBlock ? DS.error : DS.success,
          behavior: SnackBarBehavior.floating,
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Failed: $e'),
          backgroundColor: DS.error,
          behavior: SnackBarBehavior.floating,
        ));
      }
    }
  }

  Widget _buildManagePartnersSection() {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: svc.db.collection('users').where('role', isEqualTo: 'partner').limit(200).snapshots()
          .map((s) => s.docs.map((d) => {'uid': d.id, ...d.data()}).toList()),
      builder: (c, snap) {
        final partners = snap.data ?? [];
        return SectionCard(
          icon: Icons.handshake,
          title: 'Manage Partners',
          count: partners.length,
          accentColor: DS.purple,
          headerAction: GestureDetector(
            onTap: _showAddPartnerDialog,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                gradient: DS.gradientGold,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [DS.shadowGold],
              ),
              child: const Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.add, size: 14, color: Colors.white),
                SizedBox(width: 4),
                Text('Add', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white)),
              ]),
            ),
          ),
          child: snap.connectionState == ConnectionState.waiting
              ? const DashboardLoading()
              : partners.isEmpty
                  ? const DashboardEmptyState(message: 'No partners created yet')
                  : Column(children: partners.map((p) => PartnerTile(
                      name: p['name'] ?? '',
                      email: p['email'] ?? '',
                      mobile: p['mobile'] ?? '',
                      partnerCode: p['partnerCode'] ?? '',
                      status: p['partnerStatus'] ?? 'active',
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => PartnerProfilePage(partnerData: p))),
                      trailing: _partnerStatusActions(p),
                    )).toList()),
        );
      },
    );
  }

  Widget _partnerStatusActions(Map<String, dynamic> partner) {
    final bool isBlocked = (partner['partnerStatus'] ?? 'active') == 'blocked';
    return SizedBox(
      height: 36,
      child: isBlocked
          ? PButton(text: 'Unblock', icon: Icons.lock_open, onPressed: () => _setPartnerStatus(partner, 'active'))
          : PButton(text: 'Block', icon: Icons.block, isOutlined: true, onPressed: () => _setPartnerStatus(partner, 'blocked')),
    );
  }

  Future<void> _setPartnerStatus(Map<String, dynamic> partner, String status) async {
    final String uid = partner['uid'] ?? '';
    final String name = partner['name'] ?? '';
    final bool isBlock = status == 'blocked';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: DS.isDark(ctx) ? DS.darkCard : Colors.white,
        title: Text(isBlock ? 'Block $name?' : 'Unblock $name?', style: TextStyle(color: DS.inkC(ctx))),
        content: Text(
          isBlock
              ? 'The partner will be restricted from their dashboard until you unblock them.'
              : 'The partner will regain full access to their dashboard.',
          style: TextStyle(color: DS.mutedC(ctx)),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(isBlock ? 'Block' : 'Unblock', style: TextStyle(color: isBlock ? DS.error : DS.success)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await svc.updatePartnerStatus(uid, status);
      if (!isBlock) {
        await svc.updatePartnerRequestStatus(uid, 'granted');
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(isBlock ? '$name blocked' : '$name unblocked'),
          backgroundColor: isBlock ? DS.error : DS.success,
          behavior: SnackBarBehavior.floating,
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Failed: $e'),
          backgroundColor: DS.error,
          behavior: SnackBarBehavior.floating,
        ));
      }
    }
  }

  Widget _buildPartnerUnblockRequestsSection() {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: svc.watchPartnerUnblockRequests(),
      builder: (c, snap) {
        final requests = snap.data ?? [];
        final pendingRequests = requests.where((r) => r['status'] == 'pending').toList();
        return SectionCard(
          icon: Icons.lock_open,
          title: 'Partner Unblock Requests',
          count: pendingRequests.length,
          accentColor: const Color(0xFFF97316),
          child: snap.connectionState == ConnectionState.waiting
              ? const DashboardLoading()
              : pendingRequests.isEmpty
                  ? const DashboardEmptyState(message: 'No partner unblock requests')
                  : Column(children: pendingRequests.map((req) => _partnerRequestTile(req)).toList()),
        );
      },
    );
  }

  Widget _partnerRequestTile(Map<String, dynamic> req) {
    final String status = req['status'] ?? 'pending';
    final bool isPending = status == 'pending';
    return AccessRequestTile(
      ownerName: req['partnerName'] ?? '',
      shopName: '',
      mobile: req['mobile'] ?? '',
      status: status == 'granted' ? 'granted' : 'pending',
      note: null,
      trailing: Row(mainAxisSize: MainAxisSize.min, children: [
        const Icon(Icons.vpn_key, size: 12, color: DS.purple),
        const SizedBox(width: 4),
        Text(req['partnerCode'] ?? '', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: DS.purple)),
      ]),
      actionButtons: isPending
          ? SizedBox(
              height: 36,
              child: PButton(
                text: 'Unblock Partner',
                icon: Icons.lock_open,
                onPressed: () => _unblockPartner(req['partnerUid'] ?? ''),
              ),
            )
          : null,
    );
  }

  Widget _buildPartnerEditRequestsSection() {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: svc.watchPartnerEditRequests(),
      builder: (c, snap) {
        final requests = snap.data ?? [];
        final pendingRequests = requests.where((r) => r['status'] == 'pending').toList();
        final isDark = DS.isDark(context);
        return SectionCard(
          icon: Icons.badge_outlined,
          title: 'Partner Change Requests',
          count: pendingRequests.length,
          accentColor: DS.primary,
          child: snap.connectionState == ConnectionState.waiting
              ? const DashboardLoading()
              : requests.isEmpty
                  ? const DashboardEmptyState(message: 'No partner change requests')
                  : Column(children: [
                      if (pendingRequests.isNotEmpty)
                        Text('${pendingRequests.length} pending change request${pendingRequests.length == 1 ? '' : 's'}. Review and apply to update the partner account.',
                            style: TextStyle(fontSize: 12, color: isDark ? DS.darkMuted : DS.muted)),
                      if (pendingRequests.isNotEmpty) const SizedBox(height: 12),
                      ...pendingRequests.map((req) => _partnerEditRequestTile(req)),
                    ]),
        );
      },
    );
  }

  Widget _partnerEditRequestTile(Map<String, dynamic> req) {
    final isDark = DS.isDark(context);
    final field = _editFieldMeta(req['field'] ?? '');
    final status = (req['status'] ?? 'pending').toString();
    final (label, color) = status == 'applied'
        ? ('Applied', DS.success)
        : status == 'rejected'
            ? ('Rejected', DS.error)
            : ('Pending', DS.accent);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xCC16213E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.3)),
        boxShadow: isDark ? null : [DS.shadowSm],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: field.color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10)),
            child: Icon(field.icon, size: 16, color: field.color),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(req['partnerName'] ?? '', maxLines: 1, overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: isDark ? DS.darkInk : DS.ink)),
              Text(field.title, maxLines: 1, overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 12, color: isDark ? DS.darkMuted : DS.muted)),
            ]),
          ),
          const SizedBox(width: 8),
          StatusBadge(label: label, color: color),
        ]),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(color: field.color.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(10)),
          child: Row(children: [
            Expanded(
              child: Text('${req['currentValue'] ?? ''}',
                  maxLines: 1, overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 13, color: isDark ? DS.darkMuted : DS.muted)),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 8),
              child: Icon(Icons.arrow_forward, size: 16, color: DS.primary),
            ),
            Expanded(
              child: Text('${req['appliedValue'] ?? req['requestedValue'] ?? ''}',
                  maxLines: 1, overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: DS.primary)),
            ),
          ]),
        ),
        if ((req['note'] ?? '').toString().isNotEmpty) ...[
          const SizedBox(height: 8),
          Text('Note: ${req['note']}', maxLines: 2, overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 12, color: isDark ? DS.darkMuted : DS.muted)),
        ],
        if (status == 'pending') ...[
          const SizedBox(height: 10),
          SizedBox(
            height: 36,
            child: PButton(
              text: 'Review & Apply',
              icon: Icons.rate_review_outlined,
              isGold: true,
              onPressed: () => _reviewEditRequest(req),
            ),
          ),
        ],
      ]),
    );
  }

  ({String title, IconData icon, Color color}) _editFieldMeta(String field) {
    switch (field) {
      case 'name':
        return (title: 'Name Change', icon: Icons.person_outline, color: DS.primary);
      case 'mobile':
        return (title: 'Mobile Number Change', icon: Icons.phone_outlined, color: DS.success);
      case 'email':
        return (title: 'Email Change', icon: Icons.email_outlined, color: DS.accent);
      case 'password':
        return (title: 'Password Change', icon: Icons.lock_outline, color: DS.purple);
      case 'partnerCode':
        return (title: 'Partner Code Change', icon: Icons.vpn_key, color: const Color(0xFFF97316));
      default:
        return (title: field, icon: Icons.edit_outlined, color: DS.muted);
    }
  }

  Future<void> _reviewEditRequest(Map<String, dynamic> req) async {
    final field = _editFieldMeta(req['field'] ?? '');
    final valueC = TextEditingController(text: (req['requestedValue'] ?? '').toString());
    final requestId = (req['id'] ?? '').toString();
    final partnerUid = (req['partnerUid'] ?? '').toString();
    final fieldName = (req['field'] ?? '').toString();
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(DS.rXxl)),
          backgroundColor: DS.isDark(ctx) ? DS.darkCard : Colors.white,
          title: Text('Review ${field.title}', style: TextStyle(color: DS.inkC(ctx))),
          content: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('${req['partnerName'] ?? ''} (${req['partnerCode'] ?? ''})', style: TextStyle(fontWeight: FontWeight.w700, color: DS.inkC(ctx))),
              const SizedBox(height: 4),
              Text('Current: ${req['currentValue'] ?? ''}', style: TextStyle(fontSize: 13, color: DS.mutedC(ctx))),
              if ((req['note'] ?? '').toString().isNotEmpty) ...[
                const SizedBox(height: 4),
                Text('Note: ${req['note']}', style: TextStyle(fontSize: 13, color: DS.mutedC(ctx))),
              ],
              const SizedBox(height: 14),
              TextField(
                controller: valueC,
                style: TextStyle(color: DS.inkC(ctx)),
                decoration: DS.inputDecoration(ctx).copyWith(
                  labelText: 'New Value',
                  prefixIcon: Icon(field.icon, size: 20),
                ),
              ),
            ]),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, 'reject'),
              child: const Text('Reject', style: TextStyle(color: DS.error)),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, 'cancel'),
              child: Text('Cancel', style: TextStyle(color: DS.isDark(ctx) ? DS.darkMuted : DS.muted)),
            ),
            PButton(
              text: 'Apply',
              icon: Icons.check,
              isGold: true,
              horizontalPadding: 20,
              height: 44,
              expanded: false,
              onPressed: () => Navigator.pop(ctx, valueC.text.trim()),
            ),
          ],
        ),
      ),
    );
    if (result == null || result == 'cancel' || result == 'reject') {
      if (result == 'reject') {
        try {
          await svc.rejectPartnerEditRequest(requestId);
          if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Request rejected'), backgroundColor: DS.error, behavior: SnackBarBehavior.floating));
        } catch (e) {
          if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e'), backgroundColor: DS.error, behavior: SnackBarBehavior.floating));
        }
      }
      return;
    }
    if (result.isEmpty) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('New value cannot be empty'), backgroundColor: DS.error, behavior: SnackBarBehavior.floating));
      return;
    }
    try {
      await svc.applyPartnerEditRequest(requestId: requestId, partnerUid: partnerUid, field: fieldName, newValue: result);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Change applied for ${req['partnerName'] ?? 'partner'}'),
          backgroundColor: DS.success,
          behavior: SnackBarBehavior.floating,
        ));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e'), backgroundColor: DS.error, behavior: SnackBarBehavior.floating));
    }
  }

  Widget _buildAccessRequestsSection() {
    return StreamBuilder<List<AccessRequest>>(
      stream: svc.watchAccessRequests(),      builder: (c, snap) {
        final requests = (snap.data ?? []).where((r) => r.status != 'granted').toList();
        return SectionCard(
          icon: Icons.person_pin,
          title: 'Shop Access Requests',
          count: requests.length,
          accentColor: DS.accent,
          child: snap.connectionState == ConnectionState.waiting
              ? const DashboardLoading()
              : requests.isEmpty
                  ? const DashboardEmptyState(message: 'No requests yet')
                  : Column(children: requests.map((req) => AccessRequestTile(
                      ownerName: req.ownerName,
                      shopName: req.shopName,
                      mobile: req.mobile,
                      status: req.status,
                      note: req.note,
                      actionButtons: _buildRequestActions(req),
                    )).toList()),
        );
      },
    );
  }

  Widget _buildFeedbackSupportSection() {
    return SectionCard(
      icon: Icons.support_agent,
      title: 'Feedback & Support',
      accentColor: DS.accent,
      child: Column(children: [
        Row(children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: svc.db.collection('feedback').limit(200).snapshots(),
              builder: (c, snap) {
                final all = snap.data?.docs ?? [];
                final unreviewed = all.where((d) => d.data()['reviewed'] != true).length;
                return ColorStatCard(
                  icon: Icons.feedback_outlined,
                  label: 'Unreviewed Feedback',
                  value: unreviewed,
                  color: DS.accent,
                  loading: snap.connectionState == ConnectionState.waiting,
                  onTap: _openManagePage,
                );
              },
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: svc.db.collection('support_tickets').where('status', isEqualTo: 'open').limit(200).snapshots(),
              builder: (c, snap) {
                final count = snap.data?.docs.length ?? 0;
                return ColorStatCard(
                  icon: Icons.support_agent,
                  label: 'Open Issues',
                  value: count,
                  color: DS.primary,
                  loading: snap.connectionState == ConnectionState.waiting,
                  onTap: _openManagePage,
                );
              },
            ),
          ),
        ]),
        const SizedBox(height: 12),
        PButton(text: 'Manage Feedback & Issues', icon: Icons.manage_search, isGold: true, onPressed: _openManagePage),
      ]),
    );
  }

  void _openManagePage() {
    Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminManagePage()));
  }

  Widget? _buildRequestActions(AccessRequest req) {
    final isPending = req.status == 'pending';
    final isBlocked = req.status == 'blocked';
    final isGranted = req.status == 'granted';
    if (isPending) {
      return Row(children: [
        Expanded(
          child: SizedBox(height: 36, child: PButton(text: 'Allow', icon: Icons.check, onPressed: () => _updateStatus(req.ownerId, 'granted'))),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: SizedBox(height: 36, child: PButton(text: 'Block', icon: Icons.block, isOutlined: true, onPressed: () => _updateStatus(req.ownerId, 'blocked'))),
        ),
      ]);
    } else if (isBlocked) {
      return SizedBox(height: 36, child: PButton(text: 'Unblock', icon: Icons.lock_open, onPressed: () => _updateStatus(req.ownerId, 'granted')));
    } else if (isGranted) {
      return SizedBox(height: 36, child: PButton(text: 'Block Shop', icon: Icons.block, isOutlined: true, onPressed: () => _updateStatus(req.ownerId, 'blocked')));
    }
    return null;
  }

  void _showAddPartnerDialog() {
    final nameC = TextEditingController();
    final emailC = TextEditingController();
    final mobileC = TextEditingController();
    final passC = TextEditingController();
    final codeC = TextEditingController();
    bool loading = false;
    bool obscure = true;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(DS.rXxl)),
          title: const Text('Add Partner', style: TextStyle(fontWeight: FontWeight.w800)),
          content: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              TextField(controller: nameC, decoration: DS.inputDecoration(ctx).copyWith(labelText: 'Name', hintText: 'Partner name', prefixIcon: const Icon(Icons.person_outline, size: 20))),
              const SizedBox(height: 12),
              TextField(controller: emailC, keyboardType: TextInputType.emailAddress, decoration: DS.inputDecoration(ctx).copyWith(labelText: 'Email', hintText: 'partner@email.com', prefixIcon: const Icon(Icons.email_outlined, size: 20))),
              const SizedBox(height: 12),
              TextField(controller: mobileC, keyboardType: TextInputType.phone, decoration: DS.inputDecoration(ctx).copyWith(labelText: 'Mobile', hintText: '+91 9876543210', prefixIcon: const Icon(Icons.phone_outlined, size: 20))),
              const SizedBox(height: 12),
              TextField(controller: passC, obscureText: obscure, decoration: DS.inputDecoration(ctx).copyWith(labelText: 'Password', hintText: 'Min 8 characters', prefixIcon: const Icon(Icons.lock_outline, size: 20), suffixIcon: IconButton(icon: Icon(obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined, size: 20), onPressed: () => setDialogState(() => obscure = !obscure)))),
              const SizedBox(height: 12),
              TextField(controller: codeC, textCapitalization: TextCapitalization.characters, decoration: DS.inputDecoration(ctx).copyWith(labelText: 'Partner Code', hintText: 'e.g. PARTNER001', prefixIcon: const Icon(Icons.vpn_key, size: 20))),
            ]),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: Text('Cancel', style: TextStyle(color: DS.isDark(ctx) ? DS.darkMuted : DS.muted))),
            PButton(
              text: 'Create',
              icon: Icons.check,
              loading: loading,
              isGold: true,
              onPressed: () async {
                if (nameC.text.trim().isEmpty || emailC.text.trim().isEmpty || mobileC.text.trim().isEmpty || passC.text.trim().length < 8 || codeC.text.trim().isEmpty) {
                  ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: const Text('Fill all fields. Password min 8 chars.'), backgroundColor: DS.error, behavior: SnackBarBehavior.floating));
                  return;
                }
                setDialogState(() => loading = true);
                try {
                  await svc.createPartner(
                    name: nameC.text.trim(), email: emailC.text.trim(), mobile: mobileC.text.trim(),
                    password: passC.text.trim(), partnerCode: codeC.text.trim().toUpperCase(),
                  );
                  if (ctx.mounted) Navigator.pop(ctx);
                  if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: const Text('Partner created successfully'), behavior: SnackBarBehavior.floating));
                } catch (e) {
                  setDialogState(() => loading = false);
                  if (ctx.mounted) ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: DS.error, behavior: SnackBarBehavior.floating));
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _unblockPartner(String partnerUid) async {
    await svc.approvePartnerUnblock(partnerUid);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: const Text('Partner unblocked successfully'),
        behavior: SnackBarBehavior.floating,
      ));
    }
  }

  Future<void> _updateStatus(String ownerId, String status) async {
    await svc.updateAccessStatus(ownerId, status);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Shop ${status}ed successfully'),
        behavior: SnackBarBehavior.floating,
      ));
    }
  }

  void _showUsersSheet(String role) {
    final isDark = DS.isDark(context);
    final titles = {'owner': 'Shop Owners', 'customer': 'Customers', 'partner': 'Partners'};
    final icons = {'owner': Icons.store, 'customer': Icons.people, 'partner': Icons.handshake};
    final colors = {'owner': DS.accent, 'customer': DS.primary, 'partner': DS.success};
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.75,
        minChildSize: 0.4,
        maxChildSize: 0.92,
        builder: (ctx, scrollCtrl) => Container(
          decoration: BoxDecoration(
            color: isDark ? DS.darkBg : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(DS.rXxl)),
          ),
          child: Column(children: [
            Container(
              width: 40, height: 4, margin: const EdgeInsets.only(top: 12),
              decoration: BoxDecoration(color: isDark ? DS.darkBorder : DS.border, borderRadius: BorderRadius.circular(2)),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
              child: Row(children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [colors[role]!, colors[role]!.withValues(alpha: 0.7)]),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icons[role], size: 18, color: Colors.white),
                ),
                const SizedBox(width: 12),
                Expanded(child: Text(titles[role]!, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: isDark ? DS.darkInk : DS.ink))),
                TextButton(onPressed: () => Navigator.pop(ctx), child: Text('Close', style: TextStyle(color: DS.mutedC(ctx)))),
              ]),
            ),
            const Divider(height: 1),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: svc.db.collection('users').where('role', isEqualTo: role).limit(200).snapshots(),
                builder: (c, snap) {
                  if (snap.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator(strokeWidth: 3));
                  }
                  final docs = snap.data?.docs ?? [];
                  if (docs.isEmpty) {
                    return Center(child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Text('No ${titles[role]!.toLowerCase()} found', style: TextStyle(fontSize: 14, color: DS.mutedC(c))),
                    ));
                  }
                  return ListView.builder(
                    controller: scrollCtrl,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    itemCount: docs.length,
                    itemBuilder: (_, i) {
                      final d = docs[i].data() as Map<String, dynamic>;
                      final name = d['name'] ?? '';
                      final email = d['email'] ?? '';
                      final mobile = d['mobile'] ?? '';
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xCC16213E) : Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: isDark ? const Color(0x4D2A2A4A) : const Color(0x26FFFFFF)),
                          boxShadow: isDark ? null : [DS.shadowSm],
                        ),
                        child: Row(children: [
                          Container(
                            width: 40, height: 40,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(colors: [colors[role]!, colors[role]!.withValues(alpha: 0.7)]),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Center(child: Text(name.isNotEmpty ? name[0].toUpperCase() : '?', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Colors.white))),
                          ),
                          const SizedBox(width: 12),
                          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text(name, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: isDark ? DS.darkInk : DS.ink)),
                            const SizedBox(height: 2),
                            Text(email, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 12, color: isDark ? DS.darkMuted : DS.muted)),
                            if (mobile.isNotEmpty) ...[
                              const SizedBox(height: 1),
                              Text(mobile, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 11, color: isDark ? DS.darkMuted : DS.muted)),
                            ],
                          ])),
                        ]),
                      );
                    },
                  );
                },
              ),
            ),
          ]),
        ),
      ),
    );
  }

  void _showShopsSheet() {
    final isDark = DS.isDark(context);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.75,
        minChildSize: 0.4,
        maxChildSize: 0.92,
        builder: (ctx, scrollCtrl) => Container(
          decoration: BoxDecoration(
            color: isDark ? DS.darkBg : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(DS.rXxl)),
          ),
          child: Column(children: [
            Container(
              width: 40, height: 4, margin: const EdgeInsets.only(top: 12),
              decoration: BoxDecoration(color: isDark ? DS.darkBorder : DS.border, borderRadius: BorderRadius.circular(2)),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
              child: Row(children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [DS.purple, DS.purple.withValues(alpha: 0.7)]),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.storefront, size: 18, color: Colors.white),
                ),
                const SizedBox(width: 12),
                const Expanded(child: Text('All Shops', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800))),
                TextButton(onPressed: () => Navigator.pop(ctx), child: Text('Close', style: TextStyle(color: DS.mutedC(ctx)))),
              ]),
            ),
            const Divider(height: 1),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: svc.db.collection('shops').limit(300).snapshots(),
                builder: (c, snap) {
                  if (snap.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator(strokeWidth: 3));
                  }
                  final docs = snap.data?.docs ?? [];
                  if (docs.isEmpty) {
                    return Center(child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Text('No shops found', style: TextStyle(fontSize: 14, color: DS.mutedC(c))),
                    ));
                  }
                  return ListView.builder(
                    controller: scrollCtrl,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    itemCount: docs.length,
                    itemBuilder: (_, i) {
                      final d = docs[i].data() as Map<String, dynamic>;
                      final shopName = d['shopName'] ?? '';
                      final ownerName = d['ownerName'] ?? '';
                      final isOpen = d['isOpen'] == true;
                      final partnerCode = d['partnerCode'] ?? '';
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
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
                              width: 40, height: 40,
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(colors: [DS.purple, Color(0xFF9F67FF)]),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(Icons.storefront, size: 18, color: Colors.white),
                            ),
                            const SizedBox(width: 12),
                            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Text(shopName, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: isDark ? DS.darkInk : DS.ink)),
                              const SizedBox(height: 2),
                              Text(ownerName, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 12, color: isDark ? DS.darkMuted : DS.muted)),
                            ])),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: (isOpen ? DS.success : DS.error).withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(isOpen ? 'Open' : 'Closed', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: isOpen ? DS.success : DS.error)),
                            ),
                          ]),
                          if (partnerCode.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: DS.purple.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(mainAxisSize: MainAxisSize.min, children: [
                                const Icon(Icons.handshake, size: 10, color: DS.purple),
                                const SizedBox(width: 4),
                                Text(partnerCode, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: DS.purple)),
                              ]),
                            ),
                          ],
                        ]),
                      );
                    },
                  );
                },
              ),
            ),
          ]),
        ),
      ),
    );
  }
}
