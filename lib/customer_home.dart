import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import 'firebase_service.dart';
import 'models.dart';
import 'my_bookings_page.dart';
import 'shop_detail_page.dart';
import 'pages/customer_profile_page.dart';
import 'design_system.dart';
import 'widgets/premium_nav.dart';
import 'widgets/premium_card.dart';
import 'widgets/shimmer.dart';
import 'widgets/section_header.dart';
import 'widgets/search_bar.dart';
import 'widgets/empty_state.dart';
import 'widgets/shop_card.dart';
import 'pages/favourite_shops_page.dart';
import 'login_registration.dart';
import 'package:salon_app/l10n/app_localizations.dart';
import 'utils/maps_utils.dart';

class CustomerHome extends StatefulWidget {
  final AppUser user;
  const CustomerHome({super.key, required this.user});
  @override
  State<CustomerHome> createState() => _CustomerHomePageState();
}

class _CustomerHomePageState extends State<CustomerHome> with TickerProviderStateMixin {
  final svc = FirebaseService();
  int _navIndex = 0;
  final searchCnt = TextEditingController();
  double? _userLat, _userLng;
  bool _nearMeLoading = false;
  String? _selectedCategory;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() { searchCnt.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: IndexedStack(
        index: _navIndex,
        children: [
          _buildHome(),
          MyBookingsPage(user: widget.user),
          _buildAlerts(),
          CustomerProfilePage(user: widget.user),
        ],
      ),
      bottomNavigationBar: AnimUtil.slideUp(
        child: StreamBuilder<List<AppNotification>>(
          stream: svc.watchCustomerNotifications(widget.user.uid),
          builder: (c, snap) {
            final unread = snap.data?.where((n) => !n.read).length ?? 0;
            return PremiumBottomNav(
              currentIndex: _navIndex,
              onTap: (i) => setState(() => _navIndex = i),
              items: [
                const NavItem(icon: Icons.home_outlined, activeIcon: Icons.home_rounded, label: 'Home'),
                const NavItem(icon: Icons.calendar_today_outlined, activeIcon: Icons.calendar_today_rounded, label: 'Bookings'),
                NavItem(icon: Icons.notifications_outlined, activeIcon: Icons.notifications_rounded, label: 'Alerts', badge: unread),
                const NavItem(icon: Icons.person_outline, activeIcon: Icons.person_rounded, label: 'Profile'),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildAlerts() {
    final l = AppLocalizations.of(context)!;
    final isDark = DS.isDark(context);
    return Scaffold(
      body: CustomScrollView(slivers: [
        SliverToBoxAdapter(
          child: Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFF004D40), Color(0xFF00695C), Color(0xFF1A1A2E)], begin: Alignment.topLeft, end: Alignment.bottomRight),
              borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(DS.rXxl), bottomRight: Radius.circular(DS.rXxl)),
              boxShadow: [DS.shadowPrimary],
            ),
            child: SafeArea(bottom: false, child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
              child: Row(children: [
                Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(DS.rMd), border: Border.all(color: Colors.white.withValues(alpha: 0.18))), child: const Icon(Icons.notifications_active, color: DS.accent, size: 22)),
                const SizedBox(width: 14),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(l.notifications, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: -0.4)),
                  const SizedBox(height: 2),
                  Text('Updates about your bookings', style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 13)),
                ])),
              ]),
            )),
          ),
        ),
        SliverFillRemaining(child: StreamBuilder<List<AppNotification>>(
          stream: svc.watchCustomerNotifications(widget.user.uid),
          builder: (c, snap) {
            if (!snap.hasData) return const ShimmerList(itemHeight: 80);
            final notifs = snap.data!;
            if (notifs.isEmpty) return EmptyState(icon: Icons.notifications_outlined, title: l.noNotifications, subtitle: 'You\'ll see alerts about your bookings here.');
            return ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 110),
              itemCount: notifs.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (c, i) {
                final n = notifs[i];
                return AnimUtil.fadeIn(
                  delay: i * 50,
                  child: GlassCard(
                    padding: const EdgeInsets.all(4),
                    tint: n.read ? null : DS.accent,
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      leading: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: (n.read ? (isDark ? DS.darkMuted : DS.muted) : DS.accent).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(DS.rMd),
                        ),
                        child: Icon(Icons.notifications_active_rounded, color: n.read ? (isDark ? DS.darkMuted : DS.muted) : DS.accent, size: 20),
                      ),
                      title: Text(n.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: DS.inkC(context))),
                      subtitle: Padding(padding: const EdgeInsets.only(top: 4), child: Text(n.body, style: TextStyle(fontSize: 13, height: 1.35, color: DS.mutedC(context)))),
                      trailing: n.read ? null : Container(width: 8, height: 8, decoration: BoxDecoration(color: DS.accent, shape: BoxShape.circle, boxShadow: [BoxShadow(color: DS.accent.withValues(alpha: 0.4), blurRadius: 6)])),
                      onTap: () => svc.markNotificationRead(n.id),
                    ),
                  ),
                );
              },
            );
          },
        )),
      ]),
    );
  }

  Widget _buildHome() {
    final l = AppLocalizations.of(context)!;
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 260,
            pinned: false,
            floating: true,
            automaticallyImplyLeading: false,
            backgroundColor: Colors.transparent,
            elevation: 0,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Color(0xFF004D40), Color(0xFF00695C), Color(0xFF1A1A2E)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                  borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(DS.rXxl), bottomRight: Radius.circular(DS.rXxl)),
                  boxShadow: [DS.shadowPrimary],
                ),
                child: SafeArea(
                  bottom: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Row(children: [
                        Expanded(
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text('${l.hello},', style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 14, fontWeight: FontWeight.w500)),
                            const SizedBox(height: 2),
                            Text(widget.user.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w800, letterSpacing: -0.5)),
                          ]),
                        ),
                        GestureDetector(
                          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => FavouriteShopsPage(user: widget.user, userLat: _userLat, userLng: _userLng))),
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(DS.rMd),
                              border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
                            ),
                            child: const Icon(Icons.favorite_border, color: Colors.white, size: 22),
                          ),
                        ),
                        const SizedBox(width: 10),
                        GestureDetector(
                          onTap: () async {
                            await svc.logout();
                            if (!mounted) return;
                            Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const LoginPage()), (_) => false);
                          },
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(DS.rMd),
                              border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
                            ),
                            child: const Icon(Icons.logout, color: Colors.white, size: 22),
                          ),
                        ),
                      ]),
                      const Spacer(),
                      TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0, end: 1),
                        duration: DS.slow,
                        curve: DS.easeOut,
                        builder: (c, v, _) => Opacity(
                          opacity: v,
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            ShaderMask(
                              shaderCallback: (bounds) => const LinearGradient(colors: [Color(0xFFD4AF37), Color(0xFFFFF8E1)]).createShader(bounds),
                              child: const Text("Book Your\nStyle Today", maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 36, fontWeight: FontWeight.w900, color: Colors.white, height: 1.1, letterSpacing: -0.5)),
                            ),
                            const SizedBox(height: 8),
                            Text('Premium salon services at your fingertips', style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 14, fontWeight: FontWeight.w500)),
                          ]),
                        ),
                      ),
                    ]),
                  ),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 110),
              child: AnimUtil.fadeIn(
                delay: 100,
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  AnimatedSearchBar(
                    controller: searchCnt,
                    onChanged: (_) => setState(() {}),
                    onTap: () => _search(searchCnt.text),
                  ),
                  const SizedBox(height: 24),
                  _buildCategories(),
                  const SizedBox(height: 24),
                  _buildNearMeToggle(),
                  const SizedBox(height: 16),
                  _buildNearbyShops(),
                ]),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _search(String q) {
    if (q.trim().isEmpty) return;
    Navigator.push(context, MaterialPageRoute(builder: (_) => _SearchResultsPage(query: q.trim(), user: widget.user, userLat: _userLat, userLng: _userLng)));
  }

  static String _normalize(String s) => s.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');

  static bool _matchesQuery(String serviceName, String query) {
    final normService = _normalize(serviceName);
    final normQuery = _normalize(query);
    if (normQuery.isEmpty) return true;
    if (normService.contains(normQuery)) return true;
    if (normQuery.contains(normService)) return true;
    final queryWords = normQuery.split(RegExp(r'\s+')).where((w) => w.length >= 2).toList();
    if (queryWords.isEmpty) return false;
    return queryWords.any((w) => normService.contains(w));
  }

  Widget _buildCategories() {
    final cats = [
      {'icon': Icons.content_cut_rounded, 'name': 'Hair Cut', 'color': DS.primary},
      {'icon': Icons.face_rounded, 'name': 'Beard', 'color': DS.inkLight},
      {'icon': Icons.spa_outlined, 'name': 'Facial', 'color': DS.accent},
      {'icon': Icons.air_rounded, 'name': 'Hair Spa', 'color': DS.teal},
      {'icon': Icons.star_rounded, 'name': 'Premium', 'color': DS.accent},
    ];
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      SectionHeader(title: 'Categories', subtitle: 'What would you like today?'),
      const SizedBox(height: 16),
      SizedBox(
        height: 100,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: cats.length,
          separatorBuilder: (_, _) => const SizedBox(width: 12),
          itemBuilder: (c, i) {
            final cat = cats[i];
            final isSelected = _selectedCategory == cat['name'];
            return AnimUtil.scaleIn(
              delay: i * 60,
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    if (_selectedCategory == cat['name']) {
                      _selectedCategory = null;
                    } else {
                      _selectedCategory = cat['name'] as String;
                      searchCnt.clear();
                    }
                  });
                },
                child: AnimatedContainer(
                  duration: DS.fast,
                  width: 80,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color: isSelected ? (cat['color'] as Color).withValues(alpha: 0.12) : DS.surfaceC(context),
                    borderRadius: BorderRadius.circular(DS.rXl),
                    border: Border.all(
                      color: isSelected ? (cat['color'] as Color) : DS.borderC(context).withValues(alpha: 0.5),
                      width: isSelected ? 2 : 1,
                    ),
                    boxShadow: DS.isDark(context) ? null : [DS.shadowSm],
                  ),
                  child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Icon(cat['icon'] as IconData, color: isSelected ? (cat['color'] as Color) : (cat['color'] as Color).withValues(alpha: 0.5), size: 26),
                    const SizedBox(height: 6),
                    Text(cat['name'] as String, style: TextStyle(fontSize: 11, fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600, color: isSelected ? (cat['color'] as Color) : DS.inkC(context))),
                  ]),
                ),
              ),
            );
          },
        ),
      ),
    ]);
  }

  Widget _buildNearMeToggle() {
    final hasLocation = _userLat != null;
    return Row(children: [
      Icon(Icons.near_me_rounded, size: 16, color: hasLocation ? DS.primary : DS.mutedC(context)),
      const SizedBox(width: 8),
      Expanded(
        child: Text(
          hasLocation ? 'Showing shops near your location' : 'Find salons near you',
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: hasLocation ? DS.primary : DS.mutedC(context)),
        ),
      ),
      if (_nearMeLoading)
        const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
      else
        GestureDetector(
          onTap: _getCurrentLocation,
          child: AnimatedContainer(
            duration: DS.fast,
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
            decoration: BoxDecoration(
              gradient: hasLocation ? DS.gradientPrimary : null,
              color: hasLocation ? null : DS.surfaceC(context),
              borderRadius: BorderRadius.circular(DS.rXl),
              border: Border.all(color: hasLocation ? Colors.transparent : DS.borderC(context).withValues(alpha: 0.5)),
              boxShadow: hasLocation ? [DS.shadowPrimary] : [],
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.my_location_rounded, size: 16, color: hasLocation ? Colors.white : DS.primary),
              const SizedBox(width: 6),
              Text(hasLocation ? 'Refresh' : 'Near Me', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: hasLocation ? Colors.white : DS.primary)),
            ]),
          ),
        ),
    ]);
  }

  Future<void> _getCurrentLocation() async {
    setState(() => _nearMeLoading = true);
    try {
      final enabled = await Geolocator.isLocationServiceEnabled();
      if (!enabled) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enable location services'), behavior: SnackBarBehavior.floating));
        setState(() => _nearMeLoading = false);
        return;
      }
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Location permission denied'), behavior: SnackBarBehavior.floating));
          setState(() => _nearMeLoading = false);
          return;
        }
      }
      if (permission == LocationPermission.deniedForever) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Location permission permanently denied. Enable in settings.'), behavior: SnackBarBehavior.floating));
        setState(() => _nearMeLoading = false);
        return;
      }
      final pos = await Geolocator.getCurrentPosition(locationSettings: const LocationSettings(accuracy: LocationAccuracy.high));
      setState(() { _userLat = pos.latitude; _userLng = pos.longitude; _nearMeLoading = false; });
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not get location: $e'), behavior: SnackBarBehavior.floating));
      setState(() => _nearMeLoading = false);
    }
  }

  Widget _buildNearbyShops() {
    final l = AppLocalizations.of(context)!;
    final q = searchCnt.text.trim().toLowerCase();
    final nearMe = _userLat != null && _userLng != null;
    return RepaintBoundary(
      child: StreamBuilder<List<String>>(
        stream: svc.watchFavouriteShopIds(widget.user.uid),
        builder: (c, favSnap) {
          final favs = (favSnap.data ?? const <String>[]).toSet();
          return StreamBuilder<List<Shop>>(
            stream: svc.watchShops(),
            builder: (c, snap) {
          if (!snap.hasData) return const ShimmerList(itemHeight: 280);
          var shops = snap.data!.where((s) => s.accessStatus == 'granted').toList();
          if (shops.isEmpty) {
            return EmptyState(icon: Icons.store_outlined, title: l.noSalonsNearby, subtitle: 'Check back later for available salons in your area.');
          }
          if (nearMe) {
            shops = shops.where((s) => s.latitude != 0 || s.longitude != 0).toList();
            shops.sort((a, b) {
              final da = calculateDistance(_userLat!, _userLng!, a.latitude, a.longitude);
              final db = calculateDistance(_userLat!, _userLng!, b.latitude, b.longitude);
              return da.compareTo(db);
            });
          }
          if (q.isNotEmpty) {
            shops = shops.where((s) =>
                s.shopName.toLowerCase().contains(q) ||
                s.location.toLowerCase().contains(q) ||
                s.address.toLowerCase().contains(q) ||
                s.services.any((sv) => _matchesQuery(sv.name, q))).toList();
          }
          if (_selectedCategory != null) {
            shops = shops.where((s) =>
                s.services.any((sv) => _matchesQuery(sv.name, _selectedCategory!))).toList();
          }
          if (shops.isEmpty) {
            final hasFilter = q.isNotEmpty || _selectedCategory != null;
            return EmptyState(
              icon: Icons.search_off_rounded,
              title: 'No Results',
              subtitle: hasFilter
                  ? _selectedCategory != null
                      ? 'No salons offer "$_selectedCategory" service nearby.'
                      : 'No salons match "$q". Try a different search.'
                  : 'No salons with location data. Try without Near Me.',
            );
          }
          final isSearching = q.isNotEmpty || _selectedCategory != null;
          final subtitleText = isSearching
              ? '${shops.length} match${shops.length != 1 ? 'es' : ''}${_selectedCategory != null ? ' for $_selectedCategory' : ''}'
              : '${shops.length} salon${shops.length != 1 ? 's' : ''}${nearMe ? ' · sorted by distance' : ' available'}';
          return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            SectionHeader(title: isSearching ? 'Results' : l.nearbySalons, subtitle: subtitleText),
            const SizedBox(height: 16),
            ...shops.asMap().entries.map((e) {
              final shop = e.value;
              final i = e.key;
              final canBook = shop.isOpen && shop.bookingsAvailable;
              return AnimUtil.fadeIn(
                delay: i * 80,
                child: ShopCard(
                  shop: shop,
                  userLat: _userLat,
                  userLng: _userLng,
                  favouriteShopIds: favs,
                  onToggleFavourite: (id) => _toggleFavourite(id, favs),
                  onTap: canBook
                      ? () => Navigator.push(context, MaterialPageRoute(builder: (_) => ShopDetailPage(shop: shop, user: widget.user, userLat: _userLat, userLng: _userLng)))
                      : () {
                          if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l.notifBookingsUnavailable), behavior: SnackBarBehavior.floating));
                        },
                ),
              );
            }),
          ]);
            },
          );
        },
      ),
    );
  }

  Future<void> _toggleFavourite(String shopId, Set<String> favs) async {
    if (favs.contains(shopId)) {
      await svc.removeFavouriteShop(widget.user.uid, shopId);
    } else {
      await svc.addFavouriteShop(widget.user.uid, shopId);
    }
  }
}

class _SearchResultsPage extends StatefulWidget {
  final String query;
  final AppUser user;
  final double? userLat;
  final double? userLng;
  const _SearchResultsPage({required this.query, required this.user, this.userLat, this.userLng});
  @override
  State<_SearchResultsPage> createState() => _SearchResultsPageState();
}

class _SearchResultsPageState extends State<_SearchResultsPage> {
  final svc = FirebaseService();
  List<Shop>? results;
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _search();
  }

  Future<void> _search() async {
    try {
      final r = await svc.searchShops(widget.query);
      if (mounted) setState(() { results = r; loading = false; });
    } catch (_) {
      if (mounted) setState(() { results = []; loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: FloatingAppBar(title: '${l.search}: "${widget.query}"'),
      body: loading
          ? const Padding(padding: EdgeInsets.all(16), child: ShimmerList(itemHeight: 280))
          : results == null || results!.isEmpty
              ? EmptyState(icon: Icons.search_off_rounded, title: 'No Results', subtitle: 'Try a different search term.')
              : StreamBuilder<List<String>>(
                  stream: svc.watchFavouriteShopIds(widget.user.uid),
                  builder: (c, favSnap) {
                    final favs = (favSnap.data ?? const <String>[]).toSet();
                    return ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: results!.length,
                      itemBuilder: (c, i) => Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: ShopCard(
                          shop: results![i],
                          userLat: widget.userLat,
                          userLng: widget.userLng,
                          favouriteShopIds: favs,
                          onToggleFavourite: (id) => _toggleFavourite(id, favs),
                          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ShopDetailPage(shop: results![i], user: widget.user, userLat: widget.userLat, userLng: widget.userLng))),
                        ),
                      ),
                    );
                  },
                ),
    );
  }

  Future<void> _toggleFavourite(String shopId, Set<String> favs) async {
    if (favs.contains(shopId)) {
      await svc.removeFavouriteShop(widget.user.uid, shopId);
    } else {
      await svc.addFavouriteShop(widget.user.uid, shopId);
    }
  }
}
