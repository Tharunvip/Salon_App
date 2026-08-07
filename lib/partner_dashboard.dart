import 'dart:async';
import 'package:flutter/material.dart';
import 'design_system.dart';
import 'widgets/premium_card.dart';
import 'widgets/premium_button.dart';
import 'widgets/premium_nav.dart';
import 'widgets/dashboard_widgets.dart';
import 'firebase_service.dart';
import 'login_registration.dart';
import 'models.dart';
import 'pages/partner_account_page.dart';
import 'pages/shop_payment_detail_page.dart';

class PartnerDashboard extends StatefulWidget {
  final AppUser user;
  const PartnerDashboard({super.key, required this.user});
  @override
  State<PartnerDashboard> createState() => _PartnerDashboardState();
}

class _PartnerDashboardState extends State<PartnerDashboard> {
  final svc = FirebaseService();
  String _partnerCode = '';
  bool _loading = true;
  bool _isBlocked = false;
  Map<String, dynamic>? _stats;
  Map<String, dynamic>? _earnings;
  List<Shop> _linkedShops = [];
  List<AccessRequest> _accessRequests = [];
  Timer? _refreshTimer;
  int _tabIndex = 0;
  EarningsPeriod _earningsPeriod = EarningsPeriod.all;

  @override
  void initState() {
    super.initState();
    _loadAllData();
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadAllData() async {
    try {
      final userData = await svc.db.collection('users').doc(widget.user.uid).get();
      final pCode = (userData.data()?['partnerCode'] as String?) ?? '';
      final blocked = (userData.data()?['partnerStatus'] as String?) == 'blocked';
      if (pCode.isEmpty) {
        if (mounted) setState(() { _partnerCode = ''; _loading = false; _isBlocked = blocked; });
        return;
      }
      _partnerCode = pCode;
      _isBlocked = blocked;
      await Future.wait([
        _loadPartnerShops(pCode),
        _loadStats(pCode),
        _loadEarnings(pCode),
        _loadAccessRequests(pCode),
      ]);
      _refreshTimer?.cancel();
      _refreshTimer = Timer.periodic(const Duration(seconds: 10), (_) async {
        final snap = await svc.db.collection('users').doc(widget.user.uid).get();
        final nowBlocked = (snap.data()?['partnerStatus'] as String?) == 'blocked';
        if (mounted && nowBlocked != _isBlocked) setState(() => _isBlocked = nowBlocked);
        _loadPartnerShops(pCode);
        _loadStats(pCode);
        _loadEarnings(pCode);
        _loadAccessRequests(pCode);
      });
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _loadPartnerShops(String partnerCode) async {
    try {
      final shops = await svc.db.collection('shops').where('partnerCode', isEqualTo: partnerCode).get();
      final list = shops.docs.map((d) => Shop.fromMap(d.id, d.data())).toList();
      if (mounted) setState(() { _linkedShops = list; });
    } catch (e) {
      debugPrint('[Partner] loadShops error: $e');
    }
  }

  Future<void> _loadStats(String partnerCode) async {
    try {
      final stats = await svc.getPartnerStats(partnerCode);
      if (mounted) setState(() { _stats = stats; _loading = false; });
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _loadEarnings(String partnerCode) async {
    try {
      final earnings = await svc.getPartnerShopEarnings(partnerCode, period: _earningsPeriod);
      if (mounted) setState(() { _earnings = earnings; });
    } catch (e) {
      debugPrint('[Partner] loadEarnings error: $e');
    }
  }

  Future<void> _loadAccessRequests(String partnerCode) async {
    try {
      final shopDocs = await svc.db.collection('shops').where('partnerCode', isEqualTo: partnerCode).get();
      final ownerIds = shopDocs.docs.map((d) => d.id).toSet();
      final reqSnap = await svc.db.collection('admin_requests').orderBy('createdAt', descending: true).get();
      final requests = reqSnap.docs
          .where((d) => ownerIds.contains(d.data()['ownerId']))
          .map((d) => AccessRequest.fromMap(d.id, d.data()))
          .toList();
      if (mounted) setState(() => _accessRequests = requests);
    } catch (e) {
      debugPrint('[Partner] loadAccessRequests error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = DS.isDark(context);
    if (_isBlocked) return _buildBlockedView(isDark);
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(gradient: isDark ? DS.gradientDarkBg : DS.gradientBg),
        child: SafeArea(
          child: Column(children: [
            FloatingAppBar(
              title: 'Partner Dashboard',
              actions: [
                IconButton(
                  icon: Icon(Icons.logout, color: isDark ? DS.darkMuted : DS.muted),
                  onPressed: _openApp,
                ),
              ],
            ),
            Expanded(
              child: IndexedStack(
                index: _tabIndex,
                children: [
                  _buildDashboardTab(),
                  _buildShopsTab(),
                  _buildRequestsTab(),
                  _buildProfileTab(),
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
            final ownerIds = _linkedShops.map((s) => s.ownerId).toSet();
            final pending = (snap.data ?? [])
                .where((r) => r.status == 'pending' && ownerIds.contains(r.ownerId))
                .length;
            return StreamBuilder<List<Map<String, dynamic>>>(
              stream: svc.watchMyPartnerEditRequests(widget.user.uid),
              builder: (c2, snap2) {
                final myPending = (snap2.data ?? []).where((r) => r['status'] == 'pending').length;
                return PremiumBottomNav(
                  currentIndex: _tabIndex,
                  onTap: (i) => setState(() => _tabIndex = i),
                  items: [
                    const NavItem(icon: Icons.grid_view_outlined, activeIcon: Icons.grid_view_rounded, label: 'Dashboard'),
                    const NavItem(icon: Icons.storefront_outlined, activeIcon: Icons.storefront_rounded, label: 'Shops'),
                    NavItem(icon: Icons.request_page_outlined, activeIcon: Icons.request_page_rounded, label: 'Requests', badge: pending),
                    NavItem(icon: Icons.person_outline, activeIcon: Icons.person_rounded, label: 'Profile', badge: myPending),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }

  void _openApp() {
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginPage()));
  }

  Widget _buildDashboardTab() {
    return RefreshIndicator(
      onRefresh: _refreshAll,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24),
        child: StaggeredColumn(children: [
          PremiumHeroCard(
            icon: Icons.handshake,
            title: widget.user.name.isEmpty ? 'Partner' : widget.user.name,
            subtitle: _isBlocked ? 'Access blocked by admin' : 'Partner access granted',
            gradient: _isBlocked
                ? const LinearGradient(colors: [Color(0xFFEF4444), Color(0xFFB91C1C)], begin: Alignment.topLeft, end: Alignment.bottomRight)
                : DS.gradientGold,
            trailing: _partnerCode.isEmpty
                ? null
                : Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(20)),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      const Icon(Icons.vpn_key, size: 12, color: Colors.white),
                      const SizedBox(width: 4),
                      Text(_partnerCode, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: 0.5)),
                    ]),
                  ),
            stats: _loading || _stats == null
                ? const [HeroStat('Shops', '...'), HeroStat('Bookings', '...')]
                : [
                    HeroStat('Linked Shops', '${_stats!['totalShops'] ?? 0}', color: Colors.white),
                    HeroStat('Bookings', '${_stats!['totalBookings'] ?? 0}', color: Colors.white),
                  ],
          ),
          _buildInfoCard(),
          _buildStatsSection(),
          _buildEarningsSection(),
          const SizedBox(height: 20),
        ]),
      ),
    );
  }

  Widget _buildShopsTab() {
    return RefreshIndicator(
      onRefresh: _refreshAll,
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          _buildLinkedShopsSection(),
        ],
      ),
    );
  }

  Widget _buildRequestsTab() {
    return RefreshIndicator(
      onRefresh: _refreshAll,
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          _buildAccessRequestsSection(),
        ],
      ),
    );
  }

  Widget _buildProfileTab() {
    return PartnerAccountPage(user: widget.user, partnerCode: _partnerCode);
  }

  Future<void> _refreshAll() async {
    setState(() => _loading = true);
    final pCode = _partnerCode;
    if (pCode.isNotEmpty) {
      await Future.wait([
        _loadPartnerShops(pCode),
        _loadStats(pCode),
        _loadEarnings(pCode),
        _loadAccessRequests(pCode),
      ]);
    }
    if (mounted) setState(() => _loading = false);
  }

  Widget _buildInfoCard() {
    return GlassCard(
      padding: const EdgeInsets.all(24),
      child: Column(children: [
        InfoTile(icon: Icons.person, label: widget.user.name),
        const SizedBox(height: 16),
        InfoTile(icon: Icons.email, label: widget.user.email),
        const SizedBox(height: 16),
        InfoTile(icon: Icons.phone, label: widget.user.mobile),
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
              _partnerCode.isEmpty ? 'Loading...' : _partnerCode,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: DS.purple),
            ),
          ),
        ),
      ]),
    );
  }

  Widget _buildStatsSection() {
    return SectionCard(
      icon: Icons.bar_chart,
      title: 'Partner Statistics',
      accentColor: DS.primary,
      child: _loading
          ? const DashboardLoading()
          : _stats != null
              ? Row(children: [
                  Expanded(child: ColorStatCard(icon: Icons.store, label: 'Linked Shops', value: _stats!['totalShops'] ?? 0, color: DS.primary)),
                  const SizedBox(width: 10),
                  Expanded(child: ColorStatCard(icon: Icons.receipt_long, label: 'Total Bookings', value: _stats!['totalBookings'] ?? 0, color: DS.accent)),
                ])
              : const DashboardEmptyState(message: 'No data available'),
    );
  }

  Widget _buildEarningsSection() {
    return SectionCard(
      icon: Icons.account_balance,
      title: 'Earnings & Revenue',
      accentColor: DS.success,
      child: _earnings != null && (_earnings!['perShop'] as List).isNotEmpty
          ? Column(children: [
              _earningsPeriodChips(),
              const SizedBox(height: 14),
              EarningsHeroBanner(
                totalFees: _earnings!['totalBookingCharges'] ?? 0,
                totalRevenue: _earnings!['totalRevenue'] ?? 0,
                totalBookings: _earnings!['totalBookingsCompleted'] ?? 0,
              ),
              const SizedBox(height: 16),
              Text('Per-Shop Breakdown', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: DS.inkC(context))),
              const SizedBox(height: 12),
              ...(_earnings!['perShop'] as List<ShopEarnings>).map((e) => ShopEarningsMiniTile(
                shopName: e.shopName, fees: e.totalBookingCharges, revenue: e.totalRevenue, bookings: e.bookingCount,
                onTap: () => _openShopPayments(e),
              )),
            ])
          : _loading
              ? const DashboardLoading()
              : const DashboardEmptyState(message: 'No earnings data yet'),
    );
  }

  Widget _earningsPeriodChips() {
    final isDark = DS.isDark(context);
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(children: [
        for (final p in const [EarningsPeriod.all, EarningsPeriod.day, EarningsPeriod.week, EarningsPeriod.month, EarningsPeriod.year]) ...[
          if (p != EarningsPeriod.all) const SizedBox(width: 6),
          GestureDetector(
            onTap: () {
              if (_earningsPeriod == p) return;
              setState(() => _earningsPeriod = p);
              if (_partnerCode.isNotEmpty) _loadEarnings(_partnerCode);
            },
            child: AnimatedContainer(
              duration: DS.fast,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              decoration: BoxDecoration(
                color: _earningsPeriod == p ? DS.success : (isDark ? const Color(0xCC16213E) : Colors.white),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: _earningsPeriod == p ? DS.success : (isDark ? const Color(0x4D2A2A4A) : const Color(0x26FFFFFF))),
              ),
              child: Text(_earningsPeriodLabel(p), style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: _earningsPeriod == p ? Colors.white : (isDark ? DS.darkMuted : DS.muted))),
            ),
          ),
        ],
      ]),
    );
  }

  String _earningsPeriodLabel(EarningsPeriod p) {
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

  void _openShopPayments(ShopEarnings e) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => ShopPaymentDetailPage(
      ownerId: e.ownerId,
      shopName: e.shopName,
      initialPeriod: _earningsPeriod,
    )));
  }

  Widget _buildLinkedShopsSection() {
    return SectionCard(
      icon: Icons.store,
      title: 'Linked Shops',
      count: _linkedShops.length,
      accentColor: DS.purple,
      child: _linkedShops.isEmpty
          ? const DashboardEmptyState(message: 'No shops linked with your partner code yet')
          : Column(children: _linkedShops.map((shop) => ShopTile(
              shopName: shop.shopName,
              ownerName: '${shop.ownerName} \u2022 ${shop.mobile}',
              status: shop.accessStatus,
              trailing: _shopStatusActions(shop),
            )).toList()),
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
    await _handleAccessStatus(shop.ownerId, status);
  }

  Widget _buildAccessRequestsSection() {
    return SectionCard(
      icon: Icons.person_pin,
      title: 'Shop Access Requests',
      count: _accessRequests.length,
      accentColor: DS.accent,
      child: _accessRequests.isEmpty
          ? const DashboardEmptyState(message: 'No requests yet')
          : Column(children: _accessRequests.map((req) => AccessRequestTile(
              ownerName: req.ownerName,
              shopName: req.shopName,
              mobile: req.mobile,
              status: req.status,
              note: req.note,
              actionButtons: _buildRequestActions(req),
            )).toList()),
    );
  }

  Widget? _buildRequestActions(AccessRequest req) {
    final isPending = req.status == 'pending';
    final isBlocked = req.status == 'blocked';
    final isGranted = req.status == 'granted';
    if (isPending) {
      return Row(children: [
        Expanded(child: SizedBox(height: 36, child: PButton(text: 'Allow', icon: Icons.check, onPressed: () => _handleAccessStatus(req.ownerId, 'granted')))),
        const SizedBox(width: 10),
        Expanded(child: SizedBox(height: 36, child: PButton(text: 'Block', icon: Icons.block, isOutlined: true, onPressed: () => _handleAccessStatus(req.ownerId, 'blocked')))),
      ]);
    } else if (isBlocked) {
      return SizedBox(height: 36, child: PButton(text: 'Unblock', icon: Icons.lock_open, onPressed: () => _handleAccessStatus(req.ownerId, 'granted')));
    } else if (isGranted) {
      return SizedBox(height: 36, child: PButton(text: 'Block Shop', icon: Icons.block, isOutlined: true, onPressed: () => _handleAccessStatus(req.ownerId, 'blocked')));
    }
    return null;
  }

  Future<void> _handleAccessStatus(String ownerId, String status) async {
    await svc.updateAccessStatus(ownerId, status);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Shop ${status}ed successfully'),
        behavior: SnackBarBehavior.floating,
      ));
      if (_partnerCode.isNotEmpty) {
        await Future.wait([_loadAccessRequests(_partnerCode), _loadPartnerShops(_partnerCode)]);
      }
    }
  }

  Widget _buildBlockedView(bool isDark) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(gradient: isDark ? DS.gradientDarkBg : DS.gradientBg),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(32),
              child: StaggeredColumn(children: [
                AnimUtil.scaleIn(
                  delay: 0,
                  child: Container(
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [const Color(0xFFEF4444), const Color(0xFFEF4444).withValues(alpha: 0.7)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [BoxShadow(color: const Color(0xFFEF4444).withValues(alpha: 0.4), blurRadius: 40, offset: const Offset(0, 10))],
                    ),
                    child: const Icon(Icons.block, size: 64, color: Colors.white),
                  ),
                ),
                const SizedBox(height: 32),
                Text('Access Blocked', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: isDark ? DS.darkInk : DS.ink, letterSpacing: -0.5)),
                const SizedBox(height: 12),
                Text('Your partner dashboard has been blocked by the admin.', textAlign: TextAlign.center, style: TextStyle(fontSize: 15, color: isDark ? DS.darkMuted : DS.muted)),
                const SizedBox(height: 8),
                Text('You can send an unblock request to the admin.', textAlign: TextAlign.center, style: TextStyle(fontSize: 14, color: isDark ? DS.darkMuted : DS.muted)),
                const SizedBox(height: 36),
                PButton(text: 'Request Unblock', icon: Icons.lock_open, onPressed: _requestUnblock, isGold: true),
                const SizedBox(height: 16),
                PButton(text: 'Sign Out', icon: Icons.logout, isOutlined: true, onPressed: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginPage()))),
              ]),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _requestUnblock() async {
    try {
      final userData = await svc.db.collection('users').doc(widget.user.uid).get();
      final code = (userData.data()?['partnerCode'] as String?) ?? '';
      await svc.createPartnerUnblockRequest(partnerUid: widget.user.uid, partnerName: widget.user.name, partnerCode: code, mobile: widget.user.mobile);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: const Text('Unblock request sent to admin'), behavior: SnackBarBehavior.floating));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: DS.error, behavior: SnackBarBehavior.floating));
    }
  }
}
